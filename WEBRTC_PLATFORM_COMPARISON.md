# WebRTC Platform Comparison: LiveKit Cloud vs Pipecat Cloud vs Self-Hosted

**Date:** October 19, 2025  
**For:** The Agora - WebRTC AI Collaboration Platform

---

## Executive Summary

**YES! You're absolutely right** - both LiveKit Cloud and Pipecat Cloud (Daily.co) offer **global edge deployment out of the box**, which completely changes the cost equation for The Agora's WebRTC requirements.

### The Winner: LiveKit Cloud + Self-Hosted Backend

**Hybrid Architecture:**
- **LiveKit Cloud:** WebRTC media transport (global edge) - $0.014/min
- **Exoscale:** Databases + backend (right-sized) - $100-200/month
- **Total:** ~$200-400/month (depending on usage)

**This beats pure self-hosted AND is cheaper than Fly.io!**

---

## Platform Comparison

### 1. LiveKit Cloud ⭐ RECOMMENDED

#### What You Get
- **Global edge network** - 99.99% uptime, CDN-scale
- **Multi-region deployment** - Automatic routing to nearest edge
- **Agent deployment** - Fully managed AI agent hosting
- **Telephony** - SIP/PSTN integration built-in
- **Open source** - Can self-host later if needed

#### Pricing

**For The Agora's Use Case:**

**Build Tier (FREE):**
- $0/month base
- 1,000 free agent session minutes/month
- Includes:
  - Agent deployment
  - Global edge network ✅
  - Telephony
  - Session metrics
  - Community support

**Ship Tier ($50/month):**
- Everything in Build
- Team collaboration
- Email support
- Instant rollback

**Per-Minute Costs:**
- **Agent session:** $0.014/min (WebRTC voice agent)
- **Phone call (SIP):** $0.022/min (includes telephony provider)
- **Data transfer:** Included in session pricing

#### Monthly Cost Estimates

**Light usage (1,000 min/month):**
- FREE (included in Build tier)

**Moderate usage (10,000 min/month):**
- $50 (Ship tier) + $140 (9,000 × $0.014) = **$190/month**

**Heavy usage (50,000 min/month):**
- $50 + $700 (49,000 × $0.014) = **$750/month**

**Enterprise (100,000 min/month):**
- $500 (Scale tier) + $1,400 = **$1,900/month**

#### Pros
✅ **Global edge network** - Best WebRTC performance worldwide  
✅ **Open source** - Can self-host if needed  
✅ **Powers ChatGPT Advanced Voice Mode** - Proven at massive scale  
✅ **Free tier** - 1,000 minutes/month  
✅ **Vendor neutral** - Use any LLM/TTS/STT  
✅ **Built for AI agents** - Native agent deployment

#### Cons
❌ Costs scale with usage (but predictable)  
❌ Requires LiveKit SDK integration

---

### 2. Pipecat Cloud (Daily.co)

#### What You Get
- **Global WebRTC infrastructure** - Daily's proven network
- **Pipecat framework** - Open source voice AI orchestration
- **80+ service providers** - LLM, STT, TTS integrations
- **Multi-region** - Global edge deployment
- **Telephony** - SIP/PSTN built-in

#### Pricing

**Pipecat Hosting:**
- **Active agents:** $0.01/session minute
- **Reserved agents:** $0.0005/minute (always-on, no cold start)

**Transport:**
- **WebRTC Voice:** $0.001/participant minute (FREE with Pipecat Cloud!)
- **WebRTC Voice + Video:** $0.004/participant minute
- **Websocket:** Bring your own (billed to provider)

**Telephony:**
- **SIP:** $0.005/minute
- **PSTN:** $0.018/minute

**Additional:**
- **Krisp noise removal:** FREE (0-100k minutes)
- **Recording:** $0.01349/minute
- **Concurrency limit:** 50 simultaneous agents (default)

#### Monthly Cost Estimates

**Light usage (1,000 min/month):**
- Agent hosting: 1,000 × $0.01 = $10
- WebRTC transport: FREE
- **Total: $10/month**

**Moderate usage (10,000 min/month):**
- Agent hosting: 10,000 × $0.01 = $100
- WebRTC transport: FREE
- **Total: $100/month**

**Heavy usage (50,000 min/month):**
- Agent hosting: 50,000 × $0.01 = $500
- WebRTC transport: FREE
- **Total: $500/month**

**Enterprise (100,000 min/month):**
- Agent hosting: 100,000 × $0.01 = $1,000
- WebRTC transport: FREE
- **Total: $1,000/month** (volume pricing available)

