# VAPI Memory & Knowledge Base Preloading Analysis

**Date:** October 19, 2025  
**Question:** How much customer knowledge can we preload at the beginning of a call?

---

## TL;DR: Multiple Approaches Available

**VAPI offers 3 ways to handle customer-specific knowledge:**

1. **System Messages** (Small context: ~2-5K tokens)
2. **Knowledge Base Query Tool** (Large context: retrieval-based)
3. **Custom Functions** (Dynamic: unlimited via API)

**For your use case (full customer knowledge base):**
- Use **Custom Functions** to preload data dynamically per call
- Supplement with **Knowledge Base** for common information
- Use **System Messages** for customer-specific context

---

## Understanding VAPI's Memory Architecture

### 1. System Messages (Static Context)

**What it is:**
- Instructions and context passed to the LLM at call start
- Part of the assistant configuration
- Included in every LLM request

**Size limits:**
- Depends on the LLM's context window
- GPT-4o: 128K tokens total
- GPT-4o-mini: 128K tokens total
- Gemini 1.5 Pro: 2M tokens total
- Claude 3.5 Sonnet: 200K tokens total

**Practical limits for system messages:**
- **Recommended: 2,000-5,000 tokens** (~1,500-3,750 words)
- **Maximum: 10,000-20,000 tokens** (~7,500-15,000 words)
- Beyond this, response quality degrades

**What to include:**
```json
{
  "model": {
    "provider": "openai",
    "model": "gpt-4o",
    "messages": [
      {
        "role": "system",
        "content": "You are an AI assistant for [Customer Name]. Here is their profile:\n\nPreferences:\n- Communication style: [Direct/Friendly/Formal]\n- Goals: [List of goals]\n- Context: [Recent activity]\n\nUse this information to personalize responses."
      }
    ]
  }
}
```

**Best for:**
- Customer name, preferences, communication style
- Recent activity summary
- Current goals or focus areas
- Small context (< 5K tokens)

---

### 2. Knowledge Base Query Tool (Retrieval-Based)

**What it is:**
- RAG (Retrieval Augmented Generation) system
- Searches uploaded files when needed
- Dynamically retrieves relevant information

**How it works:**
```
User asks question
    ↓
VAPI determines if knowledge base is needed
    ↓
Searches knowledge base files
    ↓
Returns top K relevant chunks
    ↓
LLM uses chunks to answer
```

**Size limits:**
- **Per file: Recommended < 300KB**
- **Total files: Unlimited**
- **Per assistant: Unlimited knowledge bases**
- **Retrieved per query: ~5-10 chunks** (~2,000-4,000 tokens)

**What to include:**
- Product documentation
- Company policies
- FAQ content
- Technical specifications
- Historical information

**Configuration:**
```json
{
  "tools": [
    {
      "type": "query",
      "knowledgeBases": [
        {
          "name": "customer-kb",
          "description": "Contains customer-specific information, preferences, and history",
          "fileIds": ["file-123", "file-456"]
        }
      ]
    }
  ]
}
```

**Limitations:**
- **Not preloaded** - retrieved on-demand
- **Latency: 200-500ms** per query
- **Accuracy depends on** chunk relevance
- **Requires explicit tool calling** by LLM

---

### 3. Custom Functions (Dynamic Preloading)

**What it is:**
- API endpoints you control
- Called by VAPI during the call
- Can fetch any amount of data

**How it works:**
```
Call starts
    ↓
VAPI calls your "preload_customer_data" function
    ↓
Your API queries database
    ↓
Returns customer knowledge base
    ↓
VAPI adds to conversation context
```

**Size limits:**
- **Function response: Recommended < 10K tokens** (~7,500 words)
- **Total context: Limited by LLM context window**
- **Practical limit: 20K-50K tokens** for preloaded data

**Configuration:**
```json
{
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "preload_customer_data",
        "description": "Loads customer profile and knowledge base at call start",
        "parameters": {
          "type": "object",
          "properties": {
            "customer_id": {
              "type": "string",
              "description": "The customer's unique ID"
            }
          }
        }
      },
      "server": {
        "url": "https://your-api.vercel.app/api/preload-customer"
      }
    }
  ],
  "model": {
    "messages": [
      {
        "role": "system",
        "content": "At the start of every call, use the preload_customer_data function to load the customer's full profile and knowledge base. Use this information throughout the conversation."
      }
    ]
  }
}
```

