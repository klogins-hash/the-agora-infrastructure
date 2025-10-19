# Platform Pricing Comparison for The Agora Infrastructure

**Date:** October 19, 2025  
**Comparison:** Exoscale vs Fly.io vs Render vs Railway

---

## Your Infrastructure Requirements

### Databases & Services
- **PostgreSQL 18.0:** 50GB storage, 2-4 CPU, 4-8GB RAM
- **Valkey (Redis):** 10GB storage, 1-2 CPU, 2-4GB RAM  
- **RabbitMQ:** 20GB storage, 2 CPU, 4GB RAM
- **MinIO:** 1TB storage, 4 CPU, 8GB RAM (distributed)

### Applications
- **The Agora Backend:** FastAPI (2 CPU, 4GB RAM)
- **The Agora Frontend:** React/Vite (1 CPU, 2GB RAM)
- **ADHD Voice Assistant:** Node.js webhook (1 CPU, 1GB RAM)
- **Kong/Forgejo:** API Gateway + Git hosting (2 CPU, 4GB RAM each)

### Total Resources Needed
- **CPU:** 14-18 vCPUs
- **RAM:** 25-35 GB
- **Storage:** 1.1 TB (mostly MinIO)
- **Bandwidth:** ~500 GB/month (estimated)

---

## 1. Exoscale (Current - Oversized)

### Current Setup (10 nodes)
- **Cost:** €800/month (~$880/month)
- **Resources:** 52 CPUs, 104GB RAM, 2TB storage
- **Utilization:** 1% CPU, 5% memory (MASSIVE WASTE!)

### Right-Sized Setup (3-6 nodes with auto-scaling)
**Starting Configuration:**
- 3x standard.medium (2 CPU, 4GB RAM each)
- **Base cost:** €90/month (~$100/month)

**Auto-scaled (peak):**
- 6x standard.medium
- **Peak cost:** €180/month (~$200/month)

**With managed services (alternative):**
- Managed PostgreSQL: €95/month
- Managed Redis: €32/month
- 2x compute nodes: €60/month
- **Total:** €187/month (~$205/month)

### Pros
✅ European data sovereignty (Swiss/German)  
✅ Kubernetes native (SKS)  
✅ Block storage CSI driver  
✅ Free control plane  
✅ GDPR compliant

### Cons
❌ Smaller ecosystem than US providers  
❌ CSI driver has issues (we worked around it)  
❌ Less documentation

---

## 2. Fly.io

### Pricing Model
- **CPU:** $0.02/hour per shared CPU (~$14.40/month)
- **Memory:** $0.0000022/MB/sec (~$5.70/GB/month)
- **Storage:** $0.15/GB/month
- **Bandwidth:** $0.02/GB (first 100GB free)

### Your Infrastructure Cost

**Databases:**
- PostgreSQL (4 CPU, 8GB RAM, 50GB): ~$115/month
- Redis (2 CPU, 4GB RAM, 10GB): ~$60/month
- RabbitMQ (2 CPU, 4GB RAM, 20GB): ~$63/month
- MinIO (4 CPU, 8GB RAM, 1TB): ~$215/month

**Applications:**
- The Agora Backend (2 CPU, 4GB RAM): ~$52/month
- The Agora Frontend (1 CPU, 2GB RAM): ~$26/month
- ADHD Assistant (1 CPU, 1GB RAM): ~$20/month
- Kong + Forgejo (4 CPU, 8GB RAM): ~$104/month

**Bandwidth:** ~$8/month (500GB - 100GB free = 400GB × $0.02)

**Total: ~$663/month**

### Pros
✅ Global edge network (35+ regions)  
✅ Excellent developer experience  
✅ Built-in Postgres & Redis  
✅ Automatic SSL certificates  
✅ Great documentation  
✅ Fast deployments

### Cons
❌ More expensive than Exoscale  
❌ US-based (data sovereignty concerns)  
❌ No Kubernetes (custom orchestration)

---

## 3. Render

### Pricing Model
- **Web Services:** $7-85/month per service
- **PostgreSQL:** $95/month (2 CPU, 4GB RAM, 96GB storage)
- **Redis:** $32/month (1GB RAM)
- **Storage:** $0.30/GB/month
- **Bandwidth:** Free egress

### Your Infrastructure Cost

**Databases:**
- PostgreSQL (Standard): $95/month
- Redis (1GB): $32/month
- RabbitMQ (web service): $85/month (8GB RAM)
- MinIO (web service + storage): $85 + $300 = $385/month

**Applications:**
- The Agora Backend (4GB RAM): $85/month
- The Agora Frontend (static): $0/month (free tier)
- ADHD Assistant (512MB): $7/month
- Kong + Forgejo (8GB RAM total): $170/month

**Total: ~$859/month**

### Pros
✅ Simple pricing  
✅ Free static site hosting  
✅ Free SSL certificates  
✅ Auto-deploy from Git  
✅ Good for startups

### Cons
❌ MOST EXPENSIVE option  
❌ Limited customization  
❌ No Kubernetes  
❌ Storage is expensive

---

## 4. Railway

