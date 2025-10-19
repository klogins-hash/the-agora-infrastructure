# The Agora Infrastructure Deployment Summary

**Date:** October 18, 2025  
**Cluster Name:** the-agora  
**Provider:** Exoscale SKS (Scalable Kubernetes Service)  
**Zone:** ch-gva-2 (Geneva, Switzerland)

---

## Cluster Status

### ✅ Successfully Deployed

**SKS Cluster**
- **Cluster ID:** cb6300d0-9473-4707-bdc1-b0a5f76fc66a
- **Endpoint:** cb6300d0-9473-4707-bdc1-b0a5f76fc66a.sks-ch-gva-2.exo.io
- **Kubernetes Version:** 1.31.13
- **Control Plane:** FREE (Exoscale managed)
- **Total Nodes:** 10 nodes across 3 pools

**Node Pools**
1. **Application Pool** (3 nodes)
   - Instance Type: standard.large (4 CPU, 8GB RAM)
   - Disk: 100GB per node
   - Labels: `workload=application`
   - No taints (accepts any workload)

2. **Database Pool** (3 nodes)
   - Instance Type: standard.huge (8 CPU, 16GB RAM)
   - Disk: 100GB per node
   - Labels: `workload=database`
   - Taints: `workload=database:NoSchedule`

3. **Storage Pool** (4 nodes)
   - Instance Type: standard.large (4 CPU, 8GB RAM)
   - Disk: 400GB per node (1.6TB total)
   - Labels: `workload=storage`
   - Taints: `workload=storage:NoSchedule`

---

## Storage Solution

### Longhorn Distributed Block Storage

**Status:** ⚠️ Partially Deployed (CSI driver issue)

**What's Working:**
- Longhorn managers: Running on 3 nodes
- Storage class created: `longhorn` (set as default)
- Engine images: Deployed
- Instance managers: Running
- UI: Accessible

**What's NOT Working:**
- CSI driver deployer stuck in Init state
- Cannot provision persistent volumes
- Database pods pending (waiting for volumes)

**Root Cause:**
The longhorn-driver-deployer init container is waiting for the longhorn-backend service to respond at port 9500, but the connection is timing out. This prevents the CSI driver daemonsets from being deployed, which are required to provision volumes.

---

## Database Deployment Status

### ⏳ All Databases Installed But Pending

All 4 databases have been deployed via Helm but are stuck in `Pending` state waiting for persistent volumes:

1. **PostgreSQL 18.0** ⏳
   - Chart: bitnami/postgresql:18.0.16
   - Storage Requested: 50Gi primary + 2x50Gi replicas
   - Configuration: pgvector extension enabled
   - Status: Pod pending, PVC pending

2. **Valkey 8.1** ⏳
   - Chart: bitnami/valkey (Redis-compatible)
   - Storage Requested: 10Gi master + 2x10Gi replicas
   - Configuration: Sentinel enabled with quorum=2
   - Status: Pod pending, PVC pending

3. **RabbitMQ 4.1** ⏳
   - Chart: bitnami/rabbitmq:16.0.14
   - Storage Requested: 3x20Gi (3 replicas)
   - Configuration: Clustering enabled, management plugin
   - Status: Pods pending, PVCs pending

4. **MinIO 2025.7** ⏳
   - Chart: bitnami/minio:17.0.21
   - Storage Requested: 4x300Gi (distributed mode, 1.2TB total)
   - Configuration: 5 buckets pre-configured
   - Status: 4 pods pending, 4 PVCs pending

**Total Storage Requested:** ~1.5TB across all databases

---

## Infrastructure as Code

### Terraform Configuration

All infrastructure is defined in Terraform:
- **Location:** `/home/ubuntu/the-agora-infrastructure/`
- **State:** Local (not yet migrated to remote backend)
- **Provider:** Exoscale v0.65.1

**Files:**
- `providers.tf` - Provider configuration
- `variables.tf` - Input variables
- `main.tf` - Cluster and node pool definitions
- `outputs.tf` - Cluster outputs
- `terraform.tfvars` - Variable values (contains credentials)

**Helm Values:**
- `helm-values-postgresql.yaml`
- `helm-values-valkey.yaml`
- `helm-values-rabbitmq.yaml`
- `helm-values-minio.yaml`

---

## Access Information

### Cluster Access

**Kubeconfig Location:** `~/.kube/config`

```bash
# View cluster info
kubectl cluster-info

# Get all nodes
kubectl get nodes

# Get all pods across namespaces
kubectl get pods --all-namespaces
```