**Your API endpoint:**
```typescript
// /api/preload-customer.ts
export async function POST(req: Request) {
  const { customer_id } = await req.json();
  
  // Query your database
  const customer = await db.query(`
    SELECT 
      profile,
      preferences,
      conversation_history,
      goals,
      context,
      memories
    FROM customers 
    WHERE id = $1
  `, [customer_id]);
  
  // Format for LLM
  const knowledgeBase = `
# Customer Profile: ${customer.name}

## Preferences
${customer.preferences}

## Recent Activity
${customer.conversation_history.slice(0, 10)}

## Goals
${customer.goals}

## Important Context
${customer.context}

## Memories
${customer.memories}
  `;
  
  return Response.json({
    knowledge_base: knowledgeBase,
    tokens: knowledgeBase.split(' ').length * 1.3 // estimate
  });
}
```

**Best for:**
- Customer-specific knowledge bases
- Dynamic data (changes per call)
- Large context (10K-50K tokens)
- Full control over content

---

## Recommended Architecture for The Agora

### Hybrid Approach: System Messages + Custom Functions + Knowledge Base

```
Call starts with customer_id
    ↓
1. System Message (Static, 2K tokens)
   - Assistant personality
   - General instructions
   - Communication guidelines
    ↓
2. Custom Function: preload_customer_data (Dynamic, 10-20K tokens)
   - Customer profile
   - Preferences
   - Recent conversations (last 10)
   - Current goals
   - Active context
   - Key memories
    ↓
3. Knowledge Base (On-demand, 2-4K tokens per query)
   - Deep historical data
   - Detailed documentation
   - Archived conversations
   - Reference materials
    ↓
4. During Call: Custom Functions (As needed)
   - Update memories
   - Fetch specific information
   - Query external APIs
```

---

## How Much Can You Preload?

### Context Window Limits by Model

| Model | Context Window | Practical Preload | Cost per 1M tokens |
|-------|----------------|-------------------|-------------------|
| GPT-4o | 128K tokens | 20-50K tokens | $2.50 (input) |
| GPT-4o-mini | 128K tokens | 20-50K tokens | $0.15 (input) |
| Claude 3.5 Sonnet | 200K tokens | 50-100K tokens | $3.00 (input) |
| Gemini 1.5 Pro | 2M tokens | 100-500K tokens | $1.25 (input) |
| Gemini 1.5 Flash | 1M tokens | 50-200K tokens | $0.075 (input) |

**Recommendation: Use Gemini 1.5 Flash for maximum preload capacity**

---

### Token Estimates

**1 token ≈ 0.75 words ≈ 4 characters**

| Content Type | Tokens | Words | Size |
|--------------|--------|-------|------|
| Customer name + basic info | 50 | 37 | 200 bytes |
| Preferences + communication style | 500 | 375 | 2 KB |
| Recent conversation (10 turns) | 2,000 | 1,500 | 8 KB |
| Goals + context | 1,000 | 750 | 4 KB |
| Key memories (50 items) | 5,000 | 3,750 | 20 KB |
| **Total (minimal)** | **8,550** | **6,412** | **34 KB** |

**Extended preload:**

| Content Type | Tokens | Words | Size |
|--------------|--------|-------|------|
| Full conversation history (100 turns) | 20,000 | 15,000 | 80 KB |
| Detailed preferences + personality | 2,000 | 1,500 | 8 KB |
| All memories (500 items) | 50,000 | 37,500 | 200 KB |
| Goals + long-term context | 5,000 | 3,750 | 20 KB |
| Documents + references | 20,000 | 15,000 | 80 KB |
| **Total (extended)** | **97,000** | **72,750** | **388 KB** |

**With Gemini 1.5 Flash (1M context):**
- You could preload **10x more** (970K tokens)
- That's **727,500 words** or **3.88 MB** of text
- Equivalent to **~15 novels** worth of context

---

## Implementation Strategy

### Phase 1: Minimal Preload (MVP)

**Preload at call start (via custom function):**
```
Customer Profile (8,550 tokens):
├── Name + basic info (50 tokens)
├── Preferences (500 tokens)
├── Recent conversations (2,000 tokens)
├── Current goals (1,000 tokens)
└── Key memories (5,000 tokens)
```

