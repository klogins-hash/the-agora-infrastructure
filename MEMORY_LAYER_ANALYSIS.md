# Memory Layer Architecture Analysis for The Agora

**Date:** October 19, 2025  
**Question:** Should we use Mem0, self-hosted pgvector+Valkey, or another approach for AI agent memory?

---

## The Critical Question

**Your use case:** Multi-agent AI collaboration platform where each customer needs:
- **Short-term memory:** Current conversation context
- **Long-term memory:** User preferences, past interactions, learned behaviors
- **Vector search:** Semantic similarity for RAG (Retrieval Augmented Generation)
- **Graph relationships:** Agent interactions, knowledge graphs (Apache AGE)
- **Low latency:** Real-time voice requires <100ms memory retrieval

**The trade-off:** Managed service (Mem0) vs self-hosted (pgvector + Valkey + Apache AGE)

---

## Option 1: Mem0 (Managed Memory Layer)

### What You Get
- **Universal memory layer** for LLMs
- **Self-improving** - learns from interactions
- **Multi-level memory:**
  - User memory (preferences, facts)
  - Session memory (conversation context)
  - Agent memory (learned behaviors)
- **Managed infrastructure** - zero ops
- **Graph memory** included

### Pricing

**Hobby (FREE):**
- 10,000 memories
- Unlimited end users
- 1,000 retrieval API calls/month
- Community support

**Starter ($19/month):**
- 50,000 memories
- Unlimited end users
- 5,000 retrieval API calls/month
- Community support

**Pro ($249/month):**
- Unlimited memories
- Unlimited end users
- 50,000 retrieval API calls/month
- Private Slack channel
- Graph Memory ✅
- Advanced Analytics
- Multiple projects support

**Enterprise (Custom):**
- Everything in Pro
- On-prem deployment
- SSO
- Audit logs
- Custom integrations
- SLA

**Startup Program:**
- FREE Pro plan for 6 months ($1,500 value)
- For startups under $5M funding

### Latency Performance

From benchmarks:
- **p95 latency:** <1.5 seconds total (including LLM call)
- **Memory retrieval only:** ~100-300ms
- **Uses pgvector under the hood**

### Pros
✅ **Zero DevOps** - Fully managed  
✅ **Self-improving** - Gets smarter over time  
✅ **Multi-level memory** - User, session, agent  
✅ **Graph memory** - Relationship tracking  
✅ **FREE tier** - 10k memories, 1k API calls/month  
✅ **Startup program** - 6 months FREE Pro ($1,500 value)  
✅ **Fast integration** - Python SDK, simple API

### Cons
❌ **Latency:** 100-300ms per retrieval (too slow for real-time voice?)  
❌ **API call limits:** 1k/month (FREE), 5k/month ($19)  
❌ **Vendor lock-in:** Proprietary API  
❌ **Cold start:** Initial load takes time  
❌ **No control:** Can't optimize for your use case  
❌ **Cost at scale:** $249/month for unlimited

---

## Option 2: Self-Hosted (pgvector + Valkey + Apache AGE)

### What You Get
- **Full control** - Optimize for your exact use case
- **No API limits** - Unlimited queries
- **Low latency** - <10ms for vector search
- **Data sovereignty** - Your data stays on your infrastructure
- **Cost predictability** - Fixed monthly cost

### Architecture

**PostgreSQL 18 + pgvector:**
- Vector embeddings for semantic search
- <10ms p95 latency for vector search
- Scales to millions of vectors
- Already deployed ✅

**Valkey (Redis):**
- Session memory (conversation context)
- <1ms p95 latency
- In-memory speed
- Already deployed ✅

**Apache AGE (Graph):**
- Relationship tracking
- Agent interaction graphs
- Knowledge graphs
- Already configured ✅

**Memory Architecture:**
```
┌─────────────────────────────────────┐
│         Memory Layer                │
├─────────────────────────────────────┤
│                                     │
│  Short-term (Valkey)                │
│  - Conversation context             │
│  - Active session state             │
│  - <1ms latency                     │
│                                     │
│  Long-term (PostgreSQL + pgvector)  │
│  - User preferences                 │
│  - Past interactions                │
│  - Vector embeddings                │
│  - <10ms latency                    │
│                                     │
│  Relationships (Apache AGE)         │
│  - Agent interactions               │
│  - Knowledge graphs                 │
│  - <20ms latency                    │
│                                     │
└─────────────────────────────────────┘
```

### Cost

**Already deployed on Exoscale:**
- PostgreSQL: Included in $100-200/month cluster
- Valkey: Included
- Apache AGE: Included
- **Additional cost: $0**

### Latency Performance

From benchmarks:
- **Valkey (short-term):** <1ms p95
- **pgvector (vector search):** <10ms p95
- **Apache AGE (graph queries):** <20ms p95
- **Total memory retrieval:** <30ms (3-10x faster than Mem0)

