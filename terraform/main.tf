################################################################################
# Resource Group
################################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

################################################################################
# Storage Account - Event Source
################################################################################

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  tags = local.common_tags
}

resource "azurerm_storage_container" "container" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

################################################################################
# Service Bus - Event Queue
################################################################################

resource "azurerm_servicebus_namespace" "sb" {
  name                = var.servicebus_namespace_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.servicebus_sku

  tags = local.common_tags
}

resource "azurerm_servicebus_queue" "queue" {
  name         = var.servicebus_queue_name
  namespace_id = azurerm_servicebus_namespace.sb.id
}

################################################################################
# AKS Cluster - Workload Identity enabled for KEDA
################################################################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = var.aks_node_pool_name
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  # Required for Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = local.common_tags
}

################################################################################
# Event Grid - Blob Event Subscription
################################################################################

resource "azurerm_eventgrid_system_topic" "system_topic" {
  name                   = var.eventgrid_system_topic_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  source_arm_resource_id = azurerm_storage_account.storage.id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  tags = local.common_tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "event_sub" {
  name                = var.eventgrid_subscription_name
  system_topic        = azurerm_eventgrid_system_topic.system_topic.name
  resource_group_name = azurerm_resource_group.rg.name

  service_bus_queue_endpoint_id = azurerm_servicebus_queue.queue.id
  included_event_types          = var.eventgrid_included_event_types
}

################################################################################
# Workload Identity - Enable AKS pods to authenticate to Azure
################################################################################

# User-assigned managed identity for the KEDA worker pod
resource "azurerm_user_assigned_identity" "worker_identity" {
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = local.common_tags
}

# Federated identity credential linking Kubernetes service account to Azure managed identity
resource "azurerm_federated_identity_credential" "federated" {
  name                = var.federated_identity_name
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.worker_identity.id
  subject             = local.kubernetes_service_account_oidc
}

################################################################################
# RBAC - Service Permissions for KEDA Worker
################################################################################

# Allow worker to receive messages from Service Bus
resource "azurerm_role_assignment" "sb_receiver" {
  scope              = azurerm_servicebus_namespace.sb.id
  role_definition_name = local.rbac_roles.servicebus_receiver
  principal_id       = azurerm_user_assigned_identity.worker_identity.principal_id
}

# Allow worker to read blob data from storage
resource "azurerm_role_assignment" "blob_reader" {
  scope              = azurerm_storage_account.storage.id
  role_definition_name = local.rbac_roles.blob_reader
  principal_id       = azurerm_user_assigned_identity.worker_identity.principal_id
}

# Create the Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acreventsdemo123" # NOTE: Must be globally unique and alphanumeric only!
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # Best practice: disable admin user, use Azure AD (managed identity) instead
}

# Grant the AKS cluster's Kubelet identity permission to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

