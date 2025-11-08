# 🎯 AI-Powered Support Intelligence Platform

> **An enterprise-grade automated customer support system that uses N8N, OpenAI, and Supabase to intelligently triage, route, and respond to customer inquiries at scale.**


## 🚀 Project Overview

### The Concept

An **Intelligent Support Triage System (ISTS)** that automatically:
- Receives customer support requests from multiple channels (email, Slack, web forms)
- Uses AI to analyze, categorize, and prioritize each ticket
- Routes tickets to the right team/agent based on expertise and workload
- Generates AI-assisted responses and auto-resolves simple issues
- Monitors SLA compliance and provides real-time analytics

### Core Features

**1. Multi-Channel Intake**
- Email (IMAP), Slack events, HTTP webhooks
- Automatic deduplication (prevents duplicate tickets)
- Spam detection with AI

**2. AI-Powered Analysis**
- Category classification (billing, technical, account, general)
- Sentiment analysis (angry, frustrated, neutral, happy)
- Priority scoring (urgent, high, medium, low)
- Intent extraction and escalation detection

**3. Smart Routing**
- Rule-based routing to appropriate teams
- Load balancing across available agents
- VIP customer escalation
- Auto-resolution for simple queries (password reset, invoice requests)

**4. Response Generation**
- AI-generated draft responses using GPT-4
- Knowledge base integration for accurate answers
- Human-in-the-loop approval for high-stakes responses
- Auto-send for high-confidence simple issues

**5. Monitoring & Analytics**
- SLA tracking with breach alerts
- Real-time dashboard metrics
- Daily performance reports
- AI accuracy monitoring

---

## 💎 Why This Stands Out

### For Hiring Managers, This Demonstrates:

**AI Engineering Excellence**
- Multi-model AI architecture (classification, sentiment, generation)
- Proper prompt engineering with context management
- Cost optimization strategies ($5/day for 1000 tickets)
- Error handling and fallback logic
- Quality monitoring and A/B testing

**Workflow Orchestration Mastery**
- Complex branching logic with conditional routing
- Parallel processing where appropriate
- Error recovery patterns with retry logic
- Idempotent operations (safe to re-run)
- Event-driven architecture

**Production-Ready Mindset**
- Comprehensive error handling
- Dead letter queue for failed operations
- Audit trails for compliance
- Rate limiting and abuse prevention
- Scalable database design

**Business Value Understanding**
- Clear ROI: 60-80% reduction in response time
- 30-40% auto-resolution rate
- SLA compliance >95%
- Cost-benefit analysis documented

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────┐
│         INTAKE CHANNELS                     │
│  Email │ Slack │ Web Forms │ API Webhooks   │
└────────┬────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│         N8N ORCHESTRATION LAYER             │
│  Workflow Engine (6 core workflows)         │
└────────┬────────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐  ┌────────────┐
│OpenAI │  │  Supabase  │
│  API  │  │ (Postgres) │
└───────┘  └────────────┘
              │
              ▼
        ┌─────────────┐
        │  OUTPUTS    │
        │ Slack, Email│
        │  Webhooks   │
        └─────────────┘
```

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Workflow Engine** | N8N (self-hosted or cloud) |
| **AI/ML** | OpenAI GPT-4o + GPT-4o-mini |
| **Database** | Supabase (managed Postgres) |
| **Notifications** | Slack API |
| **Email** | IMAP/SMTP |
| **Monitoring** | Database logging + optional Grafana |

---

## 🔄 N8N Workflow Design

### 6 Core Workflows

#### **Workflow 1: Ticket Intake** (12 nodes, ~2-3 hours)

**Triggers:**
- IMAP Email Trigger (polls every 2 min)
- Slack Event Trigger (#customer-support channel)
- Webhook (POST /api/tickets/create)

**Flow:**
```
Trigger → Normalize Input → Generate Hash → Check Duplicate
                                              ↓
                                         [If New]
                                              ↓
                                        Spam Check (AI)
                                              ↓
                                         [If Legit]
                                              ↓
                                      Create Ticket Record
                                              ↓
                                        Log Event
                                              ↓
                                    Trigger AI Triage