#### Pros
✅ **Cheaper than LiveKit** at scale  
✅ **Pipecat framework** - Excellent for voice AI  
✅ **FREE WebRTC transport** - Included with hosting  
✅ **80+ integrations** - Easy to swap providers  
✅ **Krisp noise removal** - FREE background noise cancellation  
✅ **Open source** - Pipecat is fully open source

#### Cons
❌ Pipecat-specific (less flexible than LiveKit)  
❌ Focused on voice AI (not general WebRTC)  
❌ Newer platform (less proven at scale)

---

### 3. Self-Hosted on Exoscale

#### What You Get
- **Full control** - Own your infrastructure
- **No per-minute costs** - Fixed monthly pricing
- **Data sovereignty** - European hosting
- **Kubernetes** - Full orchestration control

#### Architecture

**Option A: Pure Self-Hosted**
- LiveKit open source (self-hosted)
- TURN/STUN servers (Coturn)
- Backend + databases on Exoscale
- **Cost:** $200-300/month (right-sized cluster)

**Option B: Hybrid (RECOMMENDED)**
- LiveKit Cloud for WebRTC (global edge)
- Backend + databases on Exoscale
- **Cost:** $100-200 (Exoscale) + usage-based (LiveKit)

#### Cost Comparison

**Pure Self-Hosted:**
- Exoscale cluster: $200/month
- CDN (Cloudflare): $20/month
- TURN/STUN servers: Included
- **Total: $220/month (unlimited usage)**

**Break-even point:**
- vs LiveKit Cloud: ~15,700 minutes/month
- vs Pipecat Cloud: ~22,000 minutes/month

#### Pros
✅ **Fixed costs** - No per-minute charges  
✅ **Full control** - Own everything  
✅ **Data sovereignty** - European hosting  
✅ **Unlimited usage** - No usage limits  
✅ **Cheapest at high scale** (>20k min/month)

#### Cons
❌ **Single region** - Geneva only (high latency globally)  
❌ **DevOps overhead** - You manage everything  
❌ **No edge deployment** - Poor WebRTC performance outside Europe  
❌ **Scaling complexity** - Manual capacity planning  
❌ **Higher upfront cost** - Pay even with zero usage

---

## Cost Comparison Summary

| Platform | 1k min/mo | 10k min/mo | 50k min/mo | 100k min/mo | Edge Deployment |
|----------|-----------|------------|------------|-------------|-----------------|
| **LiveKit Cloud** | **FREE** | **$190** | **$750** | **$1,900** | ✅ Global |
| **Pipecat Cloud** | **$10** | **$100** | **$500** | **$1,000** | ✅ Global |
| **Self-Hosted (Exoscale)** | **$220** | **$220** | **$220** | **$220** | ❌ Geneva only |
| **Hybrid (LiveKit + Exoscale)** | **$100** | **$290** | **$850** | **$2,000** | ✅ Global |

---

## Latency Comparison

### WebRTC Round-Trip Time (RTT)

**LiveKit Cloud (Global Edge):**
- North America: 20-40ms ✅
- Europe: 20-50ms ✅
- Asia: 30-80ms ✅
- South America: 40-100ms ✅

**Pipecat Cloud (Daily.co Global):**
- North America: 20-50ms ✅
- Europe: 20-50ms ✅
- Asia: 30-80ms ✅
- South America: 40-100ms ✅

**Self-Hosted Exoscale (Geneva Only):**
- Europe: 20-50ms ✅
- North America East: 100-150ms ⚠️
- North America West: 150-200ms ❌
- Asia: 200-300ms ❌
- South America: 200-300ms ❌

**Impact on User Experience:**
- <100ms: Excellent (feels instant)
- 100-200ms: Noticeable delay
- >200ms: Poor experience, users complain

---

## Feature Comparison

| Feature | LiveKit Cloud | Pipecat Cloud | Self-Hosted |
|---------|---------------|---------------|-------------|
| **Global Edge** | ✅ Yes | ✅ Yes | ❌ No |
| **Open Source** | ✅ Yes | ✅ Yes (Pipecat) | ✅ Yes |
| **AI Agent Hosting** | ✅ Built-in | ✅ Built-in | ❌ DIY |
| **Telephony (SIP/PSTN)** | ✅ Built-in | ✅ Built-in | ❌ DIY |
| **Free Tier** | ✅ 1k min/mo | ❌ No | N/A |
| **Vendor Lock-in** | ⚠️ Low (open source) | ⚠️ Medium | ✅ None |
| **Data Sovereignty** | ❌ US-based | ❌ US-based | ✅ Europe |
| **DevOps Overhead** | ✅ Zero | ✅ Zero | ❌ High |
| **Scaling** | ✅ Automatic | ✅ Automatic | ❌ Manual |
| **Uptime SLA** | ✅ 99.99% | ✅ 99.9% | ⚠️ DIY |