### Pros
✅ **Ultra-low latency** - <30ms total (vs 100-300ms for Mem0)  
✅ **Already deployed** - $0 additional cost  
✅ **Unlimited queries** - No API limits  
✅ **Full control** - Optimize for your use case  
✅ **Data sovereignty** - Your data, your infrastructure  
✅ **Real-time capable** - Fast enough for voice  
✅ **Proven at scale** - pgvector powers many AI apps

### Cons
❌ **DevOps overhead** - You manage it  
❌ **Not self-improving** - Manual optimization  
❌ **Custom integration** - Build memory layer yourself  
❌ **No graph memory UI** - Have to build it

---

## Option 3: Hybrid Approach

### Architecture

**Hot path (real-time voice):**
- Valkey for session context (<1ms)
- pgvector for recent memories (<10ms)
- **Total: <15ms latency**

**Cold path (background processing):**
- Mem0 for long-term memory consolidation
- Runs after call ends
- Updates user profiles, learns patterns
- **No latency impact**

### How It Works

**During call:**
1. Load session context from Valkey (instant)
2. Retrieve relevant memories from pgvector (<10ms)
3. Agent uses fast local memory for responses
4. **Total latency: <15ms ✅**

**After call:**
1. Send conversation to Mem0 for processing
2. Mem0 extracts insights, updates user profile
3. Mem0 improves memory over time
4. Next call: Pull updated profile from Mem0 at start

### Cost

- **Exoscale (hot path):** $100-200/month (already deployed)
- **Mem0 (cold path):** FREE tier (1k API calls/month)
- **Total: $100-200/month**

### Pros
✅ **Best of both worlds** - Speed + intelligence  
✅ **Low latency** - <15ms for real-time  
✅ **Self-improving** - Mem0 learns over time  
✅ **Cost-effective** - FREE Mem0 tier  
✅ **Scalable** - Hot path handles real-time, cold path handles learning

### Cons
❌ **Complexity** - Two memory systems to manage  
❌ **Sync overhead** - Keep systems in sync  
❌ **API limits** - 1k Mem0 calls/month (FREE tier)

---

## Option 4: File-Based Memory (Your Suggestion)

### How It Works

**At call start:**
1. Load user's memory file from object storage (MinIO)
2. Parse into agent context
3. Agent uses file-based memory during call

**At call end:**
1. Update memory file with new information
2. Save back to MinIO

### Cost

- **MinIO:** Already deployed ($0 additional)
- **Total: $0**

### Latency

- **File load from MinIO:** 50-200ms (network + parsing)
- **File save:** Async, no impact during call
- **Memory access during call:** Instant (in-memory)

### Pros
✅ **Simple** - Just files, no database  
✅ **Cheap** - $0 additional cost  
✅ **Portable** - Easy to migrate  
✅ **Version control** - File history

### Cons
❌ **Slow cold start** - 50-200ms to load file  
❌ **No semantic search** - Can't do vector similarity  
❌ **No graph relationships** - Just flat files  
❌ **Scaling issues** - Large files = slow parsing  
❌ **Concurrency problems** - Multiple agents accessing same file

---

## Latency Comparison

| Approach | Cold Start | Memory Retrieval | Real-time Capable? |
|----------|------------|------------------|-------------------|
| **Mem0 only** | 100-300ms | 100-300ms | ❌ Too slow |
| **Self-hosted (pgvector + Valkey)** | <10ms | <10ms | ✅ Perfect |
| **Hybrid (Valkey + Mem0 background)** | <10ms | <10ms | ✅ Perfect |
| **File-based (MinIO)** | 50-200ms | Instant (after load) | ⚠️ Slow start |

**For real-time voice:** You need <50ms latency. Only self-hosted and hybrid meet this requirement.

---

## Recommendation by Use Case

### For Real-Time Voice (The Agora) ⭐ RECOMMENDED

**Use: Self-Hosted (pgvector + Valkey + Apache AGE)**

**Why:**
1. **Ultra-low latency** - <15ms total (critical for voice)
2. **Already deployed** - $0 additional cost
3. **Unlimited queries** - No API limits
4. **Full control** - Optimize for real-time

**Architecture:**
```
Call starts
    ↓
Load session context from Valkey (<1ms)
    ↓
Retrieve relevant memories from pgvector (<10ms)
    ↓
Agent responds with context (<15ms total)
    ↓
Real-time conversation continues
    ↓
Call ends
    ↓
Update memories in background
```

**Cost:** $0 additional (already deployed)

---

### For Async Processing (Background Jobs)

**Use: Mem0 (FREE tier)**

**Why:**
1. **Self-improving** - Learns from conversations
2. **FREE tier** - 1k API calls/month
3. **No latency requirement** - Runs after call

**Use cases:**
- Post-call analysis
- User profile updates
- Insight extraction
- Pattern learning

**Cost:** FREE (1k calls/month)

---

### Hybrid Architecture (Best of Both Worlds) ⭐⭐ OPTIMAL

**Real-time path:**
- Valkey + pgvector for <15ms latency
- Handles all in-call memory needs

**Background path:**
- Mem0 for post-call learning
- Updates user profiles
- Extracts insights

