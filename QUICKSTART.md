# 🚀 Quick Start Guide

Get the Intelligent Support Triage System running in 30 minutes.

---

## What You'll Need

- **Supabase Account** (free tier works) - [supabase.com](https://supabase.com)
- **OpenAI API Key** - [platform.openai.com](https://platform.openai.com)
- **N8N Account** (cloud or local) - [n8n.cloud](https://n8n.cloud) or Docker
- **Optional**: Slack workspace (for notifications)

---

## Step 1: Database Setup (5 minutes)

### Option A: Supabase (Recommended)

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Create new project (choose a region close to you)
3. Wait for project to provision (~2 minutes)
4. Go to **SQL Editor** (left sidebar)
5. Copy contents of `database/migrations/001_create_core_tables.sql`
6. Paste in SQL Editor and click **Run**
7. Repeat with `database/seeds/002_seed_initial_data.sql`
8. Verify success: You should see "Teams created: 4" and "Agents created: 10"

### Get Your Connection String

1. In Supabase, go to **Settings** → **Database**
2. Copy the **Connection String** (URI format)
3. Save it - you'll need it next

---

## Step 2: Configure Environment (2 minutes)

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in:
   ```bash
   # Your Supabase connection string
   DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres

   # Your OpenAI API key
   OPENAI_API_KEY=sk-proj-YOUR_KEY_HERE

   # Optional: Slack token (can skip for now)
   # SLACK_BOT_TOKEN=xoxb-...
   ```

3. Save the file

---

## Step 3: Set Up N8N (10 minutes)

### Option A: N8N Cloud (Easiest)

1. Go to [n8n.cloud](https://n8n.cloud) and sign up
2. Create a new instance (free tier available)
3. Wait for instance to start

### Option B: Docker (Local)

```bash
docker run -d --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Open [http://localhost:5678](http://localhost:5678)

### Add Credentials in N8N

1. Click **Settings** (gear icon) → **Credentials**

2. **Add PostgreSQL Credential**:
   - Search for "Postgres"
   - Click "Postgres account"
   - Fill in your Supabase details:
     ```
     Host: db.YOUR_PROJECT.supabase.co
     Database: postgres
     User: postgres
     Password: [your Supabase password]
     Port: 5432
     SSL: Enabled
     ```
   - Name it "Supabase Production"
   - Save

3. **Add OpenAI Credential**:
   - Search for "OpenAI"
   - Click "OpenAI account"
   - Paste your API key
   - Name it "OpenAI Production"
   - Save

---

## Step 4: Build Your First Workflow (10 minutes)

### Workflow 1: Ticket Intake

1. In N8N, click **+ Add Workflow**
2. Name it "01 - Ticket Intake"

#### Add Nodes:

**Node 1: Webhook Trigger**
1. Add node → Search "Webhook"
2. Select "Webhook"
3. Settings:
   - HTTP Method: POST
   - Path: `ticket-intake`
   - Respond: Immediately
   - Response Code: 201
4. **IMPORTANT**: Click "Test step" and copy the webhook URL

**Node 2: Function - Normalize Input**
1. Add node → "Code" → "Run JavaScript"
2. Code:
```javascript
const input = $input.first().json;

return {
  channel: input.channel || 'api',
  sender_email: input.email,
  sender_name: input.name,
  subject: input.subject,
  body: input.message,
  idempotency_key: require('crypto')
    .createHash('sha256')
    .update(`${input.email}${input.subject}${Date.now()}`)
    .digest('hex')
};
```

**Node 3: Postgres - Create Ticket**
1. Add node → "Postgres"
2. Select your credential
3. Operation: **Execute Query**
4. Query:
```sql
INSERT INTO tickets (
  idempotency_key, channel, sender_email, sender_name,
  subject, body, status, priority
) VALUES (
  '{{ $json.idempotency_key }}',
  '{{ $json.channel }}',
  '{{ $json.sender_email }}',
  '{{ $json.sender_name }}',
  '{{ $json.subject }}',
  '{{ $json.body }}',
  'new',
  'medium'
)
RETURNING id, created_at;
```

**Node 4: Respond to Webhook**
1. Add node → "Respond to Webhook"
2. Response Code: 201
3. Response Body:
```json
{
  "success": true,
  "ticket_id": "{{ $json.id }}",
  "message": "Ticket created successfully"
}
```

5. **Connect all nodes** in sequence
6. Click **Save** (top right)
7. Toggle workflow to **Active** (switch in top right)

---

## Step 5: Test It! (3 minutes)

### Send a Test Ticket

```bash
# Make script executable
chmod +x scripts/test-webhook.sh

# Run test
./scripts/test-webhook.sh
```

Or manually with curl:

```bash
curl -X POST https://YOUR_N8N_URL/webhook/ticket-intake \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "subject": "Cannot log into account",
    "message": "I forgot my password and the reset link is not working."
  }'
```

### Verify Success

**Check N8N**:
1. In N8N, click "Executions" (left sidebar)
2. You should see a successful execution
3. Click it to see data flow through each node

**Check Database**:
1. In Supabase, go to **Table Editor**
2. Open `tickets` table
3. You should see your test ticket!

```sql
SELECT * FROM tickets ORDER BY created_at DESC LIMIT 1;
```

---

## Step 6: Add AI Triage (Optional - 5 minutes)

### Workflow 2: Simple AI Classification

1. Create new workflow: "02 - AI Triage"
2. Add **Webhook** trigger
   - Path: `ai-triage`
   - Expects: `{"ticket_id": "uuid"}`

3. Add **Postgres** → Fetch ticket:
```sql
SELECT * FROM tickets WHERE id = '{{ $json.ticket_id }}'
```

4. Add **OpenAI** → Chat Model:
   - Model: gpt-4o-mini
   - System: `You are a support ticket classifier. Return JSON: {"category": "billing|technical|account|general", "priority": "urgent|high|medium|low"}`
   - User: `Classify this ticket:\nSubject: {{ $json.subject }}\nBody: {{ $json.body }}`
   - Options → Enable JSON mode

5. Add **Postgres** → Update ticket:
```sql
UPDATE tickets
SET category = '{{ $json.category }}',
    priority = '{{ $json.priority }}',
    status = 'analyzed'
WHERE id = '{{ $node["Postgres"].json.id }}'
```

6. Save and activate

### Test AI Triage

```bash
curl -X POST https://YOUR_N8N_URL/webhook/ai-triage \
  -H "Content-Type: application/json" \
  -d '{"ticket_id": "YOUR_TICKET_ID_FROM_STEP_5"}'
```

Check database:
```sql
SELECT id, subject, category, priority, status
FROM tickets
WHERE category IS NOT NULL;
```

---

## 🎉 Success!

You now have a working AI-powered support system!

### What You've Built

- ✅ Ticket intake via webhook
- ✅ Database storage with Supabase
- ✅ AI classification with OpenAI
- ✅ Full audit trail

### Next Steps

1. **Build More Workflows**:
   - Routing & Assignment (see `docs/n8n-workflow-guide.md`)
   - Response Generation
   - SLA Monitoring
   - Analytics

2. **Add Integrations**:
   - Slack notifications
   - Email support (IMAP/SMTP)
   - Webhooks to your existing tools

3. **Generate Test Data**:
   ```bash
   node scripts/generate-test-tickets.js 50 sql > test-data.sql
   # Load in Supabase SQL Editor
   ```

4. **Monitor & Improve**:
   - Watch AI accuracy
   - Adjust prompts
   - Add custom logic

---

## 📚 Documentation

- **Full README**: `README.md` - Complete project overview
- **Workflow Guide**: `docs/n8n-workflow-guide.md` - Detailed N8N setup
- **Database Schema**: `database/migrations/` - All tables explained
- **Troubleshooting**: See section below

---

## 🐛 Troubleshooting

### "Cannot connect to database"
- Verify DATABASE_URL in .env is correct
- Check Supabase project is not paused
- Try connection in Supabase SQL Editor first

### "OpenAI API error"
- Check API key is valid
- Verify billing is set up on OpenAI account
- Check rate limits haven't been hit

### "Webhook returns 404"
- Ensure workflow is Active (toggle in top right)
- Check webhook path matches exactly
- Test URL is correct format: `https://your-n8n.cloud/webhook/PATH`

### "No data in database"
- Check N8N execution logs for errors
- Verify SQL syntax in Postgres nodes
- Test query directly in Supabase

---

## 💡 Tips

- **Start Simple**: Get one workflow perfect before moving to next
- **Test Often**: Use the test-webhook script after every change
- **Check Logs**: N8N execution logs show exactly what happened
- **Use Console**: Add `console.log($json)` in Function nodes to debug

---

## 🆘 Need Help?

- Check `docs/n8n-workflow-guide.md` for detailed instructions
- Review N8N docs: [docs.n8n.io](https://docs.n8n.io)
- Check Supabase docs: [supabase.com/docs](https://supabase.com/docs)
- OpenAI API reference: [platform.openai.com/docs](https://platform.openai.com/docs)

---

**You're ready to build something amazing! 🚀**
