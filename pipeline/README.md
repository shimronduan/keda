# GitHub Actions Deployment Pipeline

This pipeline provisions Azure infrastructure, builds and pushes the BlobWorker Docker image to ACR, and deploys to AKS with KEDA auto-scaling.

## Prerequisites

### 1. Create tfstate container

Run the setup script to create the Terraform state container:

```bash
az login
./pipeline/setup-tfstate.sh
```

### 2. Configure Azure OIDC Federation for GitHub Actions

This allows GitHub Actions to authenticate to Azure without storing secrets.

#### Create an App Registration

```bash
# Set variables
GITHUB_ORG="your-github-username"  # or organization name
GITHUB_REPO="keda"
APP_NAME="github-actions-keda"

# Create App Registration
az ad app create --display-name "$APP_NAME"

# Get the App ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get the Object ID of the Service Principal
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)
```

#### Add Federated Credential

```bash
# Create federated credential for main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create federated credential for workflow_dispatch (manual runs)
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-workflow-dispatch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:dev",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

#### Grant Azure Permissions

```bash
SUBSCRIPTION_ID="60296e74-7b11-471e-9baf-c9c450c2417b"

# Grant Contributor role (for creating resources)
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Grant User Access Administrator (for creating role assignments)
az role assignment create \
  --assignee $APP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### 3. Add GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | App Registration Application (client) ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `60296e74-7b11-471e-9baf-c9c450c2417b` |

To get these values:

```bash
# Get Client ID
az ad app list --display-name "github-actions-keda" --query "[0].appId" -o tsv

# Get Tenant ID
az account show --query "tenantId" -o tsv
```

## Running the Pipeline

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy KEDA BlobWorker** workflow
4. Click **Run workflow**
5. Select environment (dev/prod)
6. Click **Run workflow**

## Pipeline Jobs

| Job | Description |
|-----|-------------|
| **terraform** | Provisions Azure resources (Resource Group, Storage, Service Bus, Event Grid, AKS, ACR, KEDA) |
| **build-and-push** | Builds Docker image and pushes to ACR with git SHA tag |
| **deploy-to-aks** | Applies K8s manifests to AKS cluster |

## Verification

After the pipeline completes:

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-event-driven-demo --name aks-event-demo

# Check pods (should be 0 initially - KEDA scale-to-zero)
kubectl get pods -l app=blob-worker

# Check KEDA scaler
kubectl get scaledobject azure-servicebus-queue-scaler

# Upload a blob to trigger scaling
az storage blob upload \
  --account-name stblobeventdemo123 \
  --container-name uploads \
  --file test.txt \
  --name test.txt

# Watch pods scale up
kubectl get pods -l app=blob-worker -w
```
