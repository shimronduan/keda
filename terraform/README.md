# KEDA Event-Driven Terraform Configuration

A comprehensive Terraform configuration for deploying an event-driven architecture on Azure using KEDA (Kubernetes Event Driven Autoscaling).

## Architecture Overview

This configuration sets up:

- **Azure Storage Account**: Event source for blob creation events
- **Azure Service Bus**: Message queue for processing events
- **Azure Kubernetes Service (AKS)**: Container orchestration with Workload Identity
- **Azure Event Grid**: Routes blob creation events to Service Bus
- **Workload Identity**: Enables AKS pods to authenticate to Azure services without storing credentials

## File Structure

```
terraform/
├── settings.tf                  # Terraform provider configuration
├── variables.tf                 # Input variables for all resources
├── locals.tf                    # Local computed values
├── main.tf                      # Resource definitions
├── outputs.tf                   # Output values for downstream use
├── terraform.tfvars.example     # Example variable values
└── README.md                    # This file
```

## Getting Started

### Prerequisites

- Terraform >= 1.0
- Azure CLI installed and authenticated
- Appropriate Azure subscription permissions

### Setup

1. **Clone or copy the Terraform files** to your workspace

2. **Create a terraform.tfvars file** from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Customize the variables** in `terraform.tfvars` for your environment:
   - Update storage account name (must be globally unique)
   - Change cluster name if needed
   - Adjust node count/VM size for your workload
   - Modify resource names and location as needed

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the plan**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Variables

All configuration is managed through `variables.tf`. Key variable groups:

- **Environment & Location**: `environment`, `location`, `resource_group_name`
- **Storage**: `storage_account_name`, `storage_account_tier`, `storage_container_name`
- **Service Bus**: `servicebus_namespace_name`, `servicebus_sku`, `servicebus_queue_name`
- **AKS**: `aks_cluster_name`, `aks_node_count`, `aks_vm_size`
- **Event Grid**: `eventgrid_system_topic_name`, `eventgrid_subscription_name`
- **Workload Identity**: `managed_identity_name`, `kubernetes_service_account`, `kubernetes_namespace`

### Customization

Edit `terraform.tfvars` to override default values:

```hcl
# Example: Production setup
environment           = "prod"
location              = "West US 2"
aks_node_count        = 3
aks_vm_size           = "Standard_D4s_v3"
```

## Workload Identity Configuration

The configuration sets up Workload Identity, which allows AKS pods to authenticate to Azure services without storing secrets.

### Required Kubernetes Setup

On your AKS cluster, create the service account that matches your `kubernetes_service_account` variable:

```bash
kubectl create serviceaccount keda-worker-sa
```

The federated identity credential automatically links this service account to the managed identity.

## Security Considerations

- **Storage Access**: Limited to blob reading via RBAC role assignment
- **Service Bus Access**: Limited to queue message receiving
- **Workload Identity**: Uses federated credentials instead of managed keys
- **Network**: Consider adding network policies and private endpoints for production

## Outputs

After applying, useful outputs include:

- `aks_cluster_name`: Name of your AKS cluster
- `aks_oidc_issuer_url`: OIDC issuer for Workload Identity
- `managed_identity_client_id`: Client ID for pod authentication
- `kubernetes_service_account_oidc`: Full OIDC identifier for the service account

Retrieve outputs:
```bash
terraform output managed_identity_client_id
terraform output aks_oidc_issuer_url
```

## Maintenance

### Updating Configuration