```

**Key Nodes:**
1. **Email Trigger**: IMAP connection to support@company.com
2. **Function - Normalize**: Converts all channels to standard format
3. **Function - Generate Hash**: SHA-256 of content for deduplication
4. **Postgres - Check Duplicate**: Query by hash within 24h window
5. **OpenAI - Spam Detection**: gpt-4o-mini, confidence >0.9
6. **Postgres - Create Ticket**: Insert with status='new'
7. **Postgres - Log Event**: Audit trail entry

**Error Handling:**
- Retry 3x with exponential backoff
- Dead letter queue for failures
- Slack alert on critical errors

---

#### **Workflow 2: AI Triage** (15 nodes, ~3-4 hours)

**Trigger:** Postgres trigger (new tickets) or N8N schedule polling

**Flow:**
```
New Ticket → Fetch Context → Build AI Context
                                  ↓
           ┌──────────────────────┼──────────────────┐
           ▼                      ▼                  ▼
    Classification          Sentiment           Priority
    (gpt-4o-mini)          (gpt-4o-mini)       (gpt-4o-mini)
           │                      │                  │
           └──────────────────────┴──────────────────┘
                                  ↓
                          Merge Results
                                  ↓
                         Store Analysis
                                  ↓
                        Update Ticket
                                  ↓
                       Trigger Routing
```

**AI Prompts (Simplified):**

**Classification:**
```
System: You are a ticket classifier. Categories: billing, technical, account, general.
Return JSON: { "category": "...", "sub_category": "...", "confidence": 0.95 }

User: Classify this ticket:
Subject: [subject]
Body: [body]
Customer History: [last 3 tickets]
```

**Sentiment:**
```
System: Analyze sentiment. Emotions: angry, frustrated, confused, neutral, satisfied, happy.
Intensity: 1-10 scale. Flag escalation if intensity >8 and negative.
Return JSON: { "emotion": "...", "intensity": 7, "escalation_needed": true }

User: Analyze: [ticket content]
```

**Priority:**
```
System: Score priority based on: business impact, customer tier, sentiment, urgency keywords.
Levels: urgent, high, medium, low
Return JSON: { "priority": "high", "urgency_score": 8, "reasoning": "..." }

User: Ticket: [content]
Sentiment: [emotion] (intensity: [X]/10)
Customer Tier: [tier]
```

**Parallel Processing**: All 3 AI calls run simultaneously, then merge results

---

#### **Workflow 3: Routing & Assignment** (10 nodes, ~2 hours)

**Flow:**
```
Analyzed Ticket → Check Auto-Resolve Eligibility
                           ↓
                    [If Simple + High Confidence]
                           ↓
                   Auto-Response → Send → Close

                    [If Needs Human]
                           ↓
                  Fetch Routing Rules
                           ↓
                  Check Escalation Flags
                           ↓
                  Find Available Agent
                           ↓
                    Assign Ticket
                           ↓
                  Notify via Slack
                           ↓
                   Start SLA Timer
```

**Auto-Resolve Criteria:**
```javascript
canAutoResolve = (
  confidence > 0.85 &&
  sub_category in ['password_reset', 'invoice_request', 'documentation'] &&
  sentiment_intensity < 7 &&
  body.length < 500
)
```

**Agent Selection Logic:**
```sql
-- Find least-loaded agent with matching skills
SELECT a.id, a.name, COUNT(t.id) as current_load
FROM agents a
LEFT JOIN tickets t ON t.assigned_to = a.id AND t.status IN ('assigned', 'in_progress')
WHERE a.team_id = [matched_team]
  AND a.is_available = true
  AND (a.skill_level = 'senior' OR [priority] != 'urgent')
GROUP BY a.id
ORDER BY current_load ASC, RANDOM()
LIMIT 1
```

**Slack Notification:**
```
🎫 New Ticket Assigned: #12345

From: John Doe (john@company.com)
Subject: Cannot log into account
Priority: High ⚠️
Category: account > cannot_login
Sentiment: frustrated (7/10)

AI Insights:
- Customer tried multiple password resets
- Third contact this week - needs escalation
- SLA Deadline: 4 hours

