# N8N Workflow Setup Guide

Step-by-step instructions for building all 6 workflows in N8N.

---

## Prerequisites

- N8N instance running (cloud or local)
- Credentials configured in N8N:
  - PostgreSQL (Supabase)
  - OpenAI API
  - Slack (optional)
  - Email IMAP/SMTP (optional)

---

## Adding Credentials in N8N

### 1. PostgreSQL / Supabase

1. Click **Settings** (gear icon) → **Credentials**
2. Click **Add Credential** → Search "Postgres"
3. Fill in:
   - **Name**: Supabase Production
   - **Host**: `db.your-project.supabase.co`
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: Your Supabase password
   - **Port**: `5432`
   - **SSL**: Enable
4. Click **Save**

### 2. OpenAI

1. **Add Credential** → Search "OpenAI"
2. Fill in:
   - **Name**: OpenAI Production
   - **API Key**: `sk-proj-...`
3. Click **Save**

### 3. Slack (Optional)

1. **Add Credential** → Search "Slack OAuth2 API"
2. Get bot token from: https://api.slack.com/apps
3. Fill in:
   - **Name**: Slack Bot
   - **Access Token**: `xoxb-...`
4. Click **Save**

---

## Workflow 1: Ticket Intake

**Purpose**: Receive tickets from webhook, normalize data, check duplicates, detect spam, create ticket record.

### Node Configuration

#### Node 1: Webhook Trigger

1. Add node: **Webhook**
2. Settings:
   - **HTTP Method**: POST
   - **Path**: `/ticket-intake`
   - **Authentication**: None (for testing) or Header Auth (production)
   - **Response**: `{{ $json }}`
3. **Save Workflow** - Copy the webhook URL
4. Test URL: `https://your-n8n.cloud/webhook/ticket-intake`

#### Node 2: Function - Normalize Input

1. Add node: **Function**
2. Name: `Normalize Input`
3. Code:
```javascript
const input = $input.all()[0].json;
let normalized = {
  channel: 'api', // default
  sender_email: '',
  sender_name: '',
  subject: '',
  body: '',
  received_at: new Date().toISOString()
};

// Check if email format
if (input.from && input.subject) {
  normalized.channel = 'email';
  normalized.sender_email = input.from;
  normalized.sender_name = input.from.split('<')[0].trim();
  normalized.subject = input.subject;
  normalized.body = input.text || input.html;
}
// Webhook/API format
else {
  normalized.channel = 'api';
  normalized.sender_email = input.email;
  normalized.sender_name = input.name;
  normalized.subject = input.subject;
  normalized.body = input.message;
}

return normalized;
```

#### Node 3: Function - Generate Hash

1. Add node: **Function**
2. Name: `Generate Idempotency Hash`
3. Code:
```javascript
const crypto = require('crypto');
const content = `${$json.sender_email}::${$json.subject}::${$json.body.substring(0, 200)}`;
const hash = crypto.createHash('sha256').update(content).digest('hex');

return {
  ...$json,
  idempotency_key: hash
};
```

#### Node 4: Postgres - Check Duplicate

1. Add node: **Postgres**
2. Name: `Check for Duplicates`
3. Credential: Select your Supabase credential
4. Operation: **Execute Query**
5. Query:
```sql
SELECT id, status
FROM tickets
WHERE idempotency_key = '{{ $json.idempotency_key }}'
  AND created_at > NOW() - INTERVAL '24 hours'
LIMIT 1
```

#### Node 5: IF - Duplicate Check

1. Add node: **IF**
2. Name: `Is Duplicate?`
3. Conditions:
   - **Value 1**: `{{ $json.id }}`
   - **Operation**: is not empty
   - **Value 2**: (leave blank)
4. Connect:
   - **TRUE** → Stop & Return (end workflow)
   - **FALSE** → Continue to spam check

#### Node 6: OpenAI - Spam Detection

1. Add node: **OpenAI**
2. Name: `AI Spam Detection`
3. Credential: Select OpenAI credential
4. Resource: **Text**
5. Operation: **Message a Model**
6. Model: `gpt-4o-mini`
7. System Message:
```
You are a spam detection system. Analyze emails and return JSON.
Return format: {"is_spam": boolean, "confidence": number, "reason": "string"}
```
8. User Message:
```
From: {{ $json.sender_email }}
Subject: {{ $json.subject }}
Body: {{ $json.body }}

Is this spam?
```
9. Temperature: `0.2`
10. Response Format: **JSON**

#### Node 7: IF - Spam Check

1. Add node: **IF**
2. Name: `Is Spam?`
3. Conditions:
   - **Value 1**: `{{ $json.is_spam }}`
   - **Operation**: equals
   - **Value 2**: `true`
   - **AND**
   - **Value 1**: `{{ $json.confidence }}`
   - **Operation**: larger than
   - **Value 2**: `0.9`
4. Connect:
   - **TRUE** → Stop (skip creating ticket)
   - **FALSE** → Create ticket

#### Node 8: Postgres - Create Ticket