1. Modify variables in `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to update resources

### Destroying Resources

```bash
terraform destroy
```

## Refactoring Details

This configuration has been refactored for maintainability:

✅ **Extracted Variables**: All hardcoded values moved to `variables.tf` with descriptions and defaults
✅ **Computed Locals**: Common values in `locals.tf` for DRY principle
✅ **Clear Organization**: Resources grouped by section with banner comments
✅ **Tagged Resources**: All resources tagged with common tags for cost tracking
✅ **Outputs**: Comprehensive outputs for integration with other tools
✅ **Documentation**: Detailed comments explaining workload identity setup

## Troubleshooting

### Storage account name conflicts
Storage account names must be globally unique. If you get a naming error, change the value in `terraform.tfvars`.

### AKS deployment timeout
Verify your Azure subscription has sufficient quota for the VM size and region.

### Workload Identity not working
Ensure:
1. The service account exists in the correct namespace
2. The OIDC issuer URL is accessible from your cluster
3. The managed identity has appropriate RBAC role assignments

## Next Steps

1. Deploy KEDA operator to your AKS cluster
2. Create KEDA Scalers that reference the Service Bus queue
3. Deploy your workload with the configured service account
4. Monitor events flowing from Storage → Event Grid → Service Bus

## Support

For issues with Terraform, see: https://www.terraform.io/docs
For Azure provider documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
For KEDA documentation: https://keda.sh/docs/


I'll explain what I found in the terraform folder and teach AKS + Azure identity (Entra) in very simple, child-friendly terms — then show exact steps to run this config.

## Quick progress update
I read the Terraform files: settings.tf, variables.tf, locals.tf, main.tf, outputs.tf, and README.md. Now I'll explain them simply and show how the pieces fit and how to deploy.

## What each file does (as simply as possible)
- settings.tf — tells Terraform "use the Azure provider" (like telling a toy which brand of blocks to use).
- variables.tf — lists knobs you can change (names, sizes, counts). Think of it as the recipe that says "how many cookies" and "what flavor."
- locals.tf — small helpers and shortcuts (like writing down a short nickname to reuse).
- main.tf — the big build sheet: it creates the Resource Group, Storage Account, Service Bus, Event Grid, AKS cluster, a User-Assigned Managed Identity, a Federated Identity Credential, and RBAC role assignments.
- outputs.tf — tells Terraform which useful IDs/values to print after creation (like giving you the keys to doors you just built).
- README.md — explains the architecture and basic usage.

## Architecture in one sentence
Files set up: a storage for blobs → Event Grid sends "blob created" events → Service Bus queue holds messages → AKS runs workers (KEDA) to process messages; AKS pods use Workload Identity (Entra-managed) to access Storage and Service Bus without credentials.

## Very-simple analogies (5-year-old style)
- Azure = big toy city with many buildings (services).  
- Terraform = magic blueprint paper that tells the city which buildings to build and how.  
- AKS (Kubernetes) = a LEGO table where lots of little robots (containers/pods) live and work.  
- Node pool = the group of LEGO boards (VMs) where robots stand.  
- KEDA = a magic alarm that makes more robots appear when the queue gets busy, and disappear when it's quiet.  
- Storage Blob = a toy chest where you put files (blobs).  
- Event Grid = a mail system that notices when a new toy is put in the chest and sends a letter.  
- Service Bus queue = the mail bag that workers take from to know what to do.  
- Entra ID (Azure AD) = the city passport office — it says who is allowed to enter or use things.  
- Managed Identity = a special passport given to a robot so it can use things without carrying a password.  
- Federated Identity Credential = a handshake between the robot’s name on the LEGO table and the passport office so the passport office trusts the robot.

## AKS / Kubernetes basics (simple)
- Cluster = collection of machines that run containers.
- Pod = the smallest unit — one or more containers that run together.
- Service Account = a Kubernetes identity (a name) you give to pods so they can be recognized.
- Workload Identity (AKS + Entra) = instead of giving pods static secrets, we let Entra trust the pod's service account (via the cluster's OIDC), so the pod can receive tokens to call Azure services.

## Identity pieces in this repo (what Terraform creates and why)
- `azurerm_kubernetes_cluster.aks`:
  - Creates AKS with `oidc_issuer_enabled = true` and `workload_identity_enabled = true`. This allows Kubernetes service accounts to get tokens that Entra will accept.
  - Also gives the cluster a SystemAssigned identity (Azure gives the cluster itself a built-in identity).
- `azurerm_user_assigned_identity.worker_identity`:
  - A user-assigned managed identity (like a special passport you can hand to pods).
- `azurerm_federated_identity_credential.federated`:
  - Wires the Kubernetes service account ("system:serviceaccount:<namespace>:<serviceaccount>") to the user-assigned identity using the AKS OIDC issuer. This is the handshake so Entra trusts that pods with that service account can act as that managed identity.
- Role assignments (`azurerm_role_assignment`):
  - Grant the user-assigned managed identity permissions:
    - `Storage Blob Data Reader` on the storage account
    - `Azure Service Bus Data Receiver` on the service bus namespace
  - That means any pod that uses the managed identity can read blobs and receive messages.
- Event Grid subscription:
  - Routes blob-created events from the storage account into the Service Bus queue.

## How the pieces work together (step-by-step)
1. Someone uploads a blob to the Storage Account.
2. Event Grid detects "BlobCreated" and forwards an event to the Service Bus queue.
3. KEDA detects messages in the Service Bus queue and scales the worker pods in AKS.
4. Worker pod uses its Kubernetes service account. Because of the federated credential, Entra issues tokens so the pod acts as the user-assigned managed identity.
5. With that identity, pod can read the blob and receive from Service Bus (no secret files needed).

## Exact, minimal commands to run this (safe, step-by-step)
1. Initialize and plan
   - terraform init
   - terraform plan
2. Apply (creates Azure resources)
   - terraform apply
   - (or `terraform apply -auto-approve` if you're confident)
3. After apply, get outputs you will need:
   - terraform output managed_identity_client_id
   - terraform output aks_oidc_issuer_url
   - terraform output aks_cluster_name
4. Connect to AKS
   - az aks get-credentials --name <aks_cluster_name> --resource-group <resource_group_name>
5. Create the Kubernetes service account that matches `var.kubernetes_service_account`:
   - kubectl create serviceaccount keda-worker-sa --namespace default
6. Install KEDA (example using Helm)
   - helm repo add keda https://keda.sh/helm-charts
   - helm repo update
   - helm install keda keda/keda --namespace keda --create-namespace
7. Deploy your worker workload (pod/deployment) that uses the service account `keda-worker-sa` and sets the environment variable AZURE_CLIENT_ID to the `managed_identity_client_id` output (this tells Azure SDK in the app to use the user-assigned identity):
   - In pod spec:
     - spec.serviceAccountName: keda-worker-sa
     - env:
         - name: AZURE_CLIENT_ID
           value: "<managed_identity_client_id>"
   - KEDA Scalers can be configured to read the service bus queue and start the worker deploy when messages exist.

Notes:
- The terraform config already created the federated credential, so once `keda-worker-sa` exists in the same namespace and pods use that service account with the env var pointing at the client id, the pod can get tokens from Entra to access Service Bus and Storage.
- If your application uses Azure SDK's DefaultAzureCredential, having AZURE_CLIENT_ID set to the user-assigned client id makes it pick the workload identity token flow.

## Important security notes (short)
- Storage and Service Bus permissions are granted to the managed identity — pods using that identity get those permissions.
- Do not commit real `terraform.tfvars` with secrets.
- For production consider network restrictions, private endpoints, and least-privilege role scope.

## Troubleshooting checklist (if something doesn't work)
- Did `terraform apply` finish without errors? Check `terraform output` values.
- Is the service account created in the same namespace defined by `kubernetes_namespace`?
- Is AZURE_CLIENT_ID in your pod equal to `managed_identity_client_id` from Terraform outputs?
- Is AKS OIDC issuer URL reachable? (Terraform output `aks_oidc_issuer_url`)
- Check pod logs and events; check role assignment propagation (sometimes a short delay).

## Short mapping of terraform resources → plain meaning
- `azurerm_resource_group.rg` → group (folder) for the resources.
- `azurerm_storage_account.storage` + `azurerm_storage_container.container` → where files (blobs) are stored.
- `azurerm_servicebus_namespace.sb` + `azurerm_servicebus_queue.queue` → the message queue.
- `azurerm_eventgrid_system_topic.system_topic` + `..._event_subscription.event_sub` → sends blob-created messages into Service Bus.
- `azurerm_kubernetes_cluster.aks` → your Kubernetes playground (with OIDC and workload identity turned on).
- `azurerm_user_assigned_identity.worker_identity` → the Pod passport (user-assigned identity).
- `azurerm_federated_identity_credential.federated` → the handshake that lets that passport be used by a Kubernetes service account.
- `azurerm_role_assignment.*` → permissions given to the passport.

## Where to go next (short reading list)
- KEDA docs: https://keda.sh/docs/
- Azure Workload Identity (AKS): search "Azure AD Workload Identity AKS"
- Terraform azurerm provider docs: https://registry.terraform.io/providers/hashicorp/azurerm
- Azure Service Bus and Event Grid overviews on docs.microsoft.com / Microsoft Learn

---

Updated task list (all done)
- Read Terraform files in /terraform — completed
- Explain each file and resources simply — completed
- Teach AKS basics with kid-friendly analogies — completed
- Teach Azure identity/Entra and managed identities simply — completed
- Map repo terraform resources to AKS/identity concepts — completed
- Give step-by-step 'run this locally' and 'deploy' instructions — completed
- Provide concise further-reading links and next steps — completed

If you want, I can:
- Generate a ready-to-deploy Kubernetes manifest for a sample worker pod (with `serviceAccountName` and `AZURE_CLIENT_ID`), or
- Create a simple README snippet with the exact commands to run for your environment, or
- Walk through a real `terraform apply` in your terminal and help fix any errors step-by-step. Which would you like next?