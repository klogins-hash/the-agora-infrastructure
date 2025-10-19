# 8-Hour Conversation Memory Architecture: Implementation Guide

**Date:** October 19, 2025  
**Project:** The Agora - ADHD Voice Assistant  
**Goal:** Maintain full context for 8+ hour conversations with <300ms response time

---

## Architecture Overview

### Five-Layer Memory System

1. **Working Memory** (Redis/Valkey) - Last 30 minutes, <10ms access
2. **Short-Term Memory** (Redis/Valkey) - Last 2 hours summarized, <30ms access
3. **Long-Term Memory** (PostgreSQL) - Full history, <200ms access
4. **Semantic Memory** (Vector embeddings) - Semantic search, <100ms access
5. **Relationship Memory** (Apache AGE) - Graph insights, <300ms access

---

## Data Structures

### 1. Working Memory (Redis/Valkey)

#### Key Structure

```python
# Conversation transcript (last 30 minutes)
key: "conversation:{user_id}:{session_id}:transcript"
type: List
value: [
    {
        "timestamp": "2025-10-19T14:23:45Z",
        "speaker": "user",
        "text": "I need to finish the budget report",
        "audio_duration_ms": 2500,
        "turn_id": "turn_12345"
    },
    {
        "timestamp": "2025-10-19T14:23:47Z",
        "speaker": "agent",
        "text": "I can help you with that. What's the deadline?",
        "turn_id": "turn_12346"
    }
]
ttl: 1800 seconds (30 minutes)

# Current conversation summary
key: "conversation:{user_id}:{session_id}:summary"
type: Hash
value: {
    "current_topic": "Budget report completion",
    "active_tasks": ["budget_report", "friday_deadline"],
    "mentioned_entities": ["John", "CFO", "Q4_budget"],
    "user_mood": "focused",
    "conversation_start": "2025-10-19T06:00:00Z",
    "last_updated": "2025-10-19T14:23:47Z"
}
ttl: 1800 seconds

# Active entities (last 30 minutes)
key: "conversation:{user_id}:{session_id}:entities"
type: Sorted Set
value: {
    "John": 1729346627.5,  # timestamp as score
    "budget_report": 1729346625.2,
    "Friday": 1729346627.8
}
ttl: 1800 seconds

# Current turn context
key: "conversation:{user_id}:{session_id}:current_turn"
type: Hash
value: {
    "turn_id": "turn_12346",
    "user_intent": "task_completion",
    "extracted_entities": ["budget_report", "deadline"],
    "sentiment": "neutral",
    "requires_action": true
}
ttl: 300 seconds (5 minutes)
```

#### Memory Size Calculation

- Transcript (30 min, ~30 turns): ~60 KB
- Summary: ~10 KB
- Entities: ~5 KB
- Current turn: ~2 KB
- **Total: ~77 KB per active session**

### 2. Short-Term Memory (Redis/Valkey)

#### Key Structure

```python
# 2-hour summarized conversation
key: "conversation:{user_id}:{session_id}:short_term"
type: List
value: [
    {
        "time_block": "2025-10-19T12:00-12:30",
        "summary": "User discussed Q4 budget planning. Mentioned need to coordinate with John (CFO). Deadline is Friday.",
        "key_facts": [
            "Budget report due Friday",
            "John needs to approve",
            "Q4 projections needed"
        ],
        "important_quotes": [
            "This is critical for the board meeting"
        ],
        "decisions": [
            "Focus on budget completion today"
        ],
        "entities": ["John", "CFO", "budget_report", "Friday", "Q4"],
        "topics": ["budget", "planning", "deadlines"],
        "sentiment_arc": "stressed → focused → determined"
    },
    # ... 3 more 30-minute blocks
]
ttl: 7200 seconds (2 hours)

# Entity timeline (last 2 hours)
key: "conversation:{user_id}:{session_id}:entity_timeline"
type: Hash
value: {
    "John": {
        "first_mentioned": "2025-10-19T12:15:00Z",
        "last_mentioned": "2025-10-19T13:45:00Z",
        "mention_count": 5,
        "context": "CFO, needs to approve budget"
    },
    "budget_report": {
        "first_mentioned": "2025-10-19T12:00:00Z",
        "last_mentioned": "2025-10-19T14:23:45Z",
        "mention_count": 12,
        "context": "Q4 budget, due Friday, critical for board"
    }
}
ttl: 7200 seconds

# Conversation flow (topic transitions)
key: "conversation:{user_id}:{session_id}:flow"
type: List
value: [
    {
        "time": "2025-10-19T12:00:00Z",
        "topic": "budget_planning",
        "duration_minutes": 30
    },
    {
        "time": "2025-10-19T12:30:00Z",
        "topic": "team_coordination",
        "duration_minutes": 20
    },
    {
        "time": "2025-10-19T12:50:00Z",
        "topic": "budget_planning",  # returned to previous topic
        "duration_minutes": 70
    }
]
ttl: 7200 seconds
```

#### Memory Size Calculation

- 4 × 30-min summaries: ~800 KB
- Entity timeline: ~200 KB
- Conversation flow: ~50 KB
- **Total: ~1 MB per active session**

### 3. Long-Term Memory (PostgreSQL)

#### Schema

```sql
-- Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    session_id UUID NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    total_duration_seconds INTEGER,
    turn_count INTEGER,
    summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, session_id)
);

CREATE INDEX idx_conversations_user_session ON conversations(user_id, session_id);
CREATE INDEX idx_conversations_started_at ON conversations(started_at DESC);

-- Conversation turns table
CREATE TABLE conversation_turns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    turn_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    speaker VARCHAR(10) NOT NULL, -- 'user' or 'agent'
    text TEXT NOT NULL,
    audio_duration_ms INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, turn_id)
);

CREATE INDEX idx_turns_conversation ON conversation_turns(conversation_id, timestamp);
CREATE INDEX idx_turns_timestamp ON conversation_turns(timestamp DESC);
CREATE INDEX idx_turns_text_search ON conversation_turns USING gin(to_tsvector('english', text));

-- Conversation summaries (30-min blocks)
CREATE TABLE conversation_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    time_block_start TIMESTAMP WITH TIME ZONE NOT NULL,
    time_block_end TIMESTAMP WITH TIME ZONE NOT NULL,
    summary TEXT NOT NULL,
    key_facts JSONB,
    important_quotes JSONB,
    decisions JSONB,
    entities JSONB,
    topics JSONB,
    sentiment_arc VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_summaries_conversation ON conversation_summaries(conversation_id, time_block_start);

-- Entities table
CREATE TABLE conversation_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    entity_name VARCHAR(200) NOT NULL,
    entity_type VARCHAR(50), -- 'person', 'topic', 'task', 'date', etc.
    first_mentioned TIMESTAMP WITH TIME ZONE NOT NULL,
    last_mentioned TIMESTAMP WITH TIME ZONE NOT NULL,
    mention_count INTEGER DEFAULT 1,
    context TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_entities_conversation ON conversation_entities(conversation_id);
CREATE INDEX idx_entities_name ON conversation_entities(entity_name);

-- Vector embeddings table
CREATE TABLE conversation_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    turn_id VARCHAR(50),
    chunk_text TEXT NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 dimension
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_embeddings_conversation ON conversation_embeddings(conversation_id);
-- For pgvector similarity search
CREATE INDEX idx_embeddings_vector ON conversation_embeddings USING ivfflat (embedding vector_cosine_ops);
```

### 4. Apache AGE Graph Schema

#### Cypher Schema

```cypher
-- Node types
CREATE (:User {
    user_id: UUID,
    name: STRING,
    adhd_profile: JSONB
})

CREATE (:Entity {
    name: STRING,
    type: STRING,  -- 'person', 'topic', 'task', 'decision'
    first_seen: TIMESTAMP,
    last_seen: TIMESTAMP
})

CREATE (:Topic {
    name: STRING,
    category: STRING
})

CREATE (:Task {
    name: STRING,
    status: STRING,
    deadline: TIMESTAMP
})

CREATE (:Decision {
    description: STRING,
    made_at: TIMESTAMP,
    importance: INTEGER
})

CREATE (:Conversation {
    session_id: UUID,
    started_at: TIMESTAMP,
    ended_at: TIMESTAMP
})

-- Relationship types
CREATE (user:User)-[:DISCUSSED]->(topic:Topic) {
    timestamp: TIMESTAMP,
    sentiment: STRING,
    duration_minutes: INTEGER
}

CREATE (topic1:Topic)-[:RELATES_TO]->(topic2:Topic) {
    strength: FLOAT,  -- 0.0 to 1.0
    co_occurrence_count: INTEGER
}

CREATE (task:Task)-[:REQUIRES]->(dependency:Task) {
    discovered_at: TIMESTAMP
}

CREATE (task:Task)-[:MENTIONED_IN]->(conversation:Conversation) {
    timestamp: TIMESTAMP
}

CREATE (entity1:Entity)-[:MENTIONED_WITH]->(entity2:Entity) {
    conversation_id: UUID,
    timestamp: TIMESTAMP
}

CREATE (decision:Decision)-[:AFFECTS]->(task:Task) {
    impact: STRING
}
```

---

## Background Processing Pipelines

### Pipeline 1: Real-Time Processing (Every Turn)

```python
# File: pipelines/realtime_processor.py

from datetime import datetime
from typing import Dict, Any
import redis
import json

class RealtimeProcessor:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def process_turn(
        self,
        user_id: str,
        session_id: str,
        turn_data: Dict[str, Any]
    ) -> None:
        """Process each conversation turn in real-time"""
        
        # 1. Add to transcript (working memory)
        transcript_key = f"conversation:{user_id}:{session_id}:transcript"
        self.redis.rpush(transcript_key, json.dumps(turn_data))
        self.redis.expire(transcript_key, 1800)  # 30 min TTL
        
        # 2. Extract entities
        entities = await self.extract_entities(turn_data['text'])
        
        # 3. Update active entities
        entities_key = f"conversation:{user_id}:{session_id}:entities"
        timestamp = datetime.now().timestamp()
        for entity in entities:
            self.redis.zadd(entities_key, {entity: timestamp})
        self.redis.expire(entities_key, 1800)
        
        # 4. Update conversation summary
        await self.update_summary(user_id, session_id, turn_data, entities)
        
        # 5. Update current turn context
        turn_context = {
            "turn_id": turn_data['turn_id'],
            "user_intent": await self.classify_intent(turn_data['text']),
            "extracted_entities": entities,
            "sentiment": await self.analyze_sentiment(turn_data['text']),
            "requires_action": await self.detect_action(turn_data['text'])
        }
        
        turn_key = f"conversation:{user_id}:{session_id}:current_turn"
        self.redis.hset(turn_key, mapping=turn_context)
        self.redis.expire(turn_key, 300)
        
    async def extract_entities(self, text: str) -> list:
        """Extract entities using NER model"""
        # Use spaCy, Groq, or other NER
        # Return list of entity names
        pass
    
    async def classify_intent(self, text: str) -> str:
        """Classify user intent"""
        # Use LLM or classification model
        pass
    
    async def analyze_sentiment(self, text: str) -> str:
        """Analyze sentiment"""
        # Return 'positive', 'neutral', 'negative'
        pass
    
    async def detect_action(self, text: str) -> bool:
        """Detect if turn requires action"""
        # Check for task creation, scheduling, etc.
        pass
    
    async def update_summary(
        self,
        user_id: str,
        session_id: str,
        turn_data: Dict[str, Any],
        entities: list
    ) -> None:
        """Update conversation summary"""
        summary_key = f"conversation:{user_id}:{session_id}:summary"
        
        # Get current summary
        current = self.redis.hgetall(summary_key)
        
        # Update with new information
        updated = {
            "current_topic": await self.extract_topic(turn_data['text']),
            "active_tasks": self._merge_tasks(current.get('active_tasks', []), entities),
            "mentioned_entities": self._merge_entities(current.get('mentioned_entities', []), entities),
            "user_mood": await self.analyze_sentiment(turn_data['text']),
            "last_updated": datetime.now().isoformat()
        }
        
        self.redis.hset(summary_key, mapping=updated)
        self.redis.expire(summary_key, 1800)
```

