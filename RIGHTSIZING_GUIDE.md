# The Agora Infrastructure - Right-sizing and Auto-scaling Guide

## 📊 Current vs. Optimized Configuration

### Current Setup (Oversized)

**Node Pools:**
- 3x Database nodes (standard.huge: 8 CPU, 16GB RAM) = ~€450/month
- 4x Storage nodes (standard.large: 4 CPU, 8GB RAM) = ~€200/month
- 3x Application nodes (standard.large: 4 CPU, 8GB RAM) = ~€150/month

**Total:** 10 nodes, 52 CPUs, 104GB RAM  
**Cost:** ~€800/month  
**Actual Usage:** 0.5 CPUs (1%), 5GB RAM (5%)  
**Waste:** 99% of resources unused!

---

### Recommended: Right-sized Setup

**Option 1: Minimal (Development/Testing)**
- 3x Multi-purpose nodes (standard.medium: 2 CPU, 4GB RAM)
- **Total:** 6 CPUs, 12GB RAM
- **Cost:** ~€90/month
- **Savings:** €710/month (89% reduction!)

**Option 2: Production-ready with Auto-scaling**
- 3x Multi-purpose nodes (standard.medium: 2 CPU, 4GB RAM) - Always on
- 0-3x Burst nodes (standard.large: 4 CPU, 8GB RAM) - Scale from 0
- **Cost:** €90-240/month (scales with load)
- **Savings:** €560-710/month

**Option 3: Balanced**
- 2x Multi-purpose nodes (standard.large: 4 CPU, 8GB RAM)
- 1x Database node (standard.huge: 8 CPU, 16GB RAM) - For production DB
- **Cost:** ~€250/month
- **Savings:** €550/month (69% reduction)

---

## 🎯 Recommended Approach: Option 2 (Auto-scaling)

### Why This Works

**Current Reality:**
- Your databases are using <1 CPU and <5GB RAM total
- You don't need dedicated node pools for different workloads yet
- Kubernetes can schedule everything efficiently on smaller nodes

**Auto-scaling Benefits:**
- **Start small:** 3 nodes (€90/month)
- **Scale automatically:** Add nodes when CPU/memory hits 70%
- **Scale to zero:** Burst pool only runs when needed
- **Pay for what you use:** No waste

---

## 🔧 How to Implement Auto-scaling

### Step 1: Deploy Kubernetes Cluster Autoscaler

```bash
# Install Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=the-agora \
  --set cloudProvider=exoscale \
  --set exoscale.apiKey=$EXOSCALE_API_KEY \
  --set exoscale.apiSecret=$EXOSCALE_API_SECRET \
  --set exoscale.zone=ch-gva-2
```

### Step 2: Deploy Horizontal Pod Autoscaler (HPA)

HPA automatically scales your application pods based on CPU/memory:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: agora-backend-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: agora-backend
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Step 3: Deploy Vertical Pod Autoscaler (VPA)

VPA automatically adjusts CPU/memory requests for your pods:

```bash
# Install VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

---

## 📉 Migration Plan

### Option A: Fresh Deployment (Recommended)

**Pros:** Clean start, optimized from day one  
**Cons:** Need to migrate data

**Steps:**
1. Export data from current databases
2. Deploy new right-sized cluster using `main-rightsized.tf`
3. Deploy databases on new cluster
4. Import data
5. Switch DNS/traffic
6. Delete old cluster

**Downtime:** ~1 hour  
**Immediate savings:** €710/month

---

### Option B: Gradual Migration

**Pros:** Zero downtime  
**Cons:** More complex, temporary dual costs

**Steps:**
1. Deploy new right-sized cluster
2. Set up database replication
3. Gradually move services
4. Monitor and validate
5. Delete old cluster

**Downtime:** 0  
**Savings start:** After migration complete

---

### Option C: In-place Optimization (Simplest)

**Pros:** No migration needed  
**Cons:** Still paying for oversized nodes

**Steps:**
1. Remove node pool taints/labels
2. Consolidate workloads onto fewer nodes
3. Scale down node pools
4. Eventually delete unused pools

**Downtime:** 0  
**Savings:** Gradual

---

## 💡 Database-specific Right-sizing

### PostgreSQL
**Current:** 8 CPU, 16GB RAM  
**Actual usage:** 0.1 CPU, 1GB RAM  
**Recommended:** 1 CPU, 2GB RAM (can scale up)

```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2
    memory: 4Gi