**Cost per call:**
- Input tokens: 8,550 tokens
- GPT-4o-mini: $0.0013 per call
- Gemini Flash: $0.0006 per call

**Latency:**
- Custom function call: 100-300ms
- Acceptable for call start

---

### Phase 2: Extended Preload (Production)

**Preload at call start (via custom function):**
```
Full Customer Knowledge Base (50,000 tokens):
├── Customer profile (2,000 tokens)
├── Recent conversations (20,000 tokens)
├── All active memories (20,000 tokens)
├── Current context + goals (5,000 tokens)
└── Relevant documents (3,000 tokens)
```

**Cost per call:**
- Input tokens: 50,000 tokens
- GPT-4o-mini: $0.0075 per call
- Gemini Flash: $0.0038 per call

**Latency:**
- Custom function call: 200-500ms
- Still acceptable for call start

---

### Phase 3: Maximum Preload (Advanced)

**Use Gemini 1.5 Flash (1M context):**
```
Complete Customer History (200,000 tokens):
├── Full profile + preferences (5,000 tokens)
├── Complete conversation history (100,000 tokens)
├── All memories (50,000 tokens)
├── All documents (30,000 tokens)
├── External context (10,000 tokens)
└── Relationship graph (5,000 tokens)
```

**Cost per call:**
- Input tokens: 200,000 tokens
- Gemini Flash: $0.015 per call
- Still very affordable!

**Latency:**
- Custom function call: 500-1000ms
- May need optimization

---

## Dynamic Per-Call Configuration

### Option 1: Metadata in Call Request

**When starting a call from your frontend:**
```typescript
const call = await vapi.start({
  assistantId: 'your-assistant-id',
  metadata: {
    customer_id: 'cust_123',
    preload_level: 'extended', // minimal, standard, extended, maximum
    include_history: true,
    include_documents: true
  }
});
```

**VAPI passes metadata to your custom function:**
```typescript
// Your API receives
{
  "customer_id": "cust_123",
  "preload_level": "extended",
  "include_history": true,
  "include_documents": true
}
```

---

### Option 2: Dynamic Assistant Creation

**Create assistant per customer:**
```typescript
// When customer logs in
const assistant = await vapi.assistants.create({
  name: `assistant-${customer_id}`,
  model: {
    provider: 'google',
    model: 'gemini-1.5-flash',
    messages: [
      {
        role: 'system',
        content: await generateCustomerContext(customer_id)
      }
    ]
  },
  tools: [
    {
      type: 'function',
      function: {
        name: 'get_memory',
        description: 'Retrieves specific memories or information',
        parameters: {
          type: 'object',
          properties: {
            query: { type: 'string' }
          }
        }
      },
      server: {
        url: `https://your-api.vercel.app/api/memory/${customer_id}`
      }
    }
  ]
});

// Use this assistant for all calls
const call = await vapi.start({
  assistantId: assistant.id
});
```

**Pros:**
- Maximum customization per customer
- Can preload in system message
- No latency at call start

**Cons:**
- Need to manage assistant lifecycle
- Updates require assistant recreation
- More complex

---

### Option 3: Hybrid (Recommended)

**Use shared assistant + dynamic preload:**

1. **Shared assistant** with general configuration
2. **Custom function** called at call start with `customer_id`
3. **Metadata** to control preload level

**Best of both worlds:**
- ✅ Simple assistant management
- ✅ Dynamic per-customer data
- ✅ Flexible preload levels
- ✅ Easy to update

---

## Latency Considerations

### Preload Timing

**Option A: Sequential (Simple)**
```
Call starts
    ↓ (0ms)
Custom function: preload_customer_data
    ↓ (500ms)
Assistant starts speaking
    ↓ (200ms)
Total: 700ms to first word
```

**Option B: Parallel (Optimized)**
```
Call starts
    ↓ (0ms)
Parallel:
  ├─ Custom function: preload_customer_data (500ms)
  └─ Assistant generates first message (200ms)
    ↓
Assistant speaks with preloaded context
    ↓
Total: 500ms to first word
```

**Option C: Cached (Fastest)**
```
Call starts
    ↓ (0ms)
