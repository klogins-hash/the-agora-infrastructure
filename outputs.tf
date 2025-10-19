output "cluster_id" {
  description = "SKS Cluster ID"
  value       = exoscale_sks_cluster.the_agora.id
}

output "cluster_endpoint" {
  description = "SKS Cluster API endpoint"
  value       = exoscale_sks_cluster.the_agora.endpoint
}

output "cluster_name" {
  description = "SKS Cluster name"
  value       = exoscale_sks_cluster.the_agora.name
}

output "kubeconfig" {
  description = "Kubernetes configuration file"
  value       = exoscale_sks_kubeconfig.the_agora.kubeconfig
  sensitive   = true
}

output "database_nodepool_id" {
  description = "Database node pool ID"
  value       = exoscale_sks_nodepool.database.id
}

output "storage_nodepool_id" {
  description = "Storage node pool ID"
  value       = exoscale_sks_nodepool.storage.id
}

output "application_nodepool_id" {
  description = "Application node pool ID"
  value       = exoscale_sks_nodepool.application.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = exoscale_security_group.sks_nodes.id
}