1. Add node: **Postgres**
2. Name: `Create Ticket`
3. Operation: **Insert**
4. Table: `tickets`
5. Columns:
```
idempotency_key: {{ $json.idempotency_key }}
channel: {{ $json.channel }}
sender_email: {{ $json.sender_email }}
sender_name: {{ $json.sender_name }}
subject: {{ $json.subject }}
body: {{ $json.body }}
status: new
priority: medium
raw_metadata: {{ JSON.stringify($json) }}
```
6. Return Fields: `id, created_at`

#### Node 9: Postgres - Log Event

1. Add node: **Postgres**
2. Name: `Log Ticket Created`
3. Operation: **Insert**
4. Table: `ticket_events`
5. Columns:
```
ticket_id: {{ $json.id }}
event_type: created
event_data: {"channel": "{{ $json.channel }}"}
actor_type: system
```

#### Node 10: Webhook Response

1. Add node: **Respond to Webhook**
2. Status Code: `201`
3. Body:
```json
{
  "success": true,
  "ticket_id": "{{ $node['Create Ticket'].json.id }}",
  "status": "created"
}
```

### Error Handling

1. Add node: **Error Trigger**
2. Connect it to catch errors from all nodes
3. Add node: **Postgres** → Insert into `error_logs`
4. Add node: **Slack** → Send alert to #engineering-alerts

---

## Workflow 2: AI Triage

**Purpose**: Analyze ticket with AI (classification, sentiment, priority), store results, update ticket.

### Node Configuration

#### Node 1: Trigger - Webhook or Postgres Polling

Option A: Webhook (simpler for testing)
1. Add node: **Webhook**
2. Path: `/ai-triage`
3. Method: POST
4. Body should contain: `{ "ticket_id": "uuid" }`

Option B: Postgres Polling (production)
1. Add node: **Schedule Trigger**
2. Interval: Every 30 seconds
3. Then add **Postgres** → Query for new tickets

#### Node 2: Postgres - Fetch Ticket

1. Add node: **Postgres**
2. Name: `Fetch Ticket Details`
3. Query:
```sql
SELECT * FROM tickets WHERE id = '{{ $json.ticket_id }}' AND status = 'new'
```

#### Node 3: OpenAI - Classification

1. Add node: **OpenAI**
2. Name: `AI Classification`
3. Model: `gpt-4o-mini`
4. System Message:
```
You are a ticket classifier. Categories: billing, technical, account, general.
Return JSON: {"category": "...", "sub_category": "...", "confidence": 0.95, "reasoning": "..."}
```
5. User Message:
```
Subject: {{ $json.subject }}
Body: {{ $json.body }}

Classify this ticket.
```
6. Temperature: `0.2`
7. Response Format: **JSON**

#### Node 4: OpenAI - Sentiment

1. Add node: **OpenAI**
2. Name: `AI Sentiment Analysis`
3. Model: `gpt-4o-mini`
4. System Message:
```
Analyze sentiment. Emotions: angry, frustrated, confused, neutral, satisfied, happy.
Intensity: 1-10. Flag escalation if intensity >8.
Return JSON: {"emotion": "...", "intensity": 7, "escalation_needed": false}
```
5. User Message:
```
{{ $json.body }}
```

#### Node 5: OpenAI - Priority

1. Add node: **OpenAI**
2. Name: `AI Priority Scoring`
3. Model: `gpt-4o-mini`
4. System Message:
```
Determine priority: urgent, high, medium, low.
Return JSON: {"priority": "high", "urgency_score": 8, "reasoning": "..."}
```
5. User Message:
```
Ticket: {{ $json.subject }}
Body: {{ $json.body }}
Sentiment: {{ $node["AI Sentiment Analysis"].json.emotion }}
```

**Note**: Nodes 3, 4, 5 can run in **parallel**. After OpenAI nodes, add **Merge** node.

#### Node 6: Function - Merge Results

1. Add node: **Function**
2. Name: `Merge AI Results`
3. Code:
```javascript
const ticket = $node["Fetch Ticket Details"].json;
const classification = $node["AI Classification"].json;
const sentiment = $node["AI Sentiment Analysis"].json;
const priority = $node["AI Priority Scoring"].json;

return {
  ticket_id: ticket.id,
  category: classification.category,
  sub_category: classification.sub_category,
  confidence: classification.confidence,
  sentiment_emotion: sentiment.emotion,
  sentiment_intensity: sentiment.intensity,
  escalation_flag: sentiment.escalation_needed || priority.priority === 'urgent',
  priority: priority.priority,
  urgency_score: priority.urgency_score,
  reasoning: {
    classification: classification.reasoning,
    priority: priority.reasoning
  }
};
```

#### Node 7: Postgres - Store Analysis

1. Add node: **Postgres**
2. Name: `Store AI Analysis`
3. Operation: **Insert**
4. Table: `ai_analysis`
5. Columns:
```
ticket_id: {{ $json.ticket_id }}
category: {{ $json.category }}
sub_category: {{ $json.sub_category }}
confidence: {{ $json.confidence }}
sentiment_emotion: {{ $json.sentiment_emotion }}
sentiment_intensity: {{ $json.sentiment_intensity }}
escalation_flag: {{ $json.escalation_flag }}
priority_recommendation: {{ $json.priority }}
model_name: gpt-4o-mini
reasoning: {{ JSON.stringify($json.reasoning) }}
```