Check cache (Cloudflare KV)
    ↓ (10ms, cache hit)
Assistant starts speaking
    ↓ (200ms)
Total: 210ms to first word
```

**Implementation:**
```typescript
// Cache customer data in Cloudflare KV
export async function POST(req: Request, env: Env) {
  const { customer_id } = await req.json();
  
  // Check cache (10ms)
  let customerData = await env.CUSTOMER_CACHE.get(customer_id);
  
  if (!customerData) {
    // Cache miss - query database (500ms)
    customerData = await fetchCustomerData(customer_id);
    
    // Cache for 1 hour
    await env.CUSTOMER_CACHE.put(
      customer_id,
      customerData,
      { expirationTtl: 3600 }
    );
  }
  
  return Response.json({ knowledge_base: customerData });
}
```

---

## Cost Analysis

### Per-Call Cost Breakdown

**Minimal Preload (8,550 tokens):**

| Model | Input Cost | Output Cost (avg 1K tokens) | Total per Call |
|-------|------------|----------------------------|----------------|
| GPT-4o-mini | $0.0013 | $0.0006 | $0.0019 |
| Gemini Flash | $0.0006 | $0.0003 | $0.0009 |

**Extended Preload (50,000 tokens):**

| Model | Input Cost | Output Cost (avg 1K tokens) | Total per Call |
|-------|------------|----------------------------|----------------|
| GPT-4o-mini | $0.0075 | $0.0006 | $0.0081 |
| Gemini Flash | $0.0038 | $0.0003 | $0.0041 |

**Maximum Preload (200,000 tokens):**

| Model | Input Cost | Output Cost (avg 1K tokens) | Total per Call |
|-------|------------|----------------------------|----------------|
| GPT-4o-mini | $0.0300 | $0.0006 | $0.0306 |
| Gemini Flash | $0.0150 | $0.0003 | $0.0153 |

**At 10,000 calls/month:**

| Preload Level | GPT-4o-mini | Gemini Flash | Savings |
|---------------|-------------|--------------|---------|
| Minimal | $19 | $9 | $10 |
| Extended | $81 | $41 | $40 |
| Maximum | $306 | $153 | $153 |

**Recommendation: Use Gemini Flash for cost efficiency**

---

## Best Practices

### 1. Optimize Preload Size

**Include:**
- ✅ Recent activity (last 10-20 conversations)
- ✅ Active goals and context
- ✅ Key memories (most relevant)
- ✅ Current preferences

**Exclude:**
- ❌ Full conversation history (use knowledge base)
- ❌ Archived data (use on-demand retrieval)
- ❌ Redundant information
- ❌ Low-relevance memories

---

### 2. Use Tiered Preloading

**Tier 1: Always Preload (2-5K tokens)**
- Customer name + basic info
- Communication preferences
- Current session context

**Tier 2: Standard Preload (10-20K tokens)**
- Recent conversations (last 10)
- Active goals
- Key memories

**Tier 3: Extended Preload (50-100K tokens)**
- Recent conversations (last 50)
- All active memories
- Relevant documents

**Tier 4: Maximum Preload (200K+ tokens)**
- Full conversation history
- All memories
- All documents
- External context

**Choose tier based on:**
- Customer subscription level
- Call importance
- Available budget
- Latency requirements

---

### 3. Cache Aggressively

**Cache customer data in:**
- Cloudflare Workers KV (global edge)
- Redis (Valkey) on your backend
- VAPI session state (during call)

**Cache invalidation:**
- After each call (update with new data)
- On customer profile update
- TTL: 1 hour (balance freshness vs cost)

---

### 4. Compress Context

**Techniques:**
- Summarize old conversations
- Extract key points from memories
- Use embeddings for semantic search
- Remove redundant information

**Example:**
```typescript
// Instead of full conversation
const fullConversation = `
User: How do I reset my password?
Assistant: You can reset your password by...
User: Thanks, that worked!
Assistant: Great! Is there anything else?
...
`;