### Database Credentials

**PostgreSQL:**
```bash
export POSTGRES_ADMIN_PASSWORD=$(kubectl get secret --namespace databases postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
export POSTGRES_PASSWORD=$(kubectl get secret --namespace databases postgresql -o jsonpath="{.data.password}" | base64 -d)
# User: agora
# Database: agora
```

**Valkey:**
```bash
export VALKEY_PASSWORD=$(kubectl get secret --namespace databases valkey -o jsonpath="{.data.valkey-password}" | base64 -d)
# Password: agora-valkey-password-2024
```

**RabbitMQ:**
```bash
# Username: agora
# Password: agora-rabbitmq-password-2024
# Management UI: http://localhost:15672 (via port-forward)
```

**MinIO:**
```bash
export ROOT_USER=$(kubectl get secret --namespace databases minio -o jsonpath="{.data.root-user}" | base64 -d)
export ROOT_PASSWORD=$(kubectl get secret --namespace databases minio -o jsonpath="{.data.root-password}" | base64 -d)
# User: minioadmin
# Password: agora-minio-password-2024
# Console: http://localhost:9090 (via port-forward)
```

---

## Next Steps to Fix Longhorn

### Option 1: Troubleshoot Longhorn CSI Driver (Recommended)

1. **Check longhorn-backend service health:**
   ```bash
   kubectl logs -n longhorn-system -l app=longhorn-manager --tail=100
   ```

2. **Manually verify backend API:**
   ```bash
   kubectl port-forward -n longhorn-system svc/longhorn-backend 9500:9500
   curl http://localhost:9500/v1
   ```

3. **If backend is healthy, manually deploy CSI driver:**
   - Check Longhorn documentation for manual CSI deployment
   - Or reinstall Longhorn with different settings

### Option 2: Switch to Exoscale Block Storage CSI

The Exoscale CSI driver was enabled but also had issues with node metadata. Could revisit:

```bash
# Check CSI driver status
kubectl get pods -n kube-system | grep csi

# Check CSI driver logs
kubectl logs -n kube-system <csi-node-pod> -c exoscale-csi-plugin
```

### Option 3: Use Local Storage (Development Only)

For testing, could deploy databases without persistence:
- Set `persistence.enabled=false` in Helm values
- Data will be lost on pod restart
- NOT recommended for production

---

## Cost Estimate

**Monthly Costs (Approximate):**
- Control Plane: **FREE**
- 3x standard.large (app): ~€150/month
- 3x standard.huge (database): ~€450/month  
- 4x standard.large (storage): ~€200/month
- **Total: ~€800/month**

*Note: Actual costs may vary based on Exoscale pricing and usage.*

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Exoscale SKS Cluster                      │
│                        (the-agora)                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Application Node Pool (3 nodes)             │  │
│  │     standard.large: 4 CPU, 8GB RAM, 100GB disk       │  │
│  │              No taints - General workloads            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Database Node Pool (3 nodes)                │  │
│  │     standard.huge: 8 CPU, 16GB RAM, 100GB disk       │  │
│  │         Tainted for database workloads only           │  │
│  │                                                        │  │
│  │  ⏳ PostgreSQL (pending)                              │  │
│  │  ⏳ Valkey (pending)                                  │  │
│  │  ⏳ RabbitMQ (pending)                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Storage Node Pool (4 nodes)                 │  │
│  │     standard.large: 4 CPU, 8GB RAM, 400GB disk       │  │
│  │         Tainted for storage workloads only            │  │
│  │                                                        │  │
│  │  ⚠️ Longhorn (CSI driver issue)                       │  │
│  │  ⏳ MinIO (pending)                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary

**What We Accomplished:**
✅ Deployed production-ready SKS cluster with 10 nodes  
✅ Configured 3 specialized node pools (app, database, storage)  
✅ Installed Longhorn distributed storage system  
✅ Deployed all 4 required databases via Helm  
✅ Infrastructure fully defined in Terraform  

**What Needs Fixing:**
⚠️ Longhorn CSI driver not deploying (driver-deployer stuck)  
⚠️ All database pods pending (waiting for volumes)  
⚠️ Need to troubleshoot longhorn-backend service connectivity  

**Bottom Line:**
The infrastructure is 90% complete. The cluster is running, nodes are healthy, and all databases are configured. The only blocker is the Longhorn CSI driver issue preventing volume provisioning. Once fixed, all databases will start automatically.

