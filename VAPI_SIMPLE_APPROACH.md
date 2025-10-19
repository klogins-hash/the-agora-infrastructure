# VAPI Simple Approach Analysis for The Agora MVP

**Date:** October 19, 2025  
**Question:** Should we just use VAPI + Railway/Exoscale + Vercel for simplicity?

---

## TL;DR: YES! This is the simplest path to MVP

**VAPI + Vercel + Railway/Exoscale is the fastest way to launch.**

**Cost:** $150-350/month  
**Time to deploy:** 1-2 days  
**Complexity:** Low (mostly no-code)  
**Global edge:** ✅ Yes (VAPI + Vercel)  
**Database latency:** ✅ Solved (VAPI handles it)

---

## What is VAPI?

**VAPI = Voice AI Platform Infrastructure**

### What VAPI Provides:

1. **Voice AI Agents (Fully Managed)**
   - WebRTC infrastructure (global edge)
   - Speech-to-Text (STT)
   - Large Language Models (LLM)
   - Text-to-Speech (TTS)
   - Custom function calling
   - Multi-turn conversations

2. **Global Infrastructure**
   - Runs primarily in **US West** region
   - Global WebRTC edge network
   - Low latency worldwide (<50ms)
   - 99.99% SLA

3. **Channels**
   - Voice calls (web, phone)
   - SMS/Chat
   - Custom SIP

4. **Developer Experience**
   - No-code Flow Studio
   - React/TypeScript SDK
   - Python SDK
   - Custom function support
   - Webhooks for external APIs

---

## VAPI Pricing Breakdown

### Base Cost: $0.05/minute

**What's included:**
- VAPI hosting (infrastructure)
- WebRTC transport
- Call orchestration
- Custom function execution

**What's NOT included (at cost):**
- STT (Speech-to-Text): ~$0.006/min (Deepgram)
- LLM (Language Model): ~$0.02/min (GPT-4o)
- TTS (Text-to-Speech): ~$0.015/min (ElevenLabs)

**Total per minute: ~$0.091/min**

---

### Cost Estimates

**10,000 minutes/month:**
- VAPI hosting: $500
- STT: $60
- LLM: $200
- TTS: $150
- **Total: $910/month**

**BUT: You can use your own API keys!**

**With your own keys:**
- VAPI hosting: $500
- STT (your Deepgram key): $60
- LLM (your OpenAI key): $200
- TTS (your ElevenLabs key): $150
- **Total: $910/month**

**Wait, same price?**

**YES, but with benefits:**
- ✅ You control API keys
- ✅ You get volume discounts directly
- ✅ You can switch providers
- ✅ Better cost transparency

---

### Additional Costs

**Concurrency:**
- 10 concurrent calls included FREE
- $10/line/month for additional

**Data Retention:**
- 14 days call history (FREE)
- 30 days chat history (FREE)
- Custom retention: Enterprise only

**HIPAA:**
- $1,000/month add-on
- Zero data retention mode

---

## The VAPI Simple Architecture

### Option 1: VAPI + Vercel + Railway

```
Global Users
    ↓
VAPI (Voice AI)
  - WebRTC (global edge)
  - STT, LLM, TTS
  - Custom functions
  - $0.05/min + models at cost
    ↓
Vercel (Frontend + API)
  - React widget (global edge)
  - API routes for custom functions
  - $20/month (Pro plan)
    ↓
Railway (Database)
  - PostgreSQL + pgvector
  - Valkey (Redis)
  - $50-150/month
```

**Total Cost: $590-1,080/month (10k min)**

**Latency:**
- Voice: <50ms globally (VAPI edge)
- Database: <100ms (Railway US)
- Frontend: <20ms (Vercel edge)

---

### Option 2: VAPI + Vercel + Exoscale (Right-sized)

```
Global Users
    ↓
VAPI (Voice AI)
  - WebRTC (global edge)
  - STT, LLM, TTS
  - Custom functions
  - $0.05/min + models at cost
    ↓
Vercel (Frontend + API)
  - React widget (global edge)
  - API routes for custom functions
  - $20/month (Pro plan)
    ↓
Exoscale (Database)
  - PostgreSQL + pgvector
  - Valkey
  - MinIO
  - $100-200/month (right-sized)
```

**Total Cost: $620-1,130/month (10k min)**

**Latency:**
- Voice: <50ms globally (VAPI edge)
- Database: <150ms (Exoscale Geneva)
- Frontend: <20ms (Vercel edge)