#### Node 8: Postgres - Update Ticket

1. Add node: **Postgres**
2. Name: `Update Ticket Status`
3. Operation: **Update**
4. Table: `tickets`
5. Update Key: `id`
6. Update Value: `{{ $json.ticket_id }}`
7. Columns:
```
status: analyzed
category: {{ $json.category }}
priority: {{ $json.priority }}
```

---

## Workflow 3: Routing & Assignment

**Purpose**: Route analyzed tickets to teams, find available agents, assign, send notifications, start SLA tracking.

### Key Nodes

#### Node 1: Postgres - Fetch Analyzed Tickets

```sql
SELECT t.*, a.*
FROM tickets t
JOIN ai_analysis a ON a.ticket_id = t.id
WHERE t.status = 'analyzed'
LIMIT 10
```

#### Node 2: Function - Check Auto-Resolve

```javascript
const canAutoResolve = (
  $json.confidence > 0.85 &&
  ['password_reset', 'invoice_request'].includes($json.sub_category) &&
  $json.sentiment_intensity < 7
);

return { ...$json, can_auto_resolve: canAutoResolve };
```

#### Node 3: Postgres - Find Available Agent

```sql
SELECT a.id, a.name, COUNT(t.id) as current_load
FROM agents a
LEFT JOIN tickets t ON t.assigned_to = a.id AND t.status IN ('assigned', 'in_progress')
WHERE a.team_id IN (
  SELECT team_id FROM routing_rules
  WHERE category = '{{ $json.category }}'
  AND is_active = true
  LIMIT 1
)
AND a.is_available = true
GROUP BY a.id
ORDER BY current_load ASC
LIMIT 1
```

#### Node 4: Postgres - Assign Ticket

```sql
UPDATE tickets
SET assigned_to = '{{ $json.agent_id }}',
    assigned_at = NOW(),
    status = 'assigned'
WHERE id = '{{ $json.ticket_id }}'
```

#### Node 5: Slack - Notify Agent

```
🎫 New Ticket Assigned: #{{ $json.ticket_id }}

From: {{ $json.sender_name }}
Subject: {{ $json.subject }}
Priority: {{ $json.priority }} ⚠️
Category: {{ $json.category }}

View ticket: [link]
```

---

## Workflow 4: Response Generation

Simpler for MVP - manual trigger by agent.

### Key Nodes

1. **Manual Trigger** or **Webhook**
2. **Postgres** → Fetch ticket + history
3. **OpenAI** → Generate response (GPT-4)
4. **Function** → Quality checks
5. **IF** → Auto-send or save draft
6. **Email** → Send if approved

---

## Workflow 5: SLA Monitor

### Simple Version

1. **Schedule Trigger** (every 5 minutes)
2. **Postgres** → Query:
```sql
SELECT * FROM sla_tracking WHERE status = 'active'
```
3. **Function** → Calculate time remaining
4. **IF** → Check thresholds (50%, 80%, 100%)
5. **Slack** → Send alerts

---

## Workflow 6: Analytics

### Simple Version

1. **Schedule Trigger** (daily at 9 AM)
2. **Postgres** → Aggregate metrics:
```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE status = 'resolved') as resolved,
  AVG(EXTRACT(EPOCH FROM (first_response_at - created_at))/60) as avg_response_min
FROM tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
```
3. **Function** → Format report
4. **Slack** → Send daily summary

---

## Testing Your Workflows

### Test Ticket Intake

```bash
curl -X POST https://your-n8n.cloud/webhook/ticket-intake \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "subject": "Cannot log into account",
    "message": "I forgot my password and the reset email is not arriving. Please help!"
  }'
```

### Verify in Database

```sql
SELECT * FROM tickets ORDER BY created_at DESC LIMIT 5;
SELECT * FROM ai_analysis ORDER BY created_at DESC LIMIT 5;
SELECT * FROM ticket_events ORDER BY created_at DESC LIMIT 10;
```

---

## Tips

1. **Start Simple**: Build workflow 1 completely before moving to workflow 2
2. **Test Each Node**: Use the "Execute Node" button to test individually
3. **Use Console Logs**: Add `console.log()` in Function nodes for debugging
4. **Save Often**: N8N auto-saves, but manually save before major changes
5. **Use Sticky Notes**: Add notes in N8N canvas to document logic

---

## Common Issues

### "Cannot connect to database"
- Check credentials in N8N settings
- Verify Supabase connection allows external connections
- Check if IP is whitelisted (Supabase → Settings → Database → Connection Pooling)

### "OpenAI API error"
- Verify API key is correct
- Check billing/credits on OpenAI account
- Try with simpler prompt first

### "Workflow times out"
- Increase timeout in N8N settings (Settings → Workflows → Timeout)
- Optimize slow Postgres queries with indexes
- Use async processing for long-running tasks

---

**Next**: Test end-to-end by sending a ticket and watching it flow through all workflows!