[View Ticket] [Reassign] [Escalate]
```

---

#### **Workflow 4: Response Generation** (13 nodes, ~3 hours)

**Flow:**
```
Request Response → Fetch Ticket + History → Search Knowledge Base
                                                    ↓
                                          Generate AI Response
                                          (gpt-4o, temp=0.7)
                                                    ↓
                                            Quality Check
                                                    ↓
                            ┌───────────────────────┴──────────────┐
                            ▼                                      ▼
                    [Auto-Approve]                      [Needs Review]
                            ↓                                      ↓
                    Send Immediately                      Save as Draft
                            ↓                                      ↓
                      Log Response                         Notify Agent
                            ↓
                  Schedule Follow-up (24h)
```

**AI Response Prompt:**
```
System: You are a customer support agent for [Company].
Personality: Friendly, empathetic, solution-oriented
Guidelines:
- Personalize with customer name
- Acknowledge their issue with empathy
- Provide clear, actionable solution
- Offer additional help
- 150-300 words

Structure:
1. Greeting
2. Acknowledgment
3. Solution/Next steps
4. Additional resources
5. Closing

User:
Customer: [name]
Ticket: [subject and body]
Sentiment: [emotion] (intensity: [X]/10)
Category: [category]
Customer History: [recent tickets]
Relevant KB: [articles]

Draft a response.
```

**Quality Checks Before Sending:**
```javascript
qualityChecks = {
  has_greeting: /^(hi|hello|dear)/i.test(response),
  has_closing: /(regards|best|thanks)/i.test(response),
  length_ok: response.length >= 150 && response.length <= 1000,
  no_placeholders: !response.includes('[INSERT'),
  mentions_name: response.includes(customerFirstName),
  no_unauthorized_promises: !response.match(/will refund|guarantee/)
}

if (allPass && confidence > 0.9) {
  sendImmediately()
} else {
  saveDraftForReview()
}
```

---

#### **Workflow 5: SLA Monitor** (8 nodes, ~1 hour)

**Trigger:** Schedule (every 5 minutes)

**Flow:**
```
Scheduled Run → Fetch Active Tickets with SLA
                        ↓
                [For Each Ticket]
                        ↓
               Calculate Time Remaining
                        ↓
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
    50% Time      80% Elapsed     100% Breach
        ↓               ↓               ↓
    Info Alert    Warning Alert   Critical Alert
        ↓               ↓               ↓
   Slack Notify   Slack + Email   Escalate + Log
```

**SLA Thresholds:**
- Urgent: 1h first response, 4h resolution
- High: 4h first response, 8h resolution
- Medium: 8h first response, 24h resolution
- Low: 24h first response, 72h resolution

---

#### **Workflow 6: Analytics & Reporting** (10 nodes, ~2 hours)

**Trigger:** Schedule (daily at 9 AM)

**Flow:**
```
Daily Trigger → Calculate Metrics → Aggregate by Category/Priority
                                              ↓
                                    Store in analytics_daily
                                              ↓
                                      Generate Report
                                              ↓
                                     Send to Slack
                                              ↓
                              [Optional: Export to Dashboard]
```

**Metrics Calculated:**
```sql
-- Daily aggregation query
WITH daily_stats AS (
  SELECT
    DATE(created_at) as date,
    COUNT(*) as total_tickets,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved,
    AVG(EXTRACT(EPOCH FROM (first_response_at - created_at))/60) as avg_first_response_min,
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours,
    COUNT(*) FILTER (WHERE sla_deadline < resolved_at) as sla_breaches,
    jsonb_object_agg(category, category_count) as by_category
  FROM tickets
  WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
  GROUP BY DATE(created_at)
)
SELECT * FROM daily_stats;
```

**Slack Report:**
```
📊 Daily Support Metrics - Dec 15, 2024

Total Tickets: 247
Resolved: 201 (81%)
Auto-Resolved: 95 (38%)

⏱️ Performance:
Avg First Response: 32 min
Avg Resolution: 4.2 hours

✅ SLA Compliance: 94%
❌ Breaches: 14 tickets

🔥 Top Issues:
1. billing > refund_request (43 tickets)
2. technical > bug_report (38 tickets)
3. account > password_reset (31 tickets)

🤖 AI Metrics:
Classification Accuracy: 92%
AI Responses Generated: 112
AI Responses Sent: 95 (85% approval rate)
Total AI Cost: $4.87