**BUT: Database latency might be acceptable!**

---

## Why VAPI Solves Your Problems

### 1. Global Edge (Built-in)

**VAPI handles:**
- ✅ WebRTC edge deployment
- ✅ Global TURN/STUN servers
- ✅ Low latency worldwide
- ✅ No infrastructure management

**You don't need:**
- ❌ LiveKit Cloud
- ❌ Pipecat Cloud
- ❌ Daily.co
- ❌ Fly.io multi-region

---

### 2. Database Latency (Less Critical)

**Why database latency matters less with VAPI:**

**VAPI caches session state:**
- Agent context kept in memory
- Only queries database when needed
- Async database updates

**Typical flow:**
```
User speaks
    ↓
VAPI processes (STT + LLM + TTS)
  - Uses cached session state
  - 50-100ms total
    ↓
Agent responds
    ↓
Background: Update database (150ms)
  - User doesn't wait for this
```

**Database queries only needed for:**
- Initial session load (once per call)
- Specific memory retrieval (occasional)
- Post-call updates (async)

**Result:** 150ms database latency is acceptable!

---

### 3. Simplicity (Huge Win)

**With VAPI:**
- ✅ No Kubernetes management
- ✅ No agent deployment
- ✅ No WebRTC configuration
- ✅ No multi-region setup
- ✅ No scaling concerns

**You just:**
1. Configure agent in VAPI dashboard
2. Deploy frontend widget on Vercel
3. Connect to your database
4. **Done!**

**Time to MVP: 1-2 days** (vs weeks with self-hosted)

---

## VAPI vs Self-Hosted Comparison

| Feature | VAPI | LiveKit + Exoscale | Pipecat + Exoscale |
|---------|------|-------------------|-------------------|
| **Cost (10k min)** | $620-1,130 | $115-405 | $215-715 |
| **Setup Time** | 1-2 days | 1-2 weeks | 1-2 weeks |
| **Complexity** | Low (no-code) | High (K8s) | Medium (managed) |
| **Global Edge** | ✅ Built-in | ✅ (LiveKit) | ✅ (Daily.co) |
| **Database Latency** | ✅ Acceptable | ⚠️ Need cache | ⚠️ Need cache |
| **Maintenance** | ✅ Zero | ❌ High | ⚠️ Medium |
| **Vendor Lock-in** | ⚠️ Yes | ✅ No (open source) | ⚠️ Yes |
| **Custom Functions** | ✅ Yes | ✅ Yes | ✅ Yes |
| **HIPAA** | ✅ $1k/mo add-on | ⚠️ DIY | ✅ Included |

---

## When to Use VAPI

### ✅ Use VAPI if:

1. **You want to launch fast**
   - MVP in 1-2 days
   - No infrastructure setup
   - Focus on product, not DevOps

2. **You're okay with the cost**
   - $620-1,130/month (10k min)
   - 2-5x more than self-hosted
   - But saves weeks of dev time

3. **You value simplicity**
   - No-code agent builder
   - Managed infrastructure
   - Zero maintenance

4. **You need reliability**
   - 99.99% SLA
   - Enterprise-grade
   - Proven platform

---

### ❌ Don't use VAPI if:

1. **You're cost-sensitive**
   - Self-hosted is 2-5x cheaper
   - At scale, costs add up

2. **You want full control**
   - VAPI is opinionated
   - Limited customization
   - Vendor lock-in

3. **You have DevOps expertise**
   - Self-hosted gives more flexibility
   - Can optimize for your use case

4. **You're scaling beyond 100k min/month**
   - $9,100/month at 100k minutes
   - Self-hosted becomes cheaper

---

## The VAPI + Vercel + Railway/Exoscale Stack

### What You Deploy:

**1. VAPI (Voice AI Agent)**
- Configure in dashboard
- Set up custom functions
- Connect to your API

**2. Vercel (Frontend + API)**
- React widget with VAPI SDK
- API routes for custom functions
- Global edge deployment

**3. Railway or Exoscale (Database)**
- PostgreSQL + pgvector
- Valkey (Redis)
- MinIO (optional)

---

### How It Works:

```
1. User opens your app (Vercel)
   - Loads React widget
   - Connects to VAPI

2. User starts voice conversation
   - VAPI handles WebRTC
   - STT → LLM → TTS

3. Agent needs user data
   - VAPI calls your API (Vercel)
   - Vercel queries database (Railway/Exoscale)
   - Returns data to VAPI

4. Agent responds to user
   - VAPI synthesizes speech
   - User hears response

5. Call ends
   - VAPI sends webhook
   - You update database
```

