# Security Group for SKS nodes
resource "exoscale_security_group" "sks_nodes" {
  name        = "${var.cluster_name}-sks-nodes"
  description = "Security group for The Agora SKS nodes"
}

# Allow all traffic within the security group (for node-to-node communication)
resource "exoscale_security_group_rule" "sks_nodes_internal" {
  security_group_id      = exoscale_security_group.sks_nodes.id
  description            = "Allow internal communication between nodes"
  type                   = "INGRESS"
  protocol               = "TCP"
  start_port             = 1
  end_port               = 65535
  user_security_group_id = exoscale_security_group.sks_nodes.id
}

# Allow NodePort services (30000-32767)
resource "exoscale_security_group_rule" "sks_nodeport" {
  security_group_id = exoscale_security_group.sks_nodes.id
  description       = "Allow NodePort services"
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 30000
  end_port          = 32767
  cidr              = "0.0.0.0/0"
}

# Allow HTTPS (for kubectl access)
resource "exoscale_security_group_rule" "sks_https" {
  security_group_id = exoscale_security_group.sks_nodes.id
  description       = "Allow HTTPS"
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 443
  end_port          = 443
  cidr              = "0.0.0.0/0"
}

# Allow HTTP (for web access)
resource "exoscale_security_group_rule" "sks_http" {
  security_group_id = exoscale_security_group.sks_nodes.id
  description       = "Allow HTTP"
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 80
  end_port          = 80
  cidr              = "0.0.0.0/0"
}

# SKS Cluster
resource "exoscale_sks_cluster" "the_agora" {
  zone    = var.zone
  name    = var.cluster_name
  version = var.kubernetes_version
  cni     = "calico"
  
  service_level = "starter"  # Use "pro" for HA control plane
  
  auto_upgrade = false  # Manual control over upgrades
  
  # Enable Exoscale CSI driver for persistent volumes
  exoscale_csi = true
}

# Node Pool 1: Database Workloads (PostgreSQL, Valkey, RabbitMQ)
resource "exoscale_sks_nodepool" "database" {
  cluster_id         = exoscale_sks_cluster.the_agora.id
  zone               = var.zone
  name               = "database-pool"
  instance_type      = var.database_instance_type
  size               = var.database_nodepool_size
  disk_size          = var.disk_size
  security_group_ids = [exoscale_security_group.sks_nodes.id]
  
  labels = {
    "workload" = "database"
    "pool"     = "database"
  }
  
  taints = {
    "workload" = "database:NoSchedule"
  }
}

# Node Pool 2: Storage Workloads (MinIO)
resource "exoscale_sks_nodepool" "storage" {
  cluster_id         = exoscale_sks_cluster.the_agora.id
  zone               = var.zone
  name               = "storage-pool"
  instance_type      = var.storage_instance_type
  size               = var.storage_nodepool_size
  disk_size          = 400  # Max for standard.large
  security_group_ids = [exoscale_security_group.sks_nodes.id]
  
  labels = {
    "workload" = "storage"
    "pool"     = "storage"
  }
  
  taints = {
    "workload" = "storage:NoSchedule"
  }
}

# Node Pool 3: Application Workloads (FastAPI, React)
resource "exoscale_sks_nodepool" "application" {
  cluster_id         = exoscale_sks_cluster.the_agora.id
  zone               = var.zone
  name               = "app-pool"
  instance_type      = var.app_instance_type
  size               = var.app_nodepool_size
  disk_size          = var.disk_size
  security_group_ids = [exoscale_security_group.sks_nodes.id]
  
  labels = {
    "workload" = "application"
    "pool"     = "application"
  }
}

# Get the kubeconfig
resource "exoscale_sks_kubeconfig" "the_agora" {
  cluster_id = exoscale_sks_cluster.the_agora.id
  zone       = var.zone
  
  user   = "terraform-admin"
  groups = ["system:masters"]
  
  ttl_seconds = 0  # Never expires
}

