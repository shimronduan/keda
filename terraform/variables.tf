variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-event-driven-demo"
}

# Storage Account Configuration
variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, lowercase alphanumeric only)"
  type        = string
  default     = "stblobeventdemo123"
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "storage_container_name" {
  description = "Name of the blob storage container"
  type        = string
  default     = "uploads"
}

# Service Bus Configuration
variable "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
  default     = "sb-event-demo-123"
}

variable "servicebus_sku" {
  description = "SKU of the Service Bus namespace"
  type        = string
  default     = "Standard"
}

variable "servicebus_queue_name" {
  description = "Name of the Service Bus queue"
  type        = string
  default     = "blob-uploads-queue"
}

# AKS Configuration
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-event-demo"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aks-demo"
}

variable "aks_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# Event Grid Configuration
variable "eventgrid_system_topic_name" {
  description = "Name of the Event Grid system topic"
  type        = string
  default     = "storage-system-topic"
}

variable "eventgrid_subscription_name" {
  description = "Name of the Event Grid event subscription"
  type        = string
  default     = "blob-created-subscription"
}

variable "eventgrid_included_event_types" {
  description = "Event types to subscribe to"
  type        = list(string)
  default     = ["Microsoft.Storage.BlobCreated"]
}

# Workload Identity Configuration
variable "managed_identity_name" {
  description = "Name of the user-assigned managed identity"
  type        = string
  default     = "id-aks-worker"
}

variable "federated_identity_name" {
  description = "Name of the federated identity credential"
  type        = string
  default     = "aks-worker-federated"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the KEDA worker"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account for the KEDA worker"
  type        = string
  default     = "keda-worker-sa"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "event-driven-demo"
    managed_by  = "terraform"
  }
}