### Pipeline 2: Short-Term Summarization (Every 5 Minutes)

```python
# File: pipelines/short_term_summarizer.py

from datetime import datetime, timedelta
import redis
import json
from typing import Dict, List

class ShortTermSummarizer:
    def __init__(self, redis_client: redis.Redis, llm_client):
        self.redis = redis_client
        self.llm = llm_client
    
    async def summarize_last_5_minutes(
        self,
        user_id: str,
        session_id: str
    ) -> None:
        """Summarize last 5 minutes of conversation"""
        
        # 1. Get transcript from last 5 minutes
        transcript_key = f"conversation:{user_id}:{session_id}:transcript"
        transcript_json = self.redis.lrange(transcript_key, -10, -1)  # Last ~10 turns
        transcript = [json.loads(t) for t in transcript_json]
        
        # 2. Generate summary using LLM
        summary_prompt = f"""
        Summarize the following conversation segment:
        
        {self._format_transcript(transcript)}
        
        Provide:
        1. Main topic discussed
        2. Key facts mentioned
        3. Important quotes (if any)
        4. Decisions made (if any)
        5. Entities mentioned (people, topics, tasks)
        6. Sentiment arc
        """
        
        summary = await self.llm.generate(summary_prompt)
        
        # 3. Parse summary into structured format
        structured_summary = await self._parse_summary(summary)
        
        # 4. Add to short-term memory
        short_term_key = f"conversation:{user_id}:{session_id}:short_term"
        time_block = {
            "time_block": f"{datetime.now() - timedelta(minutes=5):%Y-%m-%dT%H:%M}-{datetime.now():%H:%M}",
            **structured_summary
        }
        
        self.redis.rpush(short_term_key, json.dumps(time_block))
        self.redis.expire(short_term_key, 7200)  # 2 hour TTL
        
        # 5. Update entity timeline
        await self._update_entity_timeline(user_id, session_id, structured_summary['entities'])
        
    def _format_transcript(self, transcript: List[Dict]) -> str:
        """Format transcript for LLM"""
        return "\n".join([
            f"{t['speaker']}: {t['text']}"
            for t in transcript
        ])
    
    async def _parse_summary(self, summary: str) -> Dict:
        """Parse LLM summary into structured format"""
        # Use LLM or regex to extract structured data
        pass
    
    async def _update_entity_timeline(
        self,
        user_id: str,
        session_id: str,
        entities: List[str]
    ) -> None:
        """Update entity timeline in short-term memory"""
        timeline_key = f"conversation:{user_id}:{session_id}:entity_timeline"
        
        for entity in entities:
            entity_data = self.redis.hget(timeline_key, entity)
            
            if entity_data:
                data = json.loads(entity_data)
                data['last_mentioned'] = datetime.now().isoformat()
                data['mention_count'] += 1
            else:
                data = {
                    "first_mentioned": datetime.now().isoformat(),
                    "last_mentioned": datetime.now().isoformat(),
                    "mention_count": 1,
                    "context": ""  # Will be filled by LLM
                }
            
            self.redis.hset(timeline_key, entity, json.dumps(data))
        
        self.redis.expire(timeline_key, 7200)
```

### Pipeline 3: Long-Term Archival (Every 15 Minutes)

