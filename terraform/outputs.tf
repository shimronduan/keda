output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.rg.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_container_id" {
  description = "ID of the storage container"
  value       = azurerm_storage_container.container.id
}

output "servicebus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.sb.id
}

output "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.sb.name
}

output "servicebus_queue_id" {
  description = "ID of the Service Bus queue"
  value       = azurerm_servicebus_queue.queue.id
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "Kubernetes configuration for AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster (required for Workload Identity)"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "managed_identity_id" {
  description = "ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.worker_identity.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.worker_identity.principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.worker_identity.client_id
}

output "eventgrid_system_topic_id" {
  description = "ID of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.system_topic.id
}

output "kubernetes_service_account_oidc" {
  description = "Kubernetes service account OIDC identifier for Workload Identity configuration"
  value       = local.kubernetes_service_account_oidc
}
