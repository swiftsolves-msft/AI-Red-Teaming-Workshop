# Manual Setup Lab Instructions

> **Avg deployment time: 28 min**

The following instructions are for a manual deployment of the Azure resources needed for AI red team evaluations.

## Deploy Azure AI Foundry

Azure AI Foundry is a prerequisite for AI red team evaluations; it provides the evaluation capabilities to test large language models when selecting a GenAI application, piloting a GenAI application, and also when a GenAI application is in production and operating.

> **Avg deploy time: 5 min**

1. Deploy an Azure AI Foundry resource with a project; be sure to use a unique name. ![Create Azure AI Foundry](../images/aifoundcreate1.png)
2. On Network, deploy with access for all networks. ![Deploy Azure AI Foundry](../images/aifoundcreate2.png)
3. On Identity, enable a system-assigned managed identity. ![Deploy Azure AI Foundry](../images/aifoundcreate3.png)
4. Click Review + Create and finish deployment. ![Create Azure AI Foundry](../images/aifoundcreate4.png)

## Deploy + Connect Azure Storage

An Azure Storage account is connected to Azure AI Foundry to host the evaluation reports produced after scans run. The AI red team evaluations features read the raw reports in storage and present them in the Azure AI Foundry evaluations portal.

> **Avg config time: 5 min**

1. After the Azure AI Foundry hub and project are deployed, navigate to the hub resource and launch Azure AI Studio. ![Azure AI Studio](../images/aistorage1.png)
2. In the hub, open the Connected resources blade. ![Connected resources blade](../images/aistorage2.png)
3. Create a new storage connection. ![Create storage connection](../images/aistorage3.png)
4. Finish the connection to the storage account (create one if needed) and ensure it uses the hub's managed identity. ![Finish connection](../images/aistorage4.png)

## Assign Blob Contributor permissions (AI Foundry)

This allows the Azure AI Foundry resource to connect to storage and read the uploaded AI red teaming evaluation reports.

> **Avg config time: 3 min**

1. In the storage account resource, open Access Control (IAM) and add a role assignment. ![Access Control (IAM)](../images/storagerbac.png)
2. Choose the role 'Storage Blob Data Contributor'. ![Choose role](../images/storagerbac2.png)
3. On Members, switch to Managed identity, select the Azure AI Foundry hub identity, add, and save. ![Assign managed identity](../images/storagerbac3.png)

## Deploy Azure Machine Learning workspace

(Optional) The AI red teaming exercises are conducted in a Jupyter Python notebook. You can run locally or in another compute layer; however, Azure ML workspaces provide an easy-to-deploy environment with a managed kernel and dependencies.

> **Avg deploy time: 5 min**

1. Deploy a Machine Learning workspace (search for "Machine Learning" and create). ![Create ML workspace](../images/mlworkspace.png)
2. Complete the wizard; a storage account is created with the workspace. ![Workspace storage](../images/mlworkspace2.png)
3. Ensure the workspace uses a system-assigned managed identity so it can access the storage account. ![Workspace managed identity](../images/mlworkspace3.png)

## Assign Blob Contributor permissions (ML workspace)

This allows the ML workspace managed identity to access the storage account and read/upload the Python notebook files.

> **Avg config time: 2 min**

⚠️ Assign the Machine Learning workspace managed identity the 'Storage Blob Data Contributor' role on its storage account.

## Assign Blob Contributor permissions (User)

Apply the RBAC role to the user at the resource group scope. This lets the signed-in user access both storage accounts and upload notebook files for the AI red teaming evaluations.

> **Avg config time: 2 min**

⚠️ Assign the user the 'Storage Blob Data Contributor' role at the resource group scope containing the storage accounts.

## Upload files to notebook

Download the Python notebook and supporting files so you can execute the AI red teaming exercises in the ML workspace.

> **Avg config time: 3 min**

1. Download the [files folder](https://github.com/swiftsolves-msft/AI-Red-team-evaluations-workshop/blob/main/workshop/files) locally (used later in the ML workspace). ![Files to download](../images/filestodownload.png)
2. Open the Machine Learning workspace resource and launch Studio. ![Launch Studio](../images/mlworkportal.png)
3. In Studio, open the Notebooks blade and click Upload folder. ![Upload folder](../images/mlnotebook.png)
4. Upload the `data` folder (with `prompts.json`) and the `AIRT.ipynb` notebook. ![Upload notebook](../images/mlnotebook2.png)
5. Confirm the root directory now contains `AIRT.ipynb` and a `data/` folder with `prompts.json`. ![Notebook directory](../images/mlnotebook3.png)

## Deploy compute

Deploy compute so the Python notebooks can run in a managed environment without impacting your local setup—ideal for a workshop or lab.

> **Avg deploy time: 5 min**

1. In the Compute blade, create a new compute instance. ![Create compute](../images/mlcompute.png)
2. Ensure the region has quota (e.g., Standard E4ds_v4). Idle shutdown will trigger automatically. Click Review + Create (provisioning may take 5+ minutes). ![Compute provisioning](../images/mlcompute2.png)

## Conclusion

You have completed setting up the Azure resources for the AI red teaming workshop and assigned the necessary permissions for evaluations to upload properly. Next, run the workshop exercises in `AIRT.ipynb` within the Machine Learning workspace you prepared earlier.
