locals {
  # Commonly used naming convention
  name_prefix = "${var.environment}"

  # Merge default tags with any additional tags
  common_tags = merge(
    var.tags,
    {
      deployed_at = timestamp()
    }
  )

  # Kubernetes RBAC identifier
  kubernetes_service_account_oidc = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"

  # RBAC Role Names
  rbac_roles = {
    servicebus_receiver = "Azure Service Bus Data Receiver"
    blob_reader         = "Storage Blob Data Reader"
  }
}