```python
# File: pipelines/long_term_archiver.py

from datetime import datetime, timedelta
import redis
import asyncpg
import json
from typing import List, Dict

class LongTermArchiver:
    def __init__(
        self,
        redis_client: redis.Redis,
        pg_pool: asyncpg.Pool,
        embedding_client
    ):
        self.redis = redis_client
        self.pg = pg_pool
        self.embedder = embedding_client
    
    async def archive_to_postgresql(
        self,
        user_id: str,
        session_id: str
    ) -> None:
        """Archive conversation data to PostgreSQL"""
        
        # 1. Get transcript from Redis (older than 30 minutes)
        transcript_key = f"conversation:{user_id}:{session_id}:transcript"
        all_turns = self.redis.lrange(transcript_key, 0, -1)
        
        # Filter turns older than 30 minutes
        cutoff_time = datetime.now() - timedelta(minutes=30)
        old_turns = [
            json.loads(t) for t in all_turns
            if datetime.fromisoformat(json.loads(t)['timestamp']) < cutoff_time
        ]
        
        if not old_turns:
            return
        
        # 2. Get conversation_id from PostgreSQL
        conversation_id = await self._get_or_create_conversation(user_id, session_id)
        
        # 3. Insert turns into PostgreSQL
        await self._insert_turns(conversation_id, old_turns)
        
        # 4. Generate and store embeddings
        await self._generate_embeddings(conversation_id, old_turns)
        
        # 5. Archive summaries
        await self._archive_summaries(user_id, session_id, conversation_id)
        
        # 6. Archive entities
        await self._archive_entities(user_id, session_id, conversation_id)
        
        # 7. Update graph (Apache AGE)
        await self._update_graph(user_id, session_id, old_turns)
        
        # 8. Remove old turns from Redis (keep last 30 min)
        turns_to_keep = len(all_turns) - len(old_turns)
        self.redis.ltrim(transcript_key, -turns_to_keep, -1)
        
    async def _get_or_create_conversation(
        self,
        user_id: str,
        session_id: str
    ) -> str:
        """Get or create conversation record"""
        async with self.pg.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT id FROM conversations
                WHERE user_id = $1 AND session_id = $2
            """, user_id, session_id)
            
            if row:
                return row['id']
            
            # Create new conversation
            row = await conn.fetchrow("""
                INSERT INTO conversations (user_id, session_id, started_at)
                VALUES ($1, $2, $3)
                RETURNING id
            """, user_id, session_id, datetime.now())
            
            return row['id']
    
    async def _insert_turns(
        self,
        conversation_id: str,
        turns: List[Dict]
    ) -> None:
        """Insert conversation turns into PostgreSQL"""
        async with self.pg.acquire() as conn:
            await conn.executemany("""
                INSERT INTO conversation_turns 
                (conversation_id, turn_id, timestamp, speaker, text, audio_duration_ms, metadata)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT (conversation_id, turn_id) DO NOTHING
            """, [
                (
                    conversation_id,
                    turn['turn_id'],
                    datetime.fromisoformat(turn['timestamp']),
                    turn['speaker'],
                    turn['text'],
                    turn.get('audio_duration_ms'),
                    json.dumps(turn.get('metadata', {}))
                )
                for turn in turns
            ])
    
    async def _generate_embeddings(
        self,
        conversation_id: str,
        turns: List[Dict]
    ) -> None:
        """Generate and store embeddings for semantic search"""
        # Combine turns into chunks (e.g., 3-5 turns per chunk)
        chunks = self._create_chunks(turns, chunk_size=5)
        
        # Generate embeddings
        embeddings = await self.embedder.embed_batch([
            chunk['text'] for chunk in chunks
        ])
        
        # Store in PostgreSQL
        async with self.pg.acquire() as conn:
            await conn.executemany("""
                INSERT INTO conversation_embeddings
                (conversation_id, turn_id, chunk_text, embedding, timestamp, metadata)
                VALUES ($1, $2, $3, $4, $5, $6)
            """, [
                (
                    conversation_id,
                    chunk['turn_id'],
                    chunk['text'],
                    embedding,
                    datetime.fromisoformat(chunk['timestamp']),
                    json.dumps(chunk.get('metadata', {}))
                )
                for chunk, embedding in zip(chunks, embeddings)
            ])
    
    def _create_chunks(self, turns: List[Dict], chunk_size: int = 5) -> List[Dict]:
        """Create text chunks from turns"""
        chunks = []
        for i in range(0, len(turns), chunk_size):
            chunk_turns = turns[i:i+chunk_size]
            chunks.append({
                'turn_id': chunk_turns[0]['turn_id'],
                'text': ' '.join([t['text'] for t in chunk_turns]),
                'timestamp': chunk_turns[0]['timestamp'],
                'metadata': {
                    'turn_count': len(chunk_turns),
                    'speakers': list(set([t['speaker'] for t in chunk_turns]))
                }
            })
        return chunks
    
    async def _archive_summaries(
        self,
        user_id: str,
        session_id: str,
        conversation_id: str
    ) -> None:
        """Archive summaries from Redis to PostgreSQL"""
        short_term_key = f"conversation:{user_id}:{session_id}:short_term"
        summaries_json = self.redis.lrange(short_term_key, 0, -1)
        
        if not summaries_json:
            return
        
        summaries = [json.loads(s) for s in summaries_json]
        
        async with self.pg.acquire() as conn:
            await conn.executemany("""
                INSERT INTO conversation_summaries
                (conversation_id, time_block_start, time_block_end, summary, 
                 key_facts, important_quotes, decisions, entities, topics, sentiment_arc)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                ON CONFLICT DO NOTHING
            """, [
                (
                    conversation_id,
                    self._parse_time_block_start(s['time_block']),
                    self._parse_time_block_end(s['time_block']),
                    s.get('summary', ''),
                    json.dumps(s.get('key_facts', [])),
                    json.dumps(s.get('important_quotes', [])),
                    json.dumps(s.get('decisions', [])),
                    json.dumps(s.get('entities', [])),
                    json.dumps(s.get('topics', [])),
                    s.get('sentiment_arc', '')
                )
                for s in summaries
            ])
    
    async def _archive_entities(
        self,
        user_id: str,
        session_id: str,
        conversation_id: str
    ) -> None:
        """Archive entities from Redis to PostgreSQL"""
        timeline_key = f"conversation:{user_id}:{session_id}:entity_timeline"
        entities_data = self.redis.hgetall(timeline_key)
        
        if not entities_data:
            return
        
        async with self.pg.acquire() as conn:
            for entity_name, entity_json in entities_data.items():
                entity_data = json.loads(entity_json)
                
                await conn.execute("""
                    INSERT INTO conversation_entities
                    (conversation_id, entity_name, first_mentioned, last_mentioned, 
                     mention_count, context)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    ON CONFLICT (conversation_id, entity_name) 
                    DO UPDATE SET
                        last_mentioned = EXCLUDED.last_mentioned,
                        mention_count = conversation_entities.mention_count + EXCLUDED.mention_count
                """, 
                    conversation_id,
                    entity_name,
                    datetime.fromisoformat(entity_data['first_mentioned']),
                    datetime.fromisoformat(entity_data['last_mentioned']),
                    entity_data['mention_count'],
                    entity_data.get('context', '')
                )
    
    async def _update_graph(
        self,
        user_id: str,
        session_id: str,
        turns: List[Dict]
    ) -> None:
        """Update Apache AGE graph with new data"""
        # This will be implemented in the graph pipeline
        pass
```