[View Full Dashboard →]
```

---

## 🤖 AI Logic & OpenAI Integration

### Model Selection Strategy

| Task | Model | Why | Cost per Call |
|------|-------|-----|---------------|
| Spam Detection | gpt-4o-mini | Fast, cheap, high accuracy | $0.0003 |
| Classification | gpt-4o-mini | Structured output, reliable | $0.0009 |
| Sentiment | gpt-4o-mini | Simple analysis | $0.0005 |
| Priority | gpt-4o-mini | Consistent scoring | $0.0007 |
| Response Gen | gpt-4o | Customer-facing, needs quality | $0.008 |
| KB Embeddings | text-embedding-3-small | One-time cost | $0.00002 |

**Daily Cost (1000 tickets):** ~$5.30/day = ~$160/month

### Error Handling & Fallbacks

```javascript
// Wrapper for all OpenAI calls
async function callOpenAI(config) {
  try {
    return await openai.chat.completions.create(config)
  } catch (error) {

    // Rate limit → retry with backoff
    if (error.code === 'rate_limit_error') {
      await sleep(Math.pow(2, attempt) * 1000)
      return retry()
    }

    // Context too long → truncate
    if (error.code === 'context_length_exceeded') {
      config.messages[1].content = truncate(config.messages[1].content, 0.7)
      return retry()
    }

    // API error → use fallback
    return fallbackClassification(ticket)
  }
}

// Rule-based fallback
function fallbackClassification(ticket) {
  const text = (ticket.subject + ' ' + ticket.body).toLowerCase()

  if (text.match(/refund|charge|payment|invoice/))
    return { category: 'billing', confidence: 0.6 }
  if (text.match(/bug|error|broken|crash/))
    return { category: 'technical', confidence: 0.6 }
  if (text.match(/password|login|access/))
    return { category: 'account', confidence: 0.6 }

  return { category: 'general', confidence: 0.5 }
}
```

### Cost Optimization

**1. Caching Similar Tickets:**
```javascript
// Hash ticket content, check if analyzed in last 24h
const hash = sha256(ticket.subject + ticket.body.substring(0, 200))
const cached = await db.query(
  'SELECT * FROM ai_analysis WHERE content_hash = $1 AND created_at > NOW() - INTERVAL \'24 hours\'',
  [hash]
)
if (cached.rows.length > 0) return cached.rows[0] // Reuse
```

**2. Batch Processing:**
- Process 10 tickets at once when load is high
- Reduces API overhead

**3. Smart Model Selection:**
- Use gpt-4o-mini for all classification tasks (60x cheaper than GPT-4)
- Reserve gpt-4o only for customer-facing responses

---

## 🗄️ Database Schema

### Core Tables (Postgres/Supabase)

#### **1. tickets** (Main table)
```sql
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key VARCHAR(64) UNIQUE NOT NULL, -- Deduplication

  -- Source
  channel VARCHAR(20) NOT NULL, -- email, slack, api, web
  sender_email VARCHAR(255) NOT NULL,
  sender_name VARCHAR(255),

  -- Content
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  attachments JSONB DEFAULT '[]',

  -- Classification
  category VARCHAR(50), -- billing, technical, account, general
  sub_category VARCHAR(50),
  tags TEXT[],

  -- Status
  status VARCHAR(30) DEFAULT 'new', -- new, analyzing, analyzed, assigned, in_progress, resolved, closed
  priority VARCHAR(20) DEFAULT 'medium', -- urgent, high, medium, low

  -- Assignment
  assigned_to UUID REFERENCES agents(id),
  assigned_at TIMESTAMP WITH TIME ZONE,
  team_id UUID REFERENCES teams(id),

  -- SLA
  sla_deadline TIMESTAMP WITH TIME ZONE,
  first_response_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,

  -- Flags
  is_spam BOOLEAN DEFAULT false,
  is_escalated BOOLEAN DEFAULT false,

  -- Metadata
  raw_metadata JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_sla_deadline ON tickets(sla_deadline) WHERE status NOT IN ('resolved', 'closed');