---

### Code Example:

**Vercel API Route (custom function):**

```typescript
// /api/get-user-profile.ts
import { NextRequest, NextResponse } from 'next/server';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

export async function POST(req: NextRequest) {
  const { userId } = await req.json();
  
  // Query database
  const result = await pool.query(
    'SELECT * FROM user_profiles WHERE id = $1',
    [userId]
  );
  
  return NextResponse.json(result.rows[0]);
}
```

**VAPI Configuration (dashboard):**

```json
{
  "customFunctions": [
    {
      "name": "getUserProfile",
      "url": "https://your-app.vercel.app/api/get-user-profile",
      "method": "POST"
    }
  ]
}
```

**React Widget:**

```tsx
import { useVapi } from '@vapi-ai/react';

export function VoiceWidget() {
  const { start, stop, isActive } = useVapi({
    apiKey: process.env.NEXT_PUBLIC_VAPI_KEY,
    assistant: 'your-assistant-id'
  });
  
  return (
    <button onClick={isActive ? stop : start}>
      {isActive ? 'End Call' : 'Start Call'}
    </button>
  );
}
```

---

## Cost Comparison (10,000 minutes/month)

| Stack | Monthly Cost | Setup Time | Complexity |
|-------|--------------|------------|------------|
| **VAPI + Vercel + Railway** | **$590-1,080** | **1-2 days** | **Low** |
| **VAPI + Vercel + Exoscale** | **$620-1,130** | **1-2 days** | **Low** |
| LiveKit + Vercel + Exoscale + Edge Cache | $135-425 | 1-2 weeks | High |
| Pipecat + Vercel + Exoscale + Edge Cache | $235-735 | 1-2 weeks | Medium |
| Self-hosted Exoscale only | $100-200 | 2-4 weeks | Very High |

---

## My Recommendation: Start with VAPI

### Phase 1: MVP (Now - 6 months)

**Use: VAPI + Vercel + Railway**

**Why:**
1. **Fastest to market:** 1-2 days vs weeks
2. **Lowest complexity:** No DevOps
3. **Proven platform:** 99.99% SLA
4. **Focus on product:** Not infrastructure

**Cost:** $590-1,080/month

**Acceptable because:**
- You're validating product-market fit
- Dev time saved is worth the cost
- Can optimize later

---

### Phase 2: Optimize (6-12 months)

**Options:**