---

## Recommendations by Stage

### Phase 1: MVP (0-1,000 users, <10k min/month)

**Winner: LiveKit Cloud (Build Tier - FREE)**

**Architecture:**
- LiveKit Cloud: WebRTC + AI agents (FREE tier)
- Exoscale: Databases + backend ($100-200/month)
- **Total: $100-200/month**

**Why:**
- FREE for first 1,000 minutes
- Global edge deployment from day 1
- Zero DevOps overhead
- Proven at scale (ChatGPT uses it)
- Can self-host later if needed

---

### Phase 2: Growth (1,000-10,000 users, 10k-50k min/month)

**Winner: Pipecat Cloud**

**Architecture:**
- Pipecat Cloud: WebRTC + AI agents ($100-500/month)
- Exoscale: Databases + backend ($100-200/month)
- **Total: $200-700/month**

**Why:**
- Cheaper than LiveKit at this scale
- FREE WebRTC transport
- Excellent Pipecat framework for voice AI
- Global edge deployment
- Krisp noise removal included

---

### Phase 3: Scale (10,000+ users, 50k-100k min/month)

**Winner: Hybrid (Pipecat Cloud + Exoscale)**

**Architecture:**
- Pipecat Cloud: WebRTC + AI agents ($500-1,000/month)
- Exoscale: Databases + backend ($200-300/month)
- **Total: $700-1,300/month**

**Why:**
- Still cheaper than LiveKit
- Global edge performance
- Mature voice AI infrastructure
- Volume pricing available

---

### Phase 4: Enterprise (100k+ min/month)

**Winner: Self-Hosted + CDN**

**Architecture:**
- LiveKit self-hosted on Exoscale ($300/month)
- Cloudflare for global edge ($50-200/month)
- Databases + backend on Exoscale ($200/month)
- **Total: $550-700/month (unlimited usage)**

**Why:**
- Fixed costs at scale
- Break-even at ~50-100k minutes/month
- Full control and customization
- Data sovereignty
- No vendor lock-in

---

## The Agora Specific Recommendation

### Start with: LiveKit Cloud (FREE) + Exoscale ($100-200)

**Total: $100-200/month for first 1,000 minutes**

**Why this is perfect for you:**

1. **FREE WebRTC edge deployment** - Solve the global latency problem for $0
2. **Proven at scale** - ChatGPT Advanced Voice Mode uses LiveKit
3. **Open source** - Can self-host later when you hit scale
4. **ADHD-friendly** - Zero DevOps overhead, just build features
5. **Cost-effective** - FREE tier covers MVP, scales predictably

**Migration path:**
- **Now:** LiveKit Cloud FREE tier
- **At 10k min/mo:** Switch to Pipecat Cloud ($100/mo vs $190/mo)
- **At 100k min/mo:** Self-host with CDN ($700/mo vs $1,000/mo)

---

## Bottom Line

### Your Original Question: "Does LiveKit/Pipecat offer edge functionality?"

**Answer: YES! Both do, and it changes everything.**

**The Math:**
- **Self-hosted on Exoscale:** $220/month, poor global latency
- **LiveKit Cloud + Exoscale:** $100-200/month (FREE WebRTC for 1k min), excellent global latency
- **Pipecat Cloud + Exoscale:** $110-200/month, excellent global latency

**You were right** - at scale with global users, managed WebRTC platforms ARE worth it. But you don't need to move your entire infrastructure to Fly.io.

**Best approach:**
1. **Keep databases on Exoscale** (cheapest, $100-200/month)
2. **Use LiveKit Cloud for WebRTC** (FREE tier, global edge)
3. **Deploy backend on Exoscale** (already have cluster)
4. **Total: $100-200/month with global edge deployment**

**This beats:**
- Pure self-hosted (better latency)
- Fly.io ($663/month - 3x more expensive)
- Render ($859/month - 4x more expensive)
- Railway ($972/month - 5x more expensive)

**You get the best of both worlds: Exoscale's cost efficiency + LiveKit's global edge!**

---

## Next Steps

1. **Sign up for LiveKit Cloud** (FREE tier)
2. **Right-size Exoscale cluster** (save $680/month)
3. **Deploy The Agora backend** on Exoscale
4. **Integrate LiveKit SDK** for WebRTC
5. **Test global latency** from different regions
6. **Scale when needed** (Pipecat at 10k min/month)

**You'll have a globally distributed, production-ready WebRTC platform for $100-200/month!**