```

#### **2. ai_analysis** (AI outputs)
```sql
CREATE TABLE ai_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,

  -- Classification
  category VARCHAR(50) NOT NULL,
  sub_category VARCHAR(50),
  confidence NUMERIC(3,2) NOT NULL, -- 0.00 to 1.00

  -- Sentiment
  sentiment_emotion VARCHAR(30),
  sentiment_intensity INTEGER CHECK (sentiment_intensity BETWEEN 1 AND 10),

  -- Priority
  priority_recommendation VARCHAR(20),
  urgency_score INTEGER,
  escalation_flag BOOLEAN DEFAULT false,

  -- AI reasoning (for transparency)
  reasoning JSONB,

  -- Model info
  model_name VARCHAR(100),
  prompt_tokens INTEGER,
  completion_tokens INTEGER,
  total_cost NUMERIC(10,6),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **3. ticket_events** (Audit trail)
```sql
CREATE TABLE ticket_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,

  event_type VARCHAR(50) NOT NULL, -- created, analyzed, assigned, status_changed, etc.
  event_data JSONB,

  actor_type VARCHAR(20), -- system, ai, agent, customer
  actor_id UUID,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ticket_events_ticket_id ON ticket_events(ticket_id, created_at DESC);
```

#### **4. agents**
```sql
CREATE TABLE agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,

  team_id UUID REFERENCES teams(id),
  role VARCHAR(50) DEFAULT 'agent', -- agent, senior_agent, manager
  skill_level VARCHAR(20) DEFAULT 'mid', -- junior, mid, senior, expert

  specializations TEXT[], -- ['billing', 'technical']
  max_concurrent_tickets INTEGER DEFAULT 10,

  is_available BOOLEAN DEFAULT true,
  slack_user_id VARCHAR(50),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **5. teams**
```sql
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  handles_categories TEXT[], -- ['billing', 'technical']
  slack_channel_id VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed data
INSERT INTO teams (name, handles_categories, slack_channel_id) VALUES
  ('Billing Team', ARRAY['billing'], 'C01234ABC'),
  ('Technical Support', ARRAY['technical'], 'C01234DEF'),
  ('Account Management', ARRAY['account'], 'C01234GHI'),
  ('General Support', ARRAY['general'], 'C01234JKL');
```

#### **6. routing_rules**
```sql
CREATE TABLE routing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,

  -- Match criteria
  category VARCHAR(50),
  priority VARCHAR(20),

  -- Target
  team_id UUID REFERENCES teams(id),

  rule_priority INTEGER DEFAULT 100, -- Lower = higher priority
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **7. sla_tracking**
```sql
CREATE TABLE sla_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,

  priority VARCHAR(20) NOT NULL,
  first_response_deadline TIMESTAMP WITH TIME ZONE NOT NULL,
  resolution_deadline TIMESTAMP WITH TIME ZONE NOT NULL,

  status VARCHAR(20) DEFAULT 'active', -- active, met, breached

  alert_50_sent BOOLEAN DEFAULT false,
  alert_80_sent BOOLEAN DEFAULT false,
  breach_alert_sent BOOLEAN DEFAULT false,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **8. responses**
```sql
CREATE TABLE responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,

  direction VARCHAR(20) NOT NULL, -- outbound, inbound
  channel VARCHAR(20) NOT NULL,
  body TEXT NOT NULL,

  sender_type VARCHAR(20), -- agent, customer, ai
  sender_id UUID,

  was_ai_generated BOOLEAN DEFAULT false,
  ai_draft BOOLEAN DEFAULT false, -- Saved for review vs sent

  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **9. error_logs**
```sql
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  workflow_name VARCHAR(100),
  node_name VARCHAR(100),
  error_type VARCHAR(100),
  error_message TEXT,

  ticket_id UUID REFERENCES tickets(id),
  severity VARCHAR(20) DEFAULT 'error',

  resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **10. analytics_daily**
```sql
CREATE TABLE analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE UNIQUE NOT NULL,

  total_tickets INTEGER,
  tickets_resolved INTEGER,
  tickets_auto_resolved INTEGER,

  avg_first_response_minutes NUMERIC(10,2),
  avg_resolution_hours NUMERIC(10,2),

  sla_compliance_rate NUMERIC(5,2),
  sla_breaches INTEGER,

  tickets_by_category JSONB,
  tickets_by_priority JSONB,

  ai_classification_accuracy NUMERIC(5,2),
  total_ai_cost NUMERIC(10,4),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Useful Views

