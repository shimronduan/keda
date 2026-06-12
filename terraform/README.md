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