// Use summary
const summary = `
Previous topics:
- Password reset (resolved)
- Account settings (discussed)
- Billing question (pending)
`;
```

---

### 5. Monitor Token Usage

**Track:**
- Tokens preloaded per call
- Tokens used during call
- Total cost per call
- Cache hit rate

**Optimize:**
- Reduce preload for low-engagement calls
- Increase preload for high-value customers
- A/B test different preload levels

---

## Example Implementation

### Complete Flow

**1. Frontend (React):**
```typescript
import { useVapi } from '@vapi-ai/react';

function VoiceWidget({ customerId }) {
  const { start, stop } = useVapi({
    apiKey: process.env.NEXT_PUBLIC_VAPI_KEY,
    assistant: {
      id: 'your-assistant-id',
      metadata: {
        customer_id: customerId,
        preload_level: 'extended'
      }
    }
  });
  
  return (
    <button onClick={start}>
      Start Call
    </button>
  );
}
```

---

**2. VAPI Assistant Configuration:**
```json
{
  "name": "The Agora Assistant",
  "model": {
    "provider": "google",
    "model": "gemini-1.5-flash",
    "messages": [
      {
        "role": "system",
        "content": "You are an AI assistant. At the start of every call, you will receive the customer's full profile and knowledge base. Use this information to provide personalized, context-aware responses."
      }
    ]
  },
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "preload_customer_data",
        "description": "Loads customer profile and knowledge base at call start. Call this immediately when the call begins.",
        "parameters": {
          "type": "object",
          "properties": {
            "customer_id": {
              "type": "string"
            },
            "preload_level": {
              "type": "string",
              "enum": ["minimal", "standard", "extended", "maximum"]
            }
          },
          "required": ["customer_id"]
        }
      },
      "server": {
        "url": "https://your-app.vercel.app/api/preload-customer"
      }
    },
    {
      "type": "function",
      "function": {
        "name": "update_memory",
        "description": "Updates customer memory with new information learned during the call",
        "parameters": {
          "type": "object",
          "properties": {
            "memory_type": {
              "type": "string",
              "enum": ["preference", "goal", "context", "fact"]
            },
            "content": {
              "type": "string"
            }
          }
        }
      },
      "server": {
        "url": "https://your-app.vercel.app/api/update-memory"
      }
    }
  ],
  "hooks": [
    {
      "type": "call-started",
      "url": "https://your-app.vercel.app/api/call-started"
    }
  ]
}
```

---

**3. Vercel API - Preload Endpoint:**
```typescript
// /api/preload-customer.ts
import { NextRequest, NextResponse } from 'next/server';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

export async function POST(req: NextRequest) {
  const { customer_id, preload_level = 'standard' } = await req.json();
  
  // Query database based on preload level
  const customer = await pool.query(`
    SELECT 
      c.name,
      c.preferences,
      c.goals,
      c.context,
      CASE 
        WHEN $2 = 'minimal' THEN (
          SELECT json_agg(conv) FROM (
            SELECT * FROM conversations 
            WHERE customer_id = $1 
            ORDER BY created_at DESC 
            LIMIT 5
          ) conv
        )
        WHEN $2 = 'standard' THEN (
          SELECT json_agg(conv) FROM (
            SELECT * FROM conversations 
            WHERE customer_id = $1 
            ORDER BY created_at DESC 
            LIMIT 10
          ) conv
        )
        WHEN $2 = 'extended' THEN (
          SELECT json_agg(conv) FROM (
            SELECT * FROM conversations 
            WHERE customer_id = $1 
            ORDER BY created_at DESC 
            LIMIT 50
          ) conv
        )
        ELSE (
          SELECT json_agg(conv) FROM conversations 
          WHERE customer_id = $1
        )
      END as conversations,
      (
        SELECT json_agg(mem) FROM (
          SELECT * FROM memories 
          WHERE customer_id = $1 
          AND importance > 0.5
          ORDER BY importance DESC, created_at DESC
          LIMIT CASE 
            WHEN $2 = 'minimal' THEN 20
            WHEN $2 = 'standard' THEN 50
            WHEN $2 = 'extended' THEN 200
            ELSE 1000
          END
        ) mem
      ) as memories
    FROM customers c
    WHERE c.id = $1
  `, [customer_id, preload_level]);
  
  if (!customer.rows[0]) {
    return NextResponse.json(
      { error: 'Customer not found' },
      { status: 404 }
    );
  }
  
  const data = customer.rows[0];
  
  // Format for LLM
  const knowledgeBase = `
# Customer Profile: ${data.name}

## Communication Preferences
${data.preferences}

## Current Goals
${data.goals}

## Active Context
${data.context}

## Recent Conversations
${data.conversations?.map((conv, i) => `
### Conversation ${i + 1} (${conv.date})
${conv.summary}
Key points: ${conv.key_points}
`).join('\n')}

## Important Memories
${data.memories?.map((mem, i) => `
${i + 1}. ${mem.content} (importance: ${mem.importance})
`).join('\n')}
  `.trim();
  
  // Estimate tokens
  const tokens = Math.ceil(knowledgeBase.split(' ').length * 1.3);
  
  console.log(`Preloaded ${tokens} tokens for customer ${customer_id} (level: ${preload_level})`);
  
  return NextResponse.json({
    knowledge_base: knowledgeBase,
    tokens,
    preload_level
  });
}
```

---

**4. Vercel API - Call Started Hook:**
```typescript
// /api/call-started.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  const { call, metadata } = await req.json();
  
  const customer_id = metadata?.customer_id;
  const preload_level = metadata?.preload_level || 'standard';
  
  console.log(`Call started for customer ${customer_id}`);
  
  // Trigger preload function immediately
  // (VAPI will call preload_customer_data function automatically
  // based on system prompt instructions)
  
  return NextResponse.json({ success: true });
}
```

---

**5. Vercel API - Update Memory:**
```typescript
// /api/update-memory.ts
import { NextRequest, NextResponse } from 'next/server';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