```sql
-- Active tickets with AI analysis
CREATE VIEW active_tickets_view AS
SELECT
  t.*,
  a.category as ai_category,
  a.confidence,
  a.sentiment_emotion,
  ag.name as agent_name
FROM tickets t
LEFT JOIN ai_analysis a ON a.ticket_id = t.id
LEFT JOIN agents ag ON ag.id = t.assigned_to
WHERE t.status NOT IN ('resolved', 'closed')
ORDER BY t.priority, t.created_at;

-- Agent workload
CREATE VIEW agent_workload AS
SELECT
  a.id,
  a.name,
  COUNT(t.id) as current_tickets,
  a.max_concurrent_tickets - COUNT(t.id) as capacity_remaining
FROM agents a
LEFT JOIN tickets t ON t.assigned_to = a.id AND t.status IN ('assigned', 'in_progress')
GROUP BY a.id
ORDER BY current_tickets DESC;
```

---

## 📋 Step-by-Step Build Plan

### Phase 1: Foundation (3-4 hours)

**Step 1.1: Set Up Infrastructure** (30 min)
- [ ] Create Supabase project (or local Postgres)
- [ ] Set up N8N instance (Docker or n8n.cloud)
- [ ] Create OpenAI API account, get API key
- [ ] Set up Slack workspace and create test channel

**Step 1.2: Create Database Schema** (1 hour)
- [ ] Run SQL to create all tables (tickets, ai_analysis, agents, teams, etc.)
- [ ] Insert seed data (teams, initial agent, routing rules)
- [ ] Test queries in Supabase SQL editor
- [ ] Set up indexes for performance

**Step 1.3: Configure N8N Credentials** (30 min)
- [ ] Add Supabase credentials (host, database, user, password)
- [ ] Add OpenAI API key
- [ ] Add Slack bot token
- [ ] Add email credentials (IMAP/SMTP)
- [ ] Test each connection

**Step 1.4: Create Test Data Generator** (1 hour)
- [ ] Write simple script to generate fake tickets
- [ ] Include various categories, priorities, sentiments
- [ ] Have 20-30 test tickets ready

---

### Phase 2: Core Workflows (6-8 hours)

**Step 2.1: Build Ticket Intake Workflow** (2-3 hours)
- [ ] Create new N8N workflow named "01-ticket-intake"
- [ ] Add webhook trigger (test with Postman/curl)
- [ ] Add function node to normalize input
- [ ] Add function to generate idempotency hash
- [ ] Add Postgres node to check duplicates
- [ ] Add OpenAI node for spam detection
- [ ] Add Postgres node to create ticket record
- [ ] Add Postgres node to log event
- [ ] Test end-to-end with test data
- [ ] Add error handling nodes

**Step 2.2: Build AI Triage Workflow** (3-4 hours)
- [ ] Create workflow "02-ai-triage"
- [ ] Add trigger (webhook or polling Postgres for new tickets)
- [ ] Add Postgres node to fetch ticket details
- [ ] Add 3 OpenAI nodes in parallel:
  - [ ] Classification node
  - [ ] Sentiment analysis node
  - [ ] Priority scoring node
- [ ] Add function node to merge results
- [ ] Add Postgres node to store analysis
- [ ] Add Postgres node to update ticket status
- [ ] Test with various ticket types
- [ ] Verify AI outputs are sensible

**Step 2.3: Build Routing Workflow** (2 hours)
- [ ] Create workflow "03-routing-assignment"
- [ ] Add trigger for analyzed tickets
- [ ] Add function to check auto-resolve eligibility
- [ ] Add IF node to branch
- [ ] Add Postgres query to fetch routing rules
- [ ] Add Postgres query to find available agent
- [ ] Add Postgres update to assign ticket
- [ ] Add Slack notification node
- [ ] Add Postgres insert for SLA tracking
- [ ] Test assignment logic

**Step 2.4: Build Response Generation Workflow** (2-3 hours)
- [ ] Create workflow "04-response-generation"
- [ ] Add manual trigger (button in N8N)
- [ ] Add Postgres fetch ticket + history
- [ ] Add OpenAI node for response generation (GPT-4)
- [ ] Add function for quality checks
- [ ] Add IF node for auto-approve vs draft
- [ ] Add email send node
- [ ] Add Postgres insert for response record
- [ ] Test response quality

---

### Phase 3: Monitoring & Analytics (2-3 hours)

