# Global Latency Problem & Solutions for The Agora

**Date:** October 19, 2025  
**Critical Issue:** Database in Geneva, users worldwide = high latency

---

## The Problem You Just Identified

### Scenario: User in San Francisco

**Network path:**
```
User in SF
    ↓
LiveKit Edge (SF) - 20ms ✅
    ↓
Agent on Exoscale (Geneva) - need to query database
    ↓
Database query to Geneva from Geneva - <10ms ✅
    ↓
BUT WAIT...
```

**Actually, where does the agent run?**

### Option A: Agent runs on LiveKit Cloud (distributed globally)
```
User in SF
    ↓
LiveKit Edge SF (20ms) ✅
    ↓
Agent on LiveKit SF
    ↓
Query database in Geneva (150ms) ❌ PROBLEM!
    ↓
Total: 170ms (too slow)
```

### Option B: Agent runs on Exoscale (Geneva only)
```
User in SF
    ↓
LiveKit Edge SF (20ms) ✅
    ↓
Media routed to Agent in Geneva (150ms) ❌ PROBLEM!
    ↓
Query database in Geneva (<10ms) ✅
    ↓
Total: 170ms (too slow)
```

**Either way, you have a 150ms cross-continental hop!**

---

## The Real Architecture Question

### Where Should Things Run?

**The components:**
1. **User** - Anywhere in the world
2. **WebRTC Media** - Needs global edge (LiveKit Cloud)
3. **AI Agent** - Where should this run?
4. **Database** - Where should this be?

**The latency requirements:**
- **Media (voice):** <50ms (handled by LiveKit edge ✅)
- **Agent response:** <100ms total
- **Database query:** Must be <50ms from agent

---

## Solution 1: Replicate Database Globally (Read Replicas)

### Architecture

**Primary database:** Geneva (Exoscale)
**Read replicas:** 
- US East (AWS/Fly.io)
- US West (AWS/Fly.io)
- Asia (AWS/Fly.io)

**How it works:**
```
User in SF
    ↓
LiveKit Edge SF (20ms)
    ↓
Agent on LiveKit SF
    ↓
Query read replica in SF (<10ms) ✅
    ↓
Total: 30ms ✅
```

**Writes (after call):**
```
Call ends
    ↓
Write to primary in Geneva (async, no latency impact)
    ↓
Replicate to read replicas (1-5 seconds)
```

### Cost

**Exoscale primary:** $100-200/month (already deployed)

**Read replicas (Fly.io):**
- 3 regions × PostgreSQL (1 CPU, 2GB RAM, 50GB) = 3 × $50 = $150/month
- Replication bandwidth: ~$20/month
- **Total: $170/month**

**Grand total:** $270-370/month

### Pros
✅ **Low latency globally** - <30ms database queries  
✅ **Eventually consistent** - Good enough for user memory  
✅ **Exoscale as source of truth** - Primary in Geneva  
✅ **Relatively cheap** - $170/month for global coverage

### Cons
❌ **Replication lag** - 1-5 seconds (but acceptable for memory)  
❌ **Complexity** - Manage replication  
❌ **Write conflicts** - Need conflict resolution

---

## Solution 2: Cache-First Architecture (Recommended)

### Architecture

**Global edge cache (Cloudflare KV or Upstash Redis):**
- Distributed globally
- <10ms latency worldwide
- Automatic replication

**How it works:**
```
Call starts
    ↓
Agent loads user profile from edge cache (10ms) ✅
    ↓
Conversation happens with cached context
    ↓
Call ends
    ↓
Update cache + database (async)
```

**Cache hierarchy:**
```
Level 1: In-memory (agent process)
    ↓ miss
Level 2: Edge cache (Cloudflare KV / Upstash)
    ↓ miss
Level 3: Database (Exoscale)
```

### Cost

**Cloudflare Workers KV:**
- 10GB storage: $5/month
- 10M reads: $5/month
- 1M writes: $5/month
- **Total: $15/month**

**Upstash Redis (alternative):**
- Global database
- 10k requests/day: FREE
- 1M requests/month: $20/month

**Grand total:** $115-220/month (Exoscale + edge cache)

### Pros
✅ **Ultra-low latency** - <10ms globally  
✅ **Cheap** - $15-20/month  
✅ **Simple** - Just add caching layer  
✅ **No replication lag** - Cache is source of truth for hot data  
✅ **Scales automatically** - Cloudflare/Upstash handles it

### Cons
❌ **Cache invalidation** - Classic hard problem  
❌ **Stale data** - Need TTL strategy  
❌ **Cold cache** - First query still slow

---

## Solution 3: Deploy Everything on Fly.io (Global Database)

### Architecture

**Fly.io Postgres:**
- Multi-region deployment
- Automatic read replicas
- Global routing