### Pipeline 4: Graph Update (Every 15 Minutes)

```python
# File: pipelines/graph_updater.py

from datetime import datetime
import asyncpg
from typing import List, Dict
import age  # Apache AGE Python driver

class GraphUpdater:
    def __init__(self, pg_pool: asyncpg.Pool, graph_name: str = "conversation_graph"):
        self.pg = pg_pool
        self.graph_name = graph_name
    
    async def update_graph(
        self,
        user_id: str,
        session_id: str,
        conversation_id: str
    ) -> None:
        """Update Apache AGE graph with conversation data"""
        
        # 1. Get entities from PostgreSQL
        entities = await self._get_entities(conversation_id)
        
        # 2. Get summaries to extract relationships
        summaries = await self._get_summaries(conversation_id)
        
        # 3. Create/update entity nodes
        await self._upsert_entity_nodes(entities)
        
        # 4. Create relationships between entities
        await self._create_entity_relationships(entities, summaries)
        
        # 5. Create topic nodes and relationships
        await self._create_topic_relationships(summaries)
        
        # 6. Create task nodes and dependencies
        await self._create_task_dependencies(summaries)
    
    async def _get_entities(self, conversation_id: str) -> List[Dict]:
        """Get entities from PostgreSQL"""
        async with self.pg.acquire() as conn:
            rows = await conn.fetch("""
                SELECT entity_name, entity_type, first_mentioned, 
                       last_mentioned, mention_count, context
                FROM conversation_entities
                WHERE conversation_id = $1
            """, conversation_id)
            
            return [dict(row) for row in rows]
    
    async def _get_summaries(self, conversation_id: str) -> List[Dict]:
        """Get summaries from PostgreSQL"""
        async with self.pg.acquire() as conn:
            rows = await conn.fetch("""
                SELECT time_block_start, time_block_end, summary,
                       key_facts, important_quotes, decisions, entities, topics
                FROM conversation_summaries
                WHERE conversation_id = $1
                ORDER BY time_block_start
            """, conversation_id)
            
            return [dict(row) for row in rows]
    
    async def _upsert_entity_nodes(self, entities: List[Dict]) -> None:
        """Create or update entity nodes in graph"""
        async with self.pg.acquire() as conn:
            for entity in entities:
                # Use Apache AGE Cypher query
                await conn.execute(f"""
                    SELECT * FROM cypher('{self.graph_name}', $$
                        MERGE (e:Entity {{name: $name}})
                        ON CREATE SET
                            e.type = $type,
                            e.first_seen = $first_seen,
                            e.last_seen = $last_seen,
                            e.mention_count = $mention_count,
                            e.context = $context
                        ON MATCH SET
                            e.last_seen = $last_seen,
                            e.mention_count = e.mention_count + $mention_count,
                            e.context = $context
                        RETURN e
                    $$, %s) as (entity agtype);
                """, (
                    entity['entity_name'],
                    entity.get('entity_type', 'unknown'),
                    entity['first_mentioned'].isoformat(),
                    entity['last_mentioned'].isoformat(),
                    entity['mention_count'],
                    entity.get('context', '')
                ))
    
    async def _create_entity_relationships(
        self,
        entities: List[Dict],
        summaries: List[Dict]
    ) -> None:
        """Create relationships between co-occurring entities"""
        async with self.pg.acquire() as conn:
            for summary in summaries:
                summary_entities = summary.get('entities', [])
                
                # Create MENTIONED_WITH relationships for co-occurring entities
                for i, entity1 in enumerate(summary_entities):
                    for entity2 in summary_entities[i+1:]:
                        await conn.execute(f"""
                            SELECT * FROM cypher('{self.graph_name}', $$
                                MATCH (e1:Entity {{name: $entity1}})
                                MATCH (e2:Entity {{name: $entity2}})
                                MERGE (e1)-[r:MENTIONED_WITH]->(e2)
                                ON CREATE SET
                                    r.first_occurrence = $timestamp,
                                    r.co_occurrence_count = 1
                                ON MATCH SET
                                    r.co_occurrence_count = r.co_occurrence_count + 1,
                                    r.last_occurrence = $timestamp
                                RETURN r
                            $$, %s) as (rel agtype);
                        """, (
                            entity1,
                            entity2,
                            summary['time_block_start'].isoformat()
                        ))
    
    async def _create_topic_relationships(self, summaries: List[Dict]) -> None:
        """Create topic nodes and relationships"""
        async with self.pg.acquire() as conn:
            for summary in summaries:
                topics = summary.get('topics', [])
                
                for topic in topics:
                    # Create topic node
                    await conn.execute(f"""
                        SELECT * FROM cypher('{self.graph_name}', $$
                            MERGE (t:Topic {{name: $topic}})
                            RETURN t
                        $$, %s) as (topic agtype);
                    """, (topic,))
                
                # Create RELATES_TO relationships between consecutive topics
                for i in range(len(topics) - 1):
                    await conn.execute(f"""
                        SELECT * FROM cypher('{self.graph_name}', $$
                            MATCH (t1:Topic {{name: $topic1}})
                            MATCH (t2:Topic {{name: $topic2}})
                            MERGE (t1)-[r:RELATES_TO]->(t2)
                            ON CREATE SET
                                r.strength = 0.5,
                                r.co_occurrence_count = 1
                            ON MATCH SET
                                r.co_occurrence_count = r.co_occurrence_count + 1,
                                r.strength = CASE
                                    WHEN r.co_occurrence_count > 10 THEN 1.0
                                    WHEN r.co_occurrence_count > 5 THEN 0.8
                                    ELSE 0.5
                                END
                            RETURN r
                        $$, %s) as (rel agtype);
                    """, (topics[i], topics[i+1]))
    
    async def _create_task_dependencies(self, summaries: List[Dict]) -> None:
        """Create task nodes and dependency relationships"""
        async with self.pg.acquire() as conn:
            for summary in summaries:
                decisions = summary.get('decisions', [])
                key_facts = summary.get('key_facts', [])
                
                # Extract tasks from decisions and facts
                # (This would use NLP/LLM to identify tasks and dependencies)
                # For now, simplified example:
                
                for decision in decisions:
                    # Create task node
                    await conn.execute(f"""
                        SELECT * FROM cypher('{self.graph_name}', $$
                            MERGE (t:Task {{description: $description}})
                            ON CREATE SET
                                t.created_at = $created_at,
                                t.status = 'pending'
                            RETURN t
                        $$, %s) as (task agtype);
                    """, (
                        decision,
                        summary['time_block_start'].isoformat()
                    ))
```

