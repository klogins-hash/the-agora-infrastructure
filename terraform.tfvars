exoscale_api_key    = "EXOd4e0bc1d6ea62bf2d414b24e"
exoscale_api_secret = "ekOsjtNAEUCDD35rp2T80xQfqYQ4Bp1R1qxfjx1voKw"

zone               = "ch-gva-2"
cluster_name       = "the-agora"
kubernetes_version = "1.31.13"

# Database node pool (PostgreSQL, Valkey, RabbitMQ)
database_nodepool_size = 3
database_instance_type = "standard.huge"  # 8 CPU, 16GB RAM

# Storage node pool (MinIO)
storage_nodepool_size = 4
storage_instance_type = "standard.large"  # 4 CPU, 8GB RAM

# Application node pool (FastAPI, React)
app_nodepool_size = 3
app_instance_type = "standard.large"  # 4 CPU, 8GB RAM

disk_size = 100