**Step 3.1: Build SLA Monitor** (1 hour)
- [ ] Create workflow "05-sla-monitor"
- [ ] Add schedule trigger (every 5 min)
- [ ] Add Postgres query for active SLA tracking
- [ ] Add loop node to check each ticket
- [ ] Add function to calculate time remaining
- [ ] Add IF nodes for alert thresholds (50%, 80%, 100%)
- [ ] Add Slack alert nodes
- [ ] Test with backdated tickets

**Step 3.2: Build Analytics Workflow** (2 hours)
- [ ] Create workflow "06-analytics-reporting"
- [ ] Add schedule trigger (daily at 9 AM)
- [ ] Add Postgres query for daily metrics
- [ ] Add function to format report
- [ ] Add Slack message node
- [ ] Add Postgres insert to analytics_daily
- [ ] Test with historical data

---

### Phase 4: Testing & Polish (2-3 hours)

**Step 4.1: End-to-End Testing** (1 hour)
- [ ] Send 10 test tickets through the system
- [ ] Verify each stage (intake → triage → routing → response)
- [ ] Check database records at each step
- [ ] Test error scenarios (invalid data, API failures)

**Step 4.2: Performance Optimization** (1 hour)
- [ ] Review workflow execution times
- [ ] Add missing indexes to database
- [ ] Optimize Postgres queries
- [ ] Add caching where appropriate

**Step 4.3: Documentation** (1 hour)
- [ ] Document each workflow's purpose
- [ ] Create troubleshooting guide
- [ ] Write deployment instructions
- [ ] Create demo video/screenshots

---

### Timeline Summary

| Phase | Time | Cumulative |
|-------|------|------------|
| Foundation | 3-4 hours | 3-4 hours |
| Core Workflows | 6-8 hours | 9-12 hours |
| Monitoring | 2-3 hours | 11-15 hours |
| Testing & Polish | 2-3 hours | **13-18 hours total** |

**Realistic Build Time:** 2-3 full days of focused work

---

## 🚀 Stretch Goals

If you finish early or want to make it extra impressive:

### Level 1: Enhanced Features (2-4 hours each)

**1. Multi-Language Support**
- Detect customer language with OpenAI
- Auto-translate to English for processing
- Respond in customer's original language
- Store translations in database

**2. Knowledge Base with RAG**
- Create KB articles table with embeddings
- Use OpenAI embeddings (text-embedding-3-small)
- Implement vector similarity search (pgvector)
- Inject relevant KB articles into AI context

**3. Customer Portal**
- Simple Next.js/React frontend
- Submit tickets via web form
- View ticket status and history
- Webhook to N8N on submission

**4. Advanced Analytics Dashboard**
- Set up Metabase or Grafana
- Connect to Supabase database
- Create charts: tickets over time, category breakdown, SLA compliance
- Agent performance leaderboard

**5. Sentiment Trend Analysis**
- Track sentiment changes over time
- Alert if negative sentiment spike detected
- Identify products/features causing issues
- Proactive reach-out to frustrated customers

### Level 2: Production Features (4-6 hours each)

**6. A/B Testing Framework**
- Test different AI prompts
- Track which performs better
- Automatically promote winning variant
- Store test results in database

**7. Agent Performance Metrics**
- Track: avg resolution time, customer satisfaction, tickets handled
- Leaderboard in Slack
- Coaching recommendations based on data

**8. Smart Ticket Merging**
- Detect duplicate/related tickets from same customer
- Suggest merging to agent
- Link related tickets automatically

**9. Proactive Outreach**
- Detect customers with multiple unresolved issues
- Auto-escalate to account manager
- Generate personalized "check-in" email

**10. Voice/Phone Integration**
- Integrate Twilio for phone support
- Transcribe calls with Whisper API
- Create tickets from phone calls
- Same AI triage process

### Level 3: Enterprise Features (1-2 days each)

**11. Multi-Tenant Architecture**
- Support multiple companies in one system
- Row-level security in Supabase
- Separate Slack workspaces per tenant
- White-label customization

**12. Custom ML Model**
- Fine-tune GPT-4 on your historical tickets
- Compare performance vs base model
- Document cost/accuracy tradeoffs

**13. Compliance & Security**
- PII detection and redaction
- GDPR compliance (data export, deletion)
- SOC 2 audit logging
- Encryption at rest

---

## 🎯 Portfolio Deliverables

### What to Include in Your Portfolio