---

## Query Strategies

### Query Strategy 1: Recent Context (<30 minutes)

```python
# File: queries/recent_context.py

class RecentContextQuery:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def get_recent_context(
        self,
        user_id: str,
        session_id: str,
        query: str
    ) -> Dict:
        """Get context from last 30 minutes (working memory)"""
        
        # 1. Get full transcript
        transcript_key = f"conversation:{user_id}:{session_id}:transcript"
        transcript_json = self.redis.lrange(transcript_key, 0, -1)
        transcript = [json.loads(t) for t in transcript_json]
        
        # 2. Get conversation summary
        summary_key = f"conversation:{user_id}:{session_id}:summary"
        summary = self.redis.hgetall(summary_key)
        
        # 3. Get active entities
        entities_key = f"conversation:{user_id}:{session_id}:entities"
        entities = self.redis.zrange(entities_key, 0, -1, withscores=True)
        
        # 4. Simple keyword search in transcript
        relevant_turns = [
            turn for turn in transcript
            if any(keyword.lower() in turn['text'].lower() 
                   for keyword in query.split())
        ]
        
        return {
            "source": "working_memory",
            "latency_ms": 10,
            "transcript": transcript,
            "summary": summary,
            "entities": entities,
            "relevant_turns": relevant_turns
        }
```

### Query Strategy 2: Short-Term Context (30 min - 2 hours)

```python
# File: queries/short_term_context.py

class ShortTermContextQuery:
    def __init__(self, redis_client, llm_client):
        self.redis = redis_client
        self.llm = llm_client
    
    async def get_short_term_context(
        self,
        user_id: str,
        session_id: str,
        query: str
    ) -> Dict:
        """Get context from last 2 hours (short-term memory)"""
        
        # 1. Get short-term summaries
        short_term_key = f"conversation:{user_id}:{session_id}:short_term"
        summaries_json = self.redis.lrange(short_term_key, 0, -1)
        summaries = [json.loads(s) for s in summaries_json]
        
        # 2. Get entity timeline
        timeline_key = f"conversation:{user_id}:{session_id}:entity_timeline"
        entity_timeline = self.redis.hgetall(timeline_key)
        
        # 3. Search summaries for relevant information
        relevant_summaries = []
        for summary in summaries:
            # Check if query keywords appear in summary
            if any(keyword.lower() in summary.get('summary', '').lower()
                   for keyword in query.split()):
                relevant_summaries.append(summary)
            
            # Check if query keywords match entities
            if any(keyword.lower() in entity.lower()
                   for keyword in query.split()
                   for entity in summary.get('entities', [])):
                relevant_summaries.append(summary)
        
        return {
            "source": "short_term_memory",
            "latency_ms": 30,
            "summaries": summaries,
            "entity_timeline": entity_timeline,
            "relevant_summaries": relevant_summaries
        }
```

### Query Strategy 3: Long-Term Context (2+ hours)

```python
# File: queries/long_term_context.py

class LongTermContextQuery:
    def __init__(self, pg_pool, embedding_client):
        self.pg = pg_pool
        self.embedder = embedding_client
    
    async def get_long_term_context(
        self,
        user_id: str,
        session_id: str,
        query: str
    ) -> Dict:
        """Get context from full conversation history (PostgreSQL)"""
        
        # 1. Get conversation_id
        async with self.pg.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT id FROM conversations
                WHERE user_id = $1 AND session_id = $2
            """, user_id, session_id)
            
            if not row:
                return {"source": "long_term_memory", "results": []}
            
            conversation_id = row['id']
        
        # 2. Generate query embedding
        query_embedding = await self.embedder.embed(query)
        
        # 3. Semantic search using pgvector
        async with self.pg.acquire() as conn:
            results = await conn.fetch("""
                SELECT 
                    chunk_text,
                    timestamp,
                    metadata,
                    1 - (embedding <=> $1::vector) as similarity
                FROM conversation_embeddings
                WHERE conversation_id = $2
                ORDER BY embedding <=> $1::vector
                LIMIT 10
            """, query_embedding, conversation_id)
        
        # 4. Full-text search as fallback
        async with self.pg.acquire() as conn:
            text_results = await conn.fetch("""
                SELECT 
                    text,
                    timestamp,
                    speaker,
                    ts_rank(to_tsvector('english', text), plainto_tsquery('english', $1)) as rank
                FROM conversation_turns
                WHERE conversation_id = $2
                AND to_tsvector('english', text) @@ plainto_tsquery('english', $1)
                ORDER BY rank DESC
                LIMIT 10
            """, query, conversation_id)
        
        return {
            "source": "long_term_memory",
            "latency_ms": 150,
            "semantic_results": [dict(r) for r in results],
            "text_results": [dict(r) for r in text_results]
        }
```

### Query Strategy 4: Graph Insights