**Cost:** $100-200/month (Exoscale) + FREE (Mem0)

**This is the optimal architecture for The Agora!**

---

## Specific Recommendations

### For Your Current Setup

**You already have:**
- ✅ PostgreSQL 18 + pgvector (deployed)
- ✅ Valkey (deployed)
- ✅ Apache AGE configured (not tested yet)
- ✅ MinIO for file storage (deployed)

**What to do:**

**Phase 1: Use what you have (NOW)**
1. Use Valkey for session memory (conversation context)
2. Use pgvector for long-term memory (user preferences, past interactions)
3. Use Apache AGE for relationship tracking (agent interactions)
4. **Cost: $0 additional**
5. **Latency: <15ms ✅**

**Phase 2: Add Mem0 for learning (LATER)**
1. After call ends, send conversation to Mem0
2. Mem0 extracts insights, updates user profile
3. Next call: Pull updated profile from Mem0 at start
4. **Cost: FREE (1k calls/month)**
5. **No latency impact** (background processing)

---

## Memory Layer Implementation Guide

### Short-term Memory (Valkey)

**Use for:**
- Current conversation context
- Active session state
- Recent messages (last 10-20)

**Schema:**
```redis
SET session:{user_id}:{session_id}:context "JSON conversation context"
EXPIRE session:{user_id}:{session_id}:context 3600  # 1 hour TTL
```

**Latency:** <1ms

---

### Long-term Memory (PostgreSQL + pgvector)

**Use for:**
- User preferences
- Past interactions (>1 hour old)
- Semantic search over history

**Schema:**
```sql
CREATE TABLE user_memories (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),  -- OpenAI ada-002 dimensions
    created_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX ON user_memories USING ivfflat (embedding vector_cosine_ops);
```

**Query:**
```sql
SELECT content, metadata
FROM user_memories
WHERE user_id = $1
ORDER BY embedding <=> $2  -- Cosine similarity
LIMIT 10;
```

**Latency:** <10ms

---

### Relationship Memory (Apache AGE)

**Use for:**
- Agent interactions
- Knowledge graphs
- Multi-agent collaboration

**Schema:**
```cypher
CREATE (:User {id: 'user123', name: 'John'})
CREATE (:Agent {id: 'agent456', type: 'assistant'})
CREATE (:Memory {id: 'mem789', content: 'Prefers morning calls'})

MATCH (u:User {id: 'user123'}), (m:Memory {id: 'mem789'})
CREATE (u)-[:HAS_PREFERENCE]->(m)
```

**Query:**
```cypher
MATCH (u:User {id: $user_id})-[:HAS_PREFERENCE]->(m:Memory)
RETURN m.content
```

**Latency:** <20ms

---

## Cost Comparison

| Approach | Setup Cost | Monthly Cost | Latency | Scalability |
|----------|------------|--------------|---------|-------------|
| **Mem0 only** | $0 | $0-249 | 100-300ms | ⚠️ API limits |
| **Self-hosted** | $0 (deployed) | $0 | <15ms | ✅ Unlimited |
| **Hybrid** | $0 | $0 (FREE tier) | <15ms | ✅ Best |
| **File-based** | $0 | $0 | 50-200ms | ❌ Poor |

---

## Bottom Line

### For The Agora's Real-Time Voice Requirements:

**DON'T use Mem0 for real-time memory** - 100-300ms is too slow for voice.

**DO use self-hosted (pgvector + Valkey):**
- ✅ <15ms latency (perfect for voice)
- ✅ Already deployed ($0 additional cost)
- ✅ Unlimited queries
- ✅ Full control

**OPTIONALLY add Mem0 for background learning:**
- ✅ Self-improving memory
- ✅ FREE tier (1k calls/month)
- ✅ No latency impact (runs after call)

---

## Implementation Priority

### Phase 1: MVP (NOW)
1. ✅ Use Valkey for session context
2. ✅ Use pgvector for long-term memory
3. ✅ Test Apache AGE for relationships
4. **Latency: <15ms**
5. **Cost: $0 additional**

### Phase 2: Learning (LATER)
1. Add Mem0 for post-call analysis
2. Extract insights from conversations
3. Update user profiles
4. **Cost: FREE (1k calls/month)**

### Phase 3: Scale (FUTURE)
1. Optimize pgvector indexes
2. Add caching layers
3. Consider Mem0 Pro if needed ($249/month)

---

## Answer to Your Question

> "Should I just do like a mem.io and every time someone calls it just pulls their file at the beginning of the call?"

**NO.** Here's why:

1. **Latency:** Loading from Mem0 at call start = 100-300ms delay
2. **Voice UX:** Users expect instant response (<50ms)
3. **Cost:** You already have faster infrastructure deployed
4. **File-based:** Even worse (50-200ms + no semantic search)

**Instead:**
1. **Use Valkey + pgvector for real-time** (<15ms)
2. **Use Mem0 for background learning** (after call)
3. **Best of both worlds:** Speed + intelligence

**You already have the infrastructure deployed. Use it!**