**How it works:**
```
User in SF
    ↓
LiveKit Edge SF (20ms)
    ↓
Agent on LiveKit SF
    ↓
Query Fly.io Postgres SF replica (<10ms) ✅
    ↓
Total: 30ms ✅
```

### Cost

**Fly.io Postgres (multi-region):**
- Primary (4 CPU, 8GB RAM, 50GB): $115/month
- 2 read replicas (2 CPU, 4GB RAM): 2 × $60 = $120/month
- **Total: $235/month**

**Fly.io Valkey:**
- 2 CPU, 4GB RAM: $60/month

**Fly.io MinIO:**
- 4 CPU, 8GB RAM, 1TB: $215/month

**Grand total:** $510/month (vs $100-200 on Exoscale)

### Pros
✅ **Low latency globally** - <30ms  
✅ **Fully managed** - Fly.io handles replication  
✅ **Simple** - One platform  
✅ **Global edge** - Built-in

### Cons
❌ **Expensive** - 2.5-5x more than Exoscale  
❌ **Vendor lock-in** - Fly.io specific  
❌ **Still need LiveKit** - Fly.io doesn't do WebRTC edge

---

## Solution 4: Pipecat Cloud (Agents Run on Edge)

### Architecture

**Pipecat Cloud:**
- Agents run on global edge
- Database queries from edge to Geneva

**BUT WAIT - same problem!**
```
User in SF
    ↓
Pipecat Edge SF (20ms) ✅
    ↓
Agent on Pipecat SF
    ↓
Query database in Geneva (150ms) ❌ PROBLEM!
```

**Unless you also use edge cache:**
```
User in SF
    ↓
Pipecat Edge SF (20ms) ✅
    ↓
Agent on Pipecat SF
    ↓
Query Cloudflare KV (10ms) ✅
    ↓
Total: 30ms ✅
```

### Cost

**Pipecat Cloud:** $100-500/month (usage-based)  
**Exoscale database:** $100-200/month  
**Cloudflare KV:** $15/month  
**Total:** $215-715/month

### Pros
✅ **Agents on edge** - Close to users  
✅ **Low latency with cache** - <30ms  
✅ **Managed agents** - Zero ops

### Cons
❌ **Still need edge cache** - Database in Geneva  
❌ **More expensive** - $215-715/month  
❌ **Complexity** - Multiple platforms

---

## Solution 5: Hybrid - LiveKit + Edge Cache + Exoscale (Optimal)

### Architecture

```
┌─────────────────────────────────────────────────┐
│                  Global Users                    │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│         LiveKit Cloud (WebRTC Edge)              │
│  - SF, NYC, London, Tokyo, etc.                  │
│  - <20ms latency to users                        │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│         Agents (on LiveKit Cloud)                │
│  - Run on same edge as WebRTC                    │
│  - <5ms to WebRTC media                          │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│    Cloudflare Workers KV (Edge Cache)            │
│  - User profiles, recent memories                │
│  - <10ms latency globally                        │
│  - TTL: 1 hour                                   │
└─────────────────────────────────────────────────┘
                        ↓ (cache miss)
┌─────────────────────────────────────────────────┐
│         Exoscale (Geneva)                        │
│  - PostgreSQL + pgvector (source of truth)       │
│  - Valkey (session state)                        │
│  - MinIO (file storage)                          │
│  - 150ms from SF, but rarely accessed            │
└─────────────────────────────────────────────────┘
```

### How It Works

**Call start (hot cache):**
```
1. User in SF connects to LiveKit SF edge (20ms)
2. Agent on LiveKit SF starts
3. Agent queries Cloudflare KV for user profile (10ms)
4. Cache hit! ✅
5. Total: 30ms
```

**Call start (cold cache):**
```
1. User in SF connects to LiveKit SF edge (20ms)
2. Agent on LiveKit SF starts
3. Agent queries Cloudflare KV for user profile (10ms)
4. Cache miss!
5. Query Exoscale database in Geneva (150ms)
6. Store in Cloudflare KV for next time
7. Total: 180ms (first call only)
```

**During call:**
```
1. All queries hit edge cache (10ms)
2. Real-time conversation (<30ms latency)
```

**Call end:**
```
1. Update Cloudflare KV (async)
2. Update Exoscale database (async)
3. No latency impact
```

### Cost

**LiveKit Cloud:** $0-190/month (FREE tier + usage)  
**Cloudflare Workers KV:** $15/month  
**Exoscale:** $100-200/month  
**Total:** $115-405/month

### Latency

**Hot cache (99% of calls):** <30ms ✅  
**Cold cache (1% of calls):** ~180ms (acceptable for first call)

### Pros
✅ **Low latency globally** - <30ms for 99% of queries  
✅ **Cost-effective** - $115-405/month  
✅ **Simple** - Just add Cloudflare KV  
✅ **Exoscale as source of truth** - Keep your infrastructure  
✅ **Scalable** - Cloudflare handles global distribution