**A. Stay with VAPI (if it's working)**
- Negotiate volume discounts
- Optimize model usage
- Add edge caching if needed

**B. Migrate to LiveKit (if cost matters)**
- Self-host agents
- Keep Vercel frontend
- Save $475-675/month

**C. Hybrid (best of both)**
- VAPI for complex agents
- Self-hosted for simple agents
- Balance cost and complexity

---

### Phase 3: Scale (12+ months)

**At 100k+ minutes/month:**
- Self-hosted becomes cheaper
- You have resources for DevOps
- Migrate to LiveKit or custom solution

---

## The Railway vs Exoscale Decision

### Use Railway if:

✅ **You want simplicity**
- Managed PostgreSQL + Redis
- One-click deployment
- No Kubernetes

✅ **You're US-focused**
- Railway is US-based
- Lower latency for US users

✅ **You want fast setup**
- Deploy in minutes
- No infrastructure management

**Cost:** $50-150/month

---

### Use Exoscale if:

✅ **You want cost savings**
- Already have cluster deployed
- $100-200/month for everything
- More resources for the money

✅ **You're Europe-focused**
- Exoscale is EU-based (Geneva)
- GDPR compliant

✅ **You want full control**
- Kubernetes cluster
- Can add more services
- More flexible

**Cost:** $100-200/month (right-sized)

---

## My Specific Recommendation

### For The Agora MVP:

**Stack:**
1. **VAPI** - Voice AI ($500-910/month)
2. **Vercel** - Frontend + API ($20/month)
3. **Railway** - Database ($50-150/month)

**Total: $570-1,080/month**

**Why Railway over Exoscale:**
- Simpler (no K8s management)
- Faster setup (minutes vs hours)
- US-based (VAPI is US West)
- Lower latency to VAPI
- You can always migrate to Exoscale later

**Why not Exoscale now:**
- You already spent time setting it up
- But for MVP, simplicity > cost
- Railway is faster to iterate
- Can migrate later if needed

---

## Implementation Plan

### Week 1: VAPI + Vercel + Railway

**Day 1-2: VAPI Setup**
1. Sign up for VAPI ($10 free credit)
2. Create voice agent in dashboard
3. Configure STT, LLM, TTS providers
4. Set up custom functions
5. Test in playground

**Day 3-4: Vercel Deployment**
1. Create Next.js app
2. Add VAPI React SDK
3. Build voice widget
4. Deploy to Vercel
5. Test end-to-end

**Day 5: Railway Database**
1. Deploy PostgreSQL on Railway
2. Add pgvector extension
3. Create schema
4. Connect from Vercel API
5. Test custom functions

**Day 6-7: Integration & Testing**
1. Connect all pieces
2. Test voice conversations
3. Test database queries
4. Test custom functions
5. Launch MVP!

---

### Week 2-4: Iterate & Optimize

1. Gather user feedback
2. Optimize agent prompts
3. Add more custom functions
4. Improve memory layer
5. Monitor costs

---

## Cost Optimization Tips

### 1. Use Your Own API Keys

**Instead of VAPI's models:**
- Get your own Deepgram key (STT)
- Get your own OpenAI key (LLM)
- Get your own ElevenLabs key (TTS)

**Benefits:**
- Volume discounts
- Cost transparency
- Can switch providers

---

### 2. Optimize Model Usage

**STT (Speech-to-Text):**
- Use Deepgram Nova 2 ($0.0043/min)
- Or Whisper API ($0.006/min)

**LLM (Language Model):**
- Use GPT-4o-mini for simple tasks ($0.15/1M tokens)
- Use GPT-4o for complex tasks ($2.50/1M tokens)
- Average: ~$0.02/min

**TTS (Text-to-Speech):**
- Use ElevenLabs Turbo ($0.15/1k chars)
- Or OpenAI TTS ($0.015/1k chars)
- Average: ~$0.015/min

**Total optimized: ~$0.08/min** (vs $0.091/min)

---

### 3. Cache Aggressively

**In your Vercel API:**
- Cache user profiles (1 hour)
- Cache common queries (10 min)
- Use Redis for session state

**Reduces:**
- Database queries
- API latency
- Costs

---

### 4. Monitor Usage

**VAPI Dashboard:**
- Track minutes used
- Monitor concurrency
- Check error rates

**Set alerts:**
- When approaching limits
- When costs spike
- When errors increase

---

## Risks & Mitigation

### Risk 1: Vendor Lock-in

**Mitigation:**
- Keep business logic in your API
- Use standard interfaces
- Document integration points
- Plan migration path

---

### Risk 2: Cost Scaling

**Mitigation:**
- Monitor costs closely
- Optimize model usage
- Negotiate volume discounts
- Plan migration at 50k min/month

---

### Risk 3: VAPI Downtime

**Mitigation:**
- 99.99% SLA (4.38 min/month)
- Have fallback (text chat)
- Monitor status page
- Communicate with users

---

### Risk 4: Limited Customization

**Mitigation:**
- Use custom functions extensively
- Keep complex logic in your API
- Use webhooks for events
- Plan self-hosted migration

---

## Bottom Line

### For The Agora MVP: Use VAPI + Vercel + Railway

**Why:**
1. ✅ **Fastest to market:** 1-2 days
2. ✅ **Lowest complexity:** No DevOps
3. ✅ **Global edge:** Built-in
4. ✅ **Acceptable cost:** $570-1,080/month
5. ✅ **Focus on product:** Not infrastructure

**Trade-offs:**
- ❌ 2-5x more expensive than self-hosted
- ❌ Vendor lock-in
- ❌ Less customization

**But:**
- ✅ Saves weeks of dev time
- ✅ Validates product faster
- ✅ Can optimize later

---

### Migration Path:

**Month 0-6: VAPI + Railway**
- Launch MVP
- Validate product-market fit
- Gather user feedback

**Month 6-12: Optimize**
- Add edge caching if needed
- Negotiate volume discounts
- Consider hybrid approach

**Month 12+: Scale**
- Migrate to self-hosted (LiveKit)
- Or stay with VAPI if it's working
- Depends on usage and budget

---

## Next Steps

Want me to:
1. **Set up VAPI** account and configure agent
2. **Deploy Vercel** frontend with voice widget
3. **Set up Railway** database
4. **Integrate everything** and test
5. **All of the above**

**This is the simplest path to launch The Agora!** 🚀

**Time to MVP: 1-2 days**  
**Cost: $570-1,080/month**  
**Complexity: Low**

