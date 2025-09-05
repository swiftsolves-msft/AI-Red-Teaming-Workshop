# Run AI red team evaluations agent

> **Avg execution time (section): ~15 min**

These instructions cover running the remaining `AIRT.ipynb` cells where the AI Red Teaming Agent conducts basic, intermediate, advanced, and custom prompt attacks against the target model in your Azure AI project.

## Prerequisites

1. Azure AI project deployed (hub + project) with system‑assigned managed identity.
2. Default blob storage connection (workspaceblobstore) set to **Microsoft Entra ID-based** (see Module 1 if you need to toggle it). No SAS or account keys required.
3. OpenAI deployment (e.g., `gpt-4o-mini`) accessible with your identity (Cognitive Services OpenAI User role).
4. Python environment with `azure-ai-evaluation[redteam]` installed (done in earlier notebook cells).
5. Region supported for AI Red Teaming Agent (preview) – confirm your project region is in the current preview list.

## Key Microsoft Documentation

- AI Red Teaming Agent overview (preview): <https://learn.microsoft.com/azure/ai-foundry/concepts/ai-red-teaming-agent>
- Run scans with the AI Red Teaming Agent: <https://learn.microsoft.com/azure/ai-foundry/how-to/develop/run-scans-ai-red-teaming-agent>
- View AI Red Teaming results: <https://learn.microsoft.com/azure/ai-foundry/how-to/view-ai-red-teaming-results>
- Observability & evaluation stages: <https://learn.microsoft.com/azure/ai-foundry/concepts/observability#the-three-stages-of-genaiops-evaluation>
- Risk & safety evaluators: <https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-evaluators/risk-safety-evaluators>

## Workflow summary

1. Generate / specify attack objectives (risk categories, counts).
2. Launch AI Red Teaming Agent scan (PyRIT-powered) from the notebook.
3. Monitor scan progress (optional logging output).
4. Retrieve evaluation metrics (attack success rate, per-category breakdown).
5. Inspect conversation-level artifacts for successful vs. failed attacks.
6. Iterate with additional categories / custom prompts.

### Basic attack

Focus on default risk categories (violence, sexual, hate & unfairness, self-harm) with a low prompt count to validate the pipeline end-to-end.

### Intermediate attack

Increase the objectives count and optionally introduce additional attack strategies (e.g., obfuscation, role-play) to probe guardrails more thoroughly.

### Advanced and custom attack

Add bespoke high-risk or application-specific prompt objectives and enable more complex PyRIT transformation strategies. Correlate successful attacks with mitigations (system messages, content filters) before progressing to production.

## Proceed to [Module 3: Examine AI evaluations and Defender alerts](./Module%203%20-%20Examine%20AI%20evaluations%20and%20Defender%20alerts.md)
