#!/usr/bin/env bash
set -euo pipefail  # Fail fast: -e exit on error, -u undefined var error, -o pipefail propagates pipeline failures

# generate-env.sh - Minimal workshop env generator
# Requires Azure CLI login & access to the target resource group.

SCRIPT_NAME=$(basename "$0")
OUTPUT_FILE=".env"  # Fixed for workshop
RESOURCE_GROUP=""

usage() {
  cat <<EOF
${SCRIPT_NAME} - Generate workshop .env

Usage: ${SCRIPT_NAME}

Options:
  -h, --help     Show this help

Behavior:
  * Autodetect RG: env var -> single Cognitive Services RG -> <rg>-project ML workspace heuristic.
  * Prompt only if multiple Cognitive Services accounts.
  * Write .env used by notebooks.

Environment variables written:
  AZURE_RESOURCE_GROUP_NAME
  AZURE_PROJECT_NAME
  AZURE_OPENAI_DEPLOYMENT_NAME (fixed: gpt-4o-mini)
  AZURE_OPENAI_API_VERSION (fixed: 2024-12-01-preview)
  AZURE_SUBSCRIPTION_ID
  AZURE_OPENAI_ENDPOINT
  AZURE_OPENAI_API_KEY

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 1 ;;
  esac
done

# If env var set, honor it first
if [[ -n "${AZURE_RESOURCE_GROUP_NAME:-}" ]]; then
  RESOURCE_GROUP="$AZURE_RESOURCE_GROUP_NAME"
  echo "[INFO] Using resource group from AZURE_RESOURCE_GROUP_NAME: $RESOURCE_GROUP" >&2
fi

# Pre-flight Azure CLI check happens before further autodetection needing subscription

# Pre-flight checks
if ! command -v az >/dev/null 2>&1; then
  echo "[ERROR] Azure CLI (az) not found in PATH" >&2
  exit 4
fi

# Check login. If missing, automatically run device code login so user gets code.
if ! SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null); then
  echo "[INFO] No active Azure CLI session. Running 'az login --use-device-code'..." >&2
  if az login --use-device-code; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  else
    echo "[ERROR] az login failed or was cancelled." >&2
    exit 4
  fi
fi

# Subscription acquired (silent)