```python
# File: queries/graph_insights.py

class GraphInsightsQuery:
    def __init__(self, pg_pool, graph_name: str = "conversation_graph"):
        self.pg = pg_pool
        self.graph_name = graph_name
    
    async def get_graph_insights(
        self,
        user_id: str,
        query: str,
        query_type: str = "relationship"
    ) -> Dict:
        """Get insights from Apache AGE graph"""
        
        if query_type == "relationship":
            return await self._query_relationships(query)
        elif query_type == "dependency":
            return await self._query_dependencies(query)
        elif query_type == "pattern":
            return await self._query_patterns(query)
        else:
            return {"error": "Unknown query type"}
    
    async def _query_relationships(self, entity_name: str) -> Dict:
        """Find relationships for an entity"""
        async with self.pg.acquire() as conn:
            results = await conn.fetch(f"""
                SELECT * FROM cypher('{self.graph_name}', $$
                    MATCH (e1:Entity {{name: $entity_name}})-[r]-(e2:Entity)
                    RETURN e1, type(r) as relationship, e2, r.co_occurrence_count as strength
                    ORDER BY strength DESC
                    LIMIT 20
                $$, %s) as (entity1 agtype, relationship agtype, entity2 agtype, strength agtype);
            """, (entity_name,))
            
            return {
                "source": "graph_insights",
                "latency_ms": 200,
                "relationships": [dict(r) for r in results]
            }
    
    async def _query_dependencies(self, task_name: str) -> Dict:
        """Find task dependencies"""
        async with self.pg.acquire() as conn:
            results = await conn.fetch(f"""
                SELECT * FROM cypher('{self.graph_name}', $$
                    MATCH path = (t1:Task {{description: $task_name}})-[:REQUIRES*]->(t2:Task)
                    RETURN t1, path, t2
                    LIMIT 10
                $$, %s) as (task1 agtype, path agtype, task2 agtype);
            """, (task_name,))
            
            return {
                "source": "graph_insights",
                "latency_ms": 250,
                "dependencies": [dict(r) for r in results]
            }
    
    async def _query_patterns(self, topic: str) -> Dict:
        """Find conversation patterns"""
        async with self.pg.acquire() as conn:
            results = await conn.fetch(f"""
                SELECT * FROM cypher('{self.graph_name}', $$
                    MATCH (t1:Topic {{name: $topic}})-[r:RELATES_TO]-(t2:Topic)
                    WHERE r.strength > 0.7
                    RETURN t1, t2, r.strength as strength, r.co_occurrence_count as count
                    ORDER BY strength DESC
                    LIMIT 10
                $$, %s) as (topic1 agtype, topic2 agtype, strength agtype, count agtype);
            """, (topic,))
            
            return {
                "source": "graph_insights",
                "latency_ms": 180,
                "patterns": [dict(r) for r in results]
            }
```

### Unified Query Orchestrator

```python
# File: queries/orchestrator.py

class QueryOrchestrator:
    def __init__(
        self,
        redis_client,
        pg_pool,
        llm_client,
        embedding_client
    ):
        self.recent = RecentContextQuery(redis_client)
        self.short_term = ShortTermContextQuery(redis_client, llm_client)
        self.long_term = LongTermContextQuery(pg_pool, embedding_client)
        self.graph = GraphInsightsQuery(pg_pool)
        self.llm = llm_client
    
    async def query(
        self,
        user_id: str,
        session_id: str,
        query: str
    ) -> Dict:
        """Orchestrate multi-layer query"""
        
        # 1. Start with recent context (fastest)
        recent_context = await self.recent.get_recent_context(
            user_id, session_id, query
        )
        
        # 2. If not found in recent, check short-term
        if not recent_context.get('relevant_turns'):
            short_term_context = await self.short_term.get_short_term_context(
                user_id, session_id, query
            )
        else:
            short_term_context = None
        
        # 3. If still not enough, do semantic search in long-term
        if not recent_context.get('relevant_turns') and \
           not (short_term_context and short_term_context.get('relevant_summaries')):
            long_term_context = await self.long_term.get_long_term_context(
                user_id, session_id, query
            )
        else:
            long_term_context = None
        
        # 4. Get graph insights (parallel with above)
        graph_insights = await self.graph.get_graph_insights(
            user_id, query, query_type="relationship"
        )
        
        # 5. Combine all context and generate response
        combined_context = self._combine_context(
            recent_context,
            short_term_context,
            long_term_context,
            graph_insights
        )
        
        # 6. Generate final response using LLM
        response = await self._generate_response(query, combined_context)
        
        return {
            "query": query,
            "response": response,
            "context_sources": combined_context['sources'],
            "total_latency_ms": combined_context['total_latency_ms']
        }
    
    def _combine_context(
        self,
        recent: Dict,
        short_term: Dict,
        long_term: Dict,
        graph: Dict
    ) -> Dict:
        """Combine context from all layers"""
        sources = []
        total_latency = 0
        
        if recent and recent.get('relevant_turns'):
            sources.append("working_memory")
            total_latency += recent.get('latency_ms', 0)
        
        if short_term and short_term.get('relevant_summaries'):
            sources.append("short_term_memory")
            total_latency += short_term.get('latency_ms', 0)
        
        if long_term and (long_term.get('semantic_results') or long_term.get('text_results')):
            sources.append("long_term_memory")
            total_latency += long_term.get('latency_ms', 0)
        
        if graph and graph.get('relationships'):
            sources.append("graph_insights")
            total_latency += graph.get('latency_ms', 0)
        
        return {
            "sources": sources,
            "total_latency_ms": total_latency,
            "recent": recent,
            "short_term": short_term,
            "long_term": long_term,
            "graph": graph
        }
    
    async def _generate_response(self, query: str, context: Dict) -> str:
        """Generate response using LLM with combined context"""
        
        # Build context prompt
        context_prompt = self._build_context_prompt(context)
        
        # Generate response
        prompt = f"""
        Context from conversation:
        {context_prompt}
        
        User question: {query}
        
        Provide a helpful response based on the context above.
        """
        
        response = await self.llm.generate(prompt)
        return response
    
    def _build_context_prompt(self, context: Dict) -> str:
        """Build context prompt for LLM"""
        parts = []
        
        # Recent context
        if context.get('recent') and context['recent'].get('relevant_turns'):
            parts.append("Recent conversation (last 30 minutes):")
            for turn in context['recent']['relevant_turns'][-5:]:
                parts.append(f"  {turn['speaker']}: {turn['text']}")
        
        # Short-term context
        if context.get('short_term') and context['short_term'].get('relevant_summaries'):
            parts.append("\nConversation summary (last 2 hours):")
            for summary in context['short_term']['relevant_summaries']:
                parts.append(f"  - {summary.get('summary', '')}")
        
        # Long-term context
        if context.get('long_term'):
            if context['long_term'].get('semantic_results'):
                parts.append("\nRelevant past conversation segments:")
                for result in context['long_term']['semantic_results'][:3]:
                    parts.append(f"  - {result['chunk_text']}")
        
        # Graph insights
        if context.get('graph') and context['graph'].get('relationships'):
            parts.append("\nRelated entities and topics:")
            for rel in context['graph']['relationships'][:5]:
                parts.append(f"  - {rel}")
        
        return "\n".join(parts)
```