export async function POST(req: NextRequest) {
  const { customer_id, memory_type, content } = await req.json();
  
  // Calculate importance (simple heuristic)
  const importance = calculateImportance(content, memory_type);
  
  // Store in database
  await pool.query(`
    INSERT INTO memories (customer_id, type, content, importance, created_at)
    VALUES ($1, $2, $3, $4, NOW())
  `, [customer_id, memory_type, content, importance]);
  
  // Invalidate cache
  await fetch(`https://your-worker.workers.dev/invalidate/${customer_id}`);
  
  return NextResponse.json({ success: true });
}

function calculateImportance(content: string, type: string): number {
  // Simple heuristic - you can use ML model for better results
  let score = 0.5;
  
  if (type === 'goal') score += 0.3;
  if (type === 'preference') score += 0.2;
  if (content.length > 100) score += 0.1;
  
  return Math.min(score, 1.0);
}
```

---

## Bottom Line

### For The Agora: Use Custom Functions + Gemini Flash

**Recommended approach:**

1. **Preload via custom function** (at call start)
   - Customer profile + preferences (2K tokens)
   - Recent conversations (20K tokens)
   - Active memories (20K tokens)
   - Current context (5K tokens)
   - **Total: 47K tokens**

2. **Use Gemini 1.5 Flash**
   - 1M token context window
   - $0.075 per 1M input tokens
   - **Cost: $0.0035 per call**

3. **Cache in Cloudflare KV**
   - 10ms latency (vs 500ms database)
   - 1 hour TTL
   - **$15/month for unlimited reads**

4. **Knowledge Base for deep history**
   - On-demand retrieval
   - 200-500ms latency (acceptable)
   - Unlimited storage

---

### Cost Comparison (10,000 calls/month)

| Approach | Tokens | Model | Cost per Call | Monthly Cost |
|----------|--------|-------|---------------|--------------|
| **Minimal (System Message)** | 2K | GPT-4o-mini | $0.0003 | $3 |
| **Standard (Custom Function)** | 10K | GPT-4o-mini | $0.0015 | $15 |
| **Extended (Custom Function)** | 50K | Gemini Flash | $0.0038 | $38 |
| **Maximum (Custom Function)** | 200K | Gemini Flash | $0.0150 | $150 |

**Recommendation: Extended preload with Gemini Flash**
- **$38/month** for 10K calls
- **47K tokens** of customer context
- **<500ms** preload latency
- **Unlimited** knowledge base storage

---

## Next Steps

Want me to:
1. **Implement the preload system** (custom function + API)
2. **Set up caching** (Cloudflare Workers KV)
3. **Configure VAPI assistant** with preload
4. **Test with sample customer data**
5. **All of the above**

**This gives you the full customer knowledge base at call start!** 🚀