### Cons
❌ **Cache invalidation** - Need strategy  
❌ **First call slow** - 180ms (but only once per user per hour)

---

## Comparison Matrix

| Solution | Global Latency | Monthly Cost | Complexity | Recommended? |
|----------|----------------|--------------|------------|--------------|
| **Hybrid (LiveKit + Edge Cache + Exoscale)** | **<30ms** | **$115-405** | **Low** | **✅ YES** |
| Cache-First (Cloudflare KV + Exoscale) | <30ms | $115-220 | Low | ✅ Yes |
| Read Replicas (Fly.io + Exoscale) | <30ms | $270-370 | Medium | ⚠️ Maybe |
| Full Fly.io | <30ms | $510 | Low | ❌ Expensive |
| Pipecat Cloud + Cache | <30ms | $215-715 | Medium | ⚠️ Maybe |
| Self-hosted only (Geneva) | 150ms+ | $100-200 | Low | ❌ Too slow |

---

## Recommended Architecture

### Phase 1: MVP (NOW)

**Stack:**
- **LiveKit Cloud:** WebRTC edge + agent hosting (FREE tier)
- **Cloudflare Workers KV:** Edge cache for user profiles ($15/month)
- **Exoscale:** Database source of truth ($100-200/month)

**Total:** $115-215/month

**Latency:**
- Hot cache (99%): <30ms ✅
- Cold cache (1%): ~180ms (acceptable)

**Why this works:**
1. LiveKit agents run on global edge (close to users)
2. User profiles cached on Cloudflare edge (close to agents)
3. Database in Geneva only accessed on cache miss
4. 99% of queries hit cache (<30ms)

---

### Phase 2: Optimize (LATER)

**Add read replicas if needed:**
- If cache miss rate is high (>5%)
- If 180ms cold start is unacceptable
- Cost: +$170/month

**Or migrate to Fly.io:**
- If Exoscale becomes limiting
- If you want one platform
- Cost: +$310/month

---

## Cache Strategy

### What to Cache (Cloudflare KV)

**User profile:**
- Name, preferences
- Recent conversation summaries
- Key facts about user
- TTL: 1 hour

**Recent memories:**
- Last 10 interactions
- Frequently accessed memories
- TTL: 1 hour

### What NOT to Cache

**Full conversation history:**
- Too large
- Query from database on demand

**Real-time session state:**
- Use Valkey on Exoscale
- Or LiveKit's built-in state

### Cache Invalidation

**On user update:**
```javascript
// After call ends
await kv.put(`user:${userId}:profile`, updatedProfile, {
  expirationTtl: 3600  // 1 hour
});

// Also update Exoscale database
await db.query('UPDATE users SET ... WHERE id = $1', [userId]);
```

**On cache miss:**
```javascript
// Try cache first
let profile = await kv.get(`user:${userId}:profile`);

if (!profile) {
  // Cache miss - query database
  profile = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  
  // Store in cache for next time
  await kv.put(`user:${userId}:profile`, profile, {
    expirationTtl: 3600
  });
}
```

---

## Implementation Steps

### Step 1: Set up Cloudflare Workers KV

```bash
# Install Wrangler CLI
npm install -g wrangler

# Create KV namespace
wrangler kv:namespace create "USER_PROFILES"

# Deploy worker
wrangler publish
```

### Step 2: Integrate with LiveKit Agents

```python
# In your LiveKit agent code
import requests

def get_user_profile(user_id):
    # Try edge cache first
    response = requests.get(
        f"https://your-worker.workers.dev/profile/{user_id}"
    )
    
    if response.status_code == 200:
        return response.json()  # Cache hit
    
    # Cache miss - query database
    profile = query_database(user_id)
    
    # Store in cache
    requests.put(
        f"https://your-worker.workers.dev/profile/{user_id}",
        json=profile
    )
    
    return profile
```

### Step 3: Deploy

1. Deploy Cloudflare Worker
2. Update LiveKit agent code
3. Test from different regions
4. Monitor cache hit rate

---

## Bottom Line

### The Problem You Identified is Real

**Database in Geneva + Users worldwide = 150ms+ latency ❌**

### The Solution

**Edge cache (Cloudflare KV) between agents and database:**
- 99% of queries hit cache (<30ms) ✅
- 1% cache miss queries database (~180ms, acceptable)
- Cost: +$15/month
- **Total: $115-215/month with global <30ms latency**

### Don't Migrate to Fly.io

**Fly.io would cost $510/month** (2.5x more) and you'd still need:
- LiveKit for WebRTC edge
- Edge cache for low latency

**Better:** Keep Exoscale + add edge cache = $115-215/month

---

## Next Steps

Want me to:
1. **Set up Cloudflare Workers KV** for edge caching
2. **Show you the integration code** for LiveKit agents
3. **Deploy the hybrid architecture**
4. **All of the above**

**This solves your global latency problem for $15/month!** 🚀