**1. README.md** (This file)
- Complete project overview
- Clear problem statement
- Technical architecture
- Build instructions

**2. Demo Video** (5-10 minutes)
- Show ticket coming in via email
- Watch AI analyze it in real-time
- See routing and Slack notification
- Show AI-generated response
- Walk through analytics dashboard
- Highlight error handling

**3. Architecture Diagram**
- Visual system architecture (use Excalidraw, Figma, or Mermaid)
- Data flow diagram
- N8N workflow screenshots

**4. Code Repository**
- N8N workflow JSON exports (all 6 workflows)
- Database schema SQL files
- Seed data scripts
- Test data generator
- README with setup instructions

**5. Metrics & Results**
- Screenshots of Slack notifications
- Database query results showing data
- Analytics dashboard screenshots
- Example AI classifications with confidence scores
- Cost breakdown and ROI analysis

**6. Technical Blog Post** (Optional but impressive)
- Write detailed article on DEV.to or Medium
- "Building a Production-Ready AI Support System"
- Cover challenges faced and solutions
- Share lessons learned

### Talking Points for Interviews

**When discussing this project:**

✅ "I built an intelligent support triage system that reduces response time by 60-80% using N8N, OpenAI, and Supabase"

✅ "The system processes 1000+ tickets/day with 92% AI classification accuracy, auto-resolving 30-40% of simple issues"

✅ "I implemented comprehensive error handling with fallback logic - if OpenAI fails, it degrades gracefully to rule-based classification"

✅ "Cost optimization was key - I used gpt-4o-mini for classification tasks (60x cheaper) and reserved GPT-4 only for customer-facing responses, keeping costs under $5/day"

✅ "The architecture is production-ready with idempotent operations, audit trails, SLA monitoring, and dead letter queues"

✅ "I designed a scalable database schema with proper indexing that can handle millions of tickets"

✅ "The AI logic includes quality monitoring - agents can provide feedback on classifications, and I track accuracy over time"

### What Makes This Portfolio-Ready

1. **Real Business Value**: Solves actual pain point (support backlog)
2. **Technical Depth**: Multi-model AI, complex workflows, production patterns
3. **Production Mindset**: Error handling, monitoring, cost optimization
4. **Scalable Design**: Can grow from 100 to 100,000 tickets/day
5. **Clear Documentation**: Anyone can understand and reproduce it
6. **Measurable Impact**: Concrete metrics (response time, auto-resolution rate)
7. **Demonstrates Learning**: Shows understanding of AI limitations and mitigations

---

## 🚦 Getting Started Now

### Quick Start Checklist

1. **Immediate Next Steps:**
   ```bash
   # 1. Clone or create project directory
   mkdir intelligent-support-system && cd intelligent-support-system

   # 2. Set up Supabase (or local Postgres)
   # → Go to supabase.com, create free project

   # 3. Set up N8N
   # Option A: Cloud (easiest)
   # → Go to n8n.cloud, create account

   # Option B: Docker (local)
   docker run -it --rm \
     --name n8n \
     -p 5678:5678 \
     -v ~/.n8n:/home/node/.n8n \
     n8nio/n8n

   # 4. Get OpenAI API key
   # → Go to platform.openai.com, create API key
   ```

2. **Copy Database Schema:**
   - Copy all CREATE TABLE statements from "Database Schema" section
   - Run in Supabase SQL Editor
   - Verify tables created successfully

3. **Start with Workflow 1:**
   - Open N8N
   - Create new workflow "01-ticket-intake"
   - Follow build plan step-by-step
   - Test each node as you add it

4. **Test Early, Test Often:**
   - Don't wait until everything is built
   - Test each workflow independently
   - Use sample data provided

---

## 📞 Support & Questions

If you encounter issues:
- Check N8N documentation: https://docs.n8n.io
- OpenAI API docs: https://platform.openai.com/docs
- Supabase docs: https://supabase.com/docs

Common issues:
- **OpenAI rate limits**: Add retry logic, use exponential backoff
- **N8N workflow timeout**: Increase timeout in settings, optimize queries
- **Postgres connection fails**: Check firewall, verify credentials

---

## 📄 License

MIT License - Free to use in your portfolio and adapt for projects.

---

**Built to demonstrate production-ready AI automation engineering. Good luck with your portfolio!**
