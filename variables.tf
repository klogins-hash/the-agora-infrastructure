variable "exoscale_api_key" {
  description = "Exoscale API Key"
  type        = string
  sensitive   = true
}

variable "exoscale_api_secret" {
  description = "Exoscale API Secret"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Exoscale zone"
  type        = string
  default     = "ch-gva-2"  # Geneva, Switzerland
}

variable "cluster_name" {
  description = "Name of the SKS cluster"
  type        = string
  default     = "the-agora"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.13"
}

variable "database_nodepool_size" {
  description = "Number of nodes in database node pool"
  type        = number
  default     = 3
}

variable "database_instance_type" {
  description = "Instance type for database nodes"
  type        = string
  default     = "standard.huge"  # 8 CPU, 16GB RAM
}

variable "storage_nodepool_size" {
  description = "Number of nodes in storage node pool"
  type        = number
  default     = 4
}

variable "storage_instance_type" {
  description = "Instance type for storage nodes"
  type        = string
  default     = "standard.large"  # 4 CPU, 8GB RAM
}

variable "app_nodepool_size" {
  description = "Number of nodes in application node pool"
  type        = number
  default     = 3
}

variable "app_instance_type" {
  description = "Instance type for application nodes"
  type        = string
  default     = "standard.large"  # 4 CPU, 8GB RAM
}

variable "disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
}