# Autodetect resource group if still empty: find RGs that have AIServices/OpenAI accounts
if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "[INFO] Attempting resource group autodetection..." >&2
  # List cognitive services accounts (name + resourceGroup)
  mapfile -t CS_LINES < <(az resource list --resource-type Microsoft.CognitiveServices/accounts --query "[?kind=='AIServices'||kind=='OpenAI'].[name,resourceGroup]" -o tsv 2>/dev/null || true)
  if [[ ${#CS_LINES[@]} -eq 0 ]]; then
  echo "[ERROR] No Cognitive Services accounts found in subscription; cannot determine resource group." >&2
    exit 1
  fi
  # Extract unique RG names
  declare -A RG_SET
  for line in "${CS_LINES[@]}"; do
    rg_name="${line##*$'\t'}" # last field
    RG_SET["$rg_name"]=1
  done
  RG_CANDIDATES=("${!RG_SET[@]}")
  if [[ ${#RG_CANDIDATES[@]} -eq 1 ]]; then
    RESOURCE_GROUP="${RG_CANDIDATES[0]}"
    echo "[INFO] Autodetected resource group: $RESOURCE_GROUP" >&2
  else
    echo "[INFO] Multiple candidate resource groups detected: ${RG_CANDIDATES[*]}" >&2
    echo "[INFO] Applying ML workspace heuristic (<rg>-project) to refine..." >&2
    workspace_filtered=()
    for rg in "${RG_CANDIDATES[@]}"; do
      if az resource show -g "$rg" -n "${rg}-project" --resource-type Microsoft.MachineLearningServices/workspaces >/dev/null 2>&1; then
        workspace_filtered+=("$rg")
      fi
    done
    if [[ ${#workspace_filtered[@]} -eq 1 ]]; then
      RESOURCE_GROUP="${workspace_filtered[0]}"
      echo "[INFO] Autodetected resource group via ML workspace heuristic: $RESOURCE_GROUP" >&2
    else
      if [[ ${#workspace_filtered[@]} -eq 0 ]]; then
  echo "[ERROR] Ambiguous: none of the candidate RGs has a <rg>-project ML workspace. Set AZURE_RESOURCE_GROUP_NAME." >&2
      else
  echo "[ERROR] Still ambiguous after heuristic (${workspace_filtered[*]}). Set AZURE_RESOURCE_GROUP_NAME." >&2
      fi
      exit 1
    fi
  fi
fi

if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "[ERROR] Unable to determine resource group. Set AZURE_RESOURCE_GROUP_NAME and re-run." >&2
  exit 1
fi

# Validate RG exists
if ! az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "[ERROR] Resource group '$RESOURCE_GROUP' not found" >&2
  exit 2
fi

PROJECT_NAME="${RESOURCE_GROUP}-project"  # Retained for notebooks referencing project naming convention

# Find Cognitive Services account(s) (no jq dependency)
ACCOUNT_NAMES=($(az resource list -g "$RESOURCE_GROUP" --resource-type Microsoft.CognitiveServices/accounts --query "[?kind=='AIServices'||kind=='OpenAI'].name" -o tsv))

if [[ ${#ACCOUNT_NAMES[@]} -eq 0 ]]; then
  echo "[ERROR] No Cognitive Services (AIServices/OpenAI) accounts found in RG" >&2
  exit 3
fi

if [[ ${#ACCOUNT_NAMES[@]} -eq 1 ]]; then
  SELECTED_ACCOUNT="${ACCOUNT_NAMES[0]}"
  echo "[INFO] Using Cognitive Services account: ${SELECTED_ACCOUNT}" >&2
else
  echo "Multiple Cognitive Services accounts found:" >&2
  i=1
  for acct in "${ACCOUNT_NAMES[@]}"; do
    echo "  $i) $acct" >&2
    i=$((i+1))
  done
  while true; do
    read -rp "Select account [1-${#ACCOUNT_NAMES[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#ACCOUNT_NAMES[@]} )); then
      SELECTED_ACCOUNT="${ACCOUNT_NAMES[$((choice-1))]}"
      break
    else
      echo "Invalid selection." >&2
    fi
  done
fi

ENDPOINT="https://${SELECTED_ACCOUNT}.openai.azure.com/"

# Retrieve key (key1)
# If retrieval fails, we keep empty string.
OPENAI_KEY=""
if ! OPENAI_KEY=$(az cognitiveservices account keys list -n "$SELECTED_ACCOUNT" -g "$RESOURCE_GROUP" --query key1 -o tsv 2>/dev/null); then
  echo "[WARN] Unable to retrieve API key (insufficient role?). Leaving empty." >&2
fi

# Prepare env content
ENV_CONTENT=$(cat <<EOF
# Generated by ${SCRIPT_NAME} on $(date -u +%Y-%m-%dT%H:%M:%SZ)
AZURE_RESOURCE_GROUP_NAME="${RESOURCE_GROUP}"
AZURE_PROJECT_NAME="${PROJECT_NAME}"
AZURE_OPENAI_DEPLOYMENT_NAME="gpt-4o-mini"
AZURE_OPENAI_API_VERSION="2024-12-01-preview"
AZURE_SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
AZURE_OPENAI_ENDPOINT="${ENDPOINT}"
AZURE_OPENAI_API_KEY="${OPENAI_KEY}"
EOF
)

# Write file (prompt if exists)
if [[ -f "$OUTPUT_FILE" ]]; then
  read -rp "File '$OUTPUT_FILE' exists. Overwrite? [y/N]: " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "[INFO] Aborted overwrite." >&2
    echo "----- .env content (not written) -----" >&2
    echo "$ENV_CONTENT"
    exit 0
  fi
fi

echo "$ENV_CONTENT" > "$OUTPUT_FILE"

# Mask key for summary
MASKED_KEY="${OPENAI_KEY:0:4}****${OPENAI_KEY: -4}"
[[ -z "$OPENAI_KEY" ]] && MASKED_KEY="(empty)"

echo "[INFO] .env written (rg=${RESOURCE_GROUP} project=${PROJECT_NAME} acct=${SELECTED_ACCOUNT} sub=${SUBSCRIPTION_ID} endpoint=${ENDPOINT} key=${MASKED_KEY})" >&2

exit 0