### Pricing Model
- **CPU:** $20/vCPU/month
- **Memory:** $10/GB/month
- **Storage:** $0.15/GB/month (persistent volumes)
- **Bandwidth:** $0.05/GB
- **Includes $5 credit/month on Hobby plan**

### Your Infrastructure Cost

**Databases:**
- PostgreSQL (4 CPU, 8GB RAM, 50GB): $80 + $80 + $7.50 = $167.50/month
- Redis (2 CPU, 4GB RAM, 10GB): $40 + $40 + $1.50 = $81.50/month
- RabbitMQ (2 CPU, 4GB RAM, 20GB): $40 + $40 + $3 = $83/month
- MinIO (4 CPU, 8GB RAM, 1TB): $80 + $80 + $150 = $310/month

**Applications:**
- The Agora Backend (2 CPU, 4GB RAM): $40 + $40 = $80/month
- The Agora Frontend (1 CPU, 2GB RAM): $20 + $20 = $40/month
- ADHD Assistant (1 CPU, 1GB RAM): $20 + $10 = $30/month
- Kong + Forgejo (4 CPU, 8GB RAM): $80 + $80 = $160/month

**Bandwidth:** $25/month (500GB × $0.05)

**Total: ~$977/month**  
**With $5 credit: ~$972/month**

### Pros
✅ Simple, predictable pricing  
✅ Great developer experience  
✅ Fast deployments  
✅ Good for prototyping

### Cons
❌ MOST EXPENSIVE option  
❌ CPU pricing is very high  
❌ No free tier for production  
❌ Limited regions

---

## Cost Comparison Summary

| Platform | Monthly Cost | Annual Cost | vs Exoscale (Right-sized) |
|----------|-------------|-------------|---------------------------|
| **Exoscale (Right-sized)** | **$100-200** | **$1,200-2,400** | **Baseline** |
| **Fly.io** | **$663** | **$7,956** | **+231% to +563%** |
| **Render** | **$859** | **$10,308** | **+330% to +759%** |
| **Railway** | **$972** | **$11,664** | **+386% to +872%** |
| Exoscale (Current) | $880 | $10,560 | +340% to +780% |

---

## Recommendation by Use Case

### 🏆 Best Overall Value: Exoscale (Right-sized)
**Cost:** $100-200/month  
**Best for:** Production workloads, European customers, cost-conscious teams  
**Savings:** $563-872/month vs alternatives

### 🚀 Best Developer Experience: Fly.io
**Cost:** $663/month  
**Best for:** Global edge deployment, teams prioritizing DX over cost  
**Premium:** +$463-563/month vs Exoscale

### 🎯 Best for Simplicity: Render
**Cost:** $859/month  
**Best for:** Teams wanting managed everything, no DevOps  
**Premium:** +$659-759/month vs Exoscale

### 💰 Most Expensive: Railway
**Cost:** $972/month  
**Best for:** Rapid prototyping, teams with budget  
**Premium:** +$772-872/month vs Exoscale

---

## Hidden Costs to Consider

### Exoscale
- ✅ No egress fees
- ✅ No support fees (community)
- ❌ DevOps time (Kubernetes management)

### Fly.io
- ✅ No support fees
- ✅ Minimal DevOps
- ❌ Bandwidth overages can add up

### Render
- ✅ Free egress
- ✅ Zero DevOps
- ❌ Limited customization may require workarounds

### Railway
- ✅ Simple billing
- ❌ Bandwidth costs add up quickly
- ❌ No free tier for production

---

## My Recommendation

**Stay with Exoscale, but right-size it:**

1. **Immediate action:** Scale down to 3-6 nodes → Save $680/month
2. **Enable auto-scaling:** Handle traffic spikes automatically
3. **Use local storage:** Avoid CSI driver issues (already solved)
4. **Deploy all services:** Consolidate Kong, Forgejo, The Agora, ADHD Assistant

**Annual savings vs alternatives:**
- vs Fly.io: **$5,556-6,756/year**
- vs Render: **$7,908-9,108/year**
- vs Railway: **$9,264-10,464/year**

**That's enough to hire a part-time DevOps engineer!**

---

## When to Consider Alternatives

**Choose Fly.io if:**
- You need global edge deployment (multi-region)
- Developer experience is worth $500/month premium
- You're targeting international users

**Choose Render if:**
- You have zero DevOps skills
- You want managed everything
- Budget is not a constraint

**Choose Railway if:**
- You're prototyping and need speed
- You have significant funding
- You plan to migrate later

**Choose Exoscale if:**
- You want best price/performance
- European data sovereignty matters
- You're comfortable with Kubernetes
- You want to save $6,000-10,000/year

---

## Bottom Line

**Exoscale right-sized = $100-200/month**  
**Everything else = $663-972/month**

**You're already on the cheapest platform. Just need to optimize it!**

The $680/month you're currently wasting on oversized infrastructure could pay for:
- 3-4 months of Fly.io hosting
- A junior developer for 2 weeks
- Your entire infrastructure for 3-7 months

**Recommendation: Stay with Exoscale, right-size it, save $680/month immediately.**