```

### Valkey
**Current:** 0.5 CPU, 1GB RAM  
**Actual usage:** 0.05 CPU, 200MB RAM  
**Recommended:** 250m CPU, 512MB RAM

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1
    memory: 2Gi
```

### RabbitMQ
**Current:** 1 CPU, 2GB RAM  
**Actual usage:** 0.05 CPU, 200MB RAM  
**Recommended:** 250m CPU, 512MB RAM

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 2
    memory: 4Gi
```

### MinIO
**Current:** 8 CPU (4 nodes × 2), 16GB RAM  
**Actual usage:** 0.2 CPU, 1GB RAM  
**Recommended:** Start with 1 node, scale to 4 as needed

```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2
    memory: 4Gi
```

---

## 🎯 Recommended Action Plan

### Immediate (This Week)
1. **Update database resource requests** to match actual usage
2. **Remove node pool taints** to allow workload consolidation
3. **Scale down to 5 nodes** (delete 5 nodes)
4. **Savings:** ~€400/month

### Short-term (Next 2 Weeks)
1. **Deploy Cluster Autoscaler**
2. **Deploy right-sized cluster** using `main-rightsized.tf`
3. **Migrate databases** with minimal downtime
4. **Delete old cluster**
5. **Savings:** ~€710/month

### Long-term (Next Month)
1. **Implement HPA** for application pods
2. **Implement VPA** for automatic resource tuning
3. **Monitor and optimize** based on actual usage patterns
4. **Set up alerts** for scaling events

---

## 📊 Cost Comparison Summary

| Configuration | Nodes | CPUs | RAM | Monthly Cost | Savings |
|--------------|-------|------|-----|--------------|---------|
| **Current (Oversized)** | 10 | 52 | 104GB | €800 | - |
| **Minimal** | 3 | 6 | 12GB | €90 | €710 (89%) |
| **Auto-scaling** | 3-6 | 6-18 | 12-36GB | €90-240 | €560-710 |
| **Balanced** | 3 | 16 | 28GB | €250 | €550 (69%) |

---

## 🚀 Quick Start: Deploy Right-sized Cluster

```bash
cd ~/the-agora-infrastructure

# Backup current cluster config
cp main.tf main-oversized.tf.bak

# Use right-sized config
cp main-rightsized.tf main.tf

# Plan the changes
terraform plan

# Apply (this will create a NEW cluster)
terraform apply

# Get new kubeconfig
terraform output -raw kubeconfig > ~/.kube/config-new

# Test new cluster
KUBECONFIG=~/.kube/config-new kubectl get nodes

# Migrate databases (see migration guide)
# ...

# Switch to new cluster
cp ~/.kube/config-new ~/.kube/config

# Delete old cluster
# (update terraform to remove old cluster resources)
```

---

## 📈 Monitoring Auto-scaling

### Watch Cluster Autoscaler
```bash
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

### Watch HPA
```bash
kubectl get hpa --watch
```

### Check Node Scaling Events
```bash
kubectl get events --sort-by='.lastTimestamp' | grep -i scale
```

---

## 🎯 Bottom Line

**You're currently spending €800/month for resources you're not using.**

**Recommended action:**
1. **Immediate:** Scale down to 5 nodes → Save €400/month
2. **This month:** Deploy right-sized cluster with auto-scaling → Save €710/month
3. **Total annual savings:** €8,520

**The right-sized cluster will:**
- ✅ Handle your current load easily
- ✅ Auto-scale when traffic increases
- ✅ Cost 89% less
- ✅ Still be production-ready

**Want me to help you migrate to the right-sized cluster?**