---

## Deployment Configuration

### Docker Compose Configuration

```yaml
# File: docker-compose.yml

version: '3.8'

services:
  # Pipecat agent
  pipecat-agent:
    build: ./agent
    environment:
      - REDIS_URL=redis://valkey:6379
      - POSTGRES_URL=postgresql://user:pass@postgres:5432/agora
      - GROQ_API_KEY=${GROQ_API_KEY}
      - CARTESIA_API_KEY=${CARTESIA_API_KEY}
    depends_on:
      - valkey
      - postgres
    deploy:
      replicas: 3
  
  # Valkey (Redis-compatible)
  valkey:
    image: valkey/valkey:latest
    ports:
      - "6379:6379"
    volumes:
      - valkey-data:/data
    command: valkey-server --maxmemory 8gb --maxmemory-policy allkeys-lru
  
  # PostgreSQL with pgvector and Apache AGE
  postgres:
    image: apache/age:latest
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=yourpassword
      - POSTGRES_DB=agora
    volumes:
      - postgres-data:/var/lib/postgresql/data
  
  # Background processors
  realtime-processor:
    build: ./processors
    command: python realtime_processor.py
    environment:
      - REDIS_URL=redis://valkey:6379
    depends_on:
      - valkey
  
  short-term-summarizer:
    build: ./processors
    command: python short_term_summarizer.py
    environment:
      - REDIS_URL=redis://valkey:6379
      - GROQ_API_KEY=${GROQ_API_KEY}
    depends_on:
      - valkey
  
  long-term-archiver:
    build: ./processors
    command: python long_term_archiver.py
    environment:
      - REDIS_URL=redis://valkey:6379
      - POSTGRES_URL=postgresql://user:pass@postgres:5432/agora
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - valkey
      - postgres
  
  graph-updater:
    build: ./processors
    command: python graph_updater.py
    environment:
      - POSTGRES_URL=postgresql://user:pass@postgres:5432/agora
    depends_on:
      - postgres

volumes:
  valkey-data:
  postgres-data:
```

### Fly.io Configuration (for Edge Valkey)

```toml
# File: fly.toml

app = "agora-valkey"
primary_region = "iad"  # Washington DC

[build]
  image = "valkey/valkey:latest"

[[services]]
  internal_port = 6379
  protocol = "tcp"

  [[services.ports]]
    port = 6379

[env]
  MAXMEMORY = "8gb"
  MAXMEMORY_POLICY = "allkeys-lru"

# Deploy to multiple regions for edge access
[[regions]]
  name = "iad"  # Washington DC (North America East)
  
[[regions]]
  name = "lax"  # Los Angeles (North America West)
  
[[regions]]
  name = "lhr"  # London (Europe)
  
[[regions]]
  name = "fra"  # Frankfurt (Europe)
  
[[regions]]
  name = "syd"  # Sydney (Asia-Pacific)

[metrics]
  port = 9091
  path = "/metrics"
```

---

## Cost Estimate

### Infrastructure Costs (1,000 Concurrent Users)

**Fly.io Valkey (Edge Redis):**
- 5 regions × 8 GB RAM = 40 GB total
- Cost: ~$200/month

**Pipecat Cloud:**
- 10,000 minutes/month
- Cost: $900/month

**Exoscale PostgreSQL:**
- Already deployed
- Cost: $800/month (included in existing infrastructure)

**Total: ~$1,900/month**

### Performance Targets

- Preload time: 200-400ms
- Query latency (90% of queries): <30ms
- Query latency (9% of queries): <200ms
- Query latency (1% of queries): <300ms
- Total response time: <350ms ✅

---

## Next Steps

1. **Set up development environment**
   - Clone repository
   - Install dependencies
   - Configure environment variables

2. **Deploy infrastructure**
   - Deploy Fly.io Valkey to 5 regions
   - Configure PostgreSQL with pgvector and Apache AGE
   - Set up Pipecat Cloud account

3. **Implement pipelines**
   - Real-time processor
   - Short-term summarizer
   - Long-term archiver
   - Graph updater

4. **Implement query strategies**
   - Recent context query
   - Short-term context query
   - Long-term context query
   - Graph insights query
   - Query orchestrator

5. **Build Pipecat agent**
   - Voice input/output
   - Context retrieval
   - LLM integration
   - Response generation

6. **Test and optimize**
   - Load testing
   - Latency optimization
   - Memory optimization
   - Cost optimization

**Ready to start implementation?**

