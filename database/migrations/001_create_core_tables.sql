-- Migration 001: Create Core Tables
-- Run this first in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Teams Table
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  handles_categories TEXT[],
  slack_channel_id VARCHAR(50),
  slack_channel_name VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agents Table
CREATE TABLE agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  avatar_url TEXT,

  team_id UUID REFERENCES teams(id),
  role VARCHAR(50) DEFAULT 'agent' CHECK (role IN ('agent', 'senior_agent', 'team_lead', 'manager')),
  skill_level VARCHAR(20) DEFAULT 'mid' CHECK (skill_level IN ('junior', 'mid', 'senior', 'expert')),

  specializations TEXT[],
  max_concurrent_tickets INTEGER DEFAULT 10,

  is_available BOOLEAN DEFAULT true,
  availability_status VARCHAR(30) DEFAULT 'online' CHECK (availability_status IN ('online', 'away', 'busy', 'offline')),

  slack_user_id VARCHAR(50),
  slack_dm_channel_id VARCHAR(50),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE
);

-- Tickets Table (Main)
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key VARCHAR(64) UNIQUE NOT NULL,

  -- Source
  channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'slack', 'api', 'web', 'phone')),
  sender_email VARCHAR(255) NOT NULL,
  sender_name VARCHAR(255),

  -- Content
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  attachments JSONB DEFAULT '[]'::jsonb,

  -- Classification
  category VARCHAR(50),
  sub_category VARCHAR(50),
  tags TEXT[],

  -- Status & Priority
  status VARCHAR(30) DEFAULT 'new' CHECK (status IN ('new', 'analyzing', 'analyzed', 'assigned', 'in_progress', 'waiting_customer', 'resolved', 'closed', 'spam')),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('urgent', 'high', 'medium', 'low')),

  -- Assignment
  assigned_to UUID REFERENCES agents(id),
  assigned_at TIMESTAMP WITH TIME ZONE,
  team_id UUID REFERENCES teams(id),

  -- SLA
  sla_deadline TIMESTAMP WITH TIME ZONE,
  first_response_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE,

  -- Flags
  is_spam BOOLEAN DEFAULT false,
  is_escalated BOOLEAN DEFAULT false,
  escalated_to UUID REFERENCES agents(id),

  -- Metadata
  raw_metadata JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI Analysis Table
CREATE TABLE ai_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,

  -- Classification
  category VARCHAR(50) NOT NULL,
  sub_category VARCHAR(50),
  confidence NUMERIC(3,2) NOT NULL CHECK (confidence BETWEEN 0 AND 1),

  -- Sentiment
  sentiment_emotion VARCHAR(30),
  sentiment_intensity INTEGER CHECK (sentiment_intensity BETWEEN 1 AND 10),

  -- Priority
  priority_recommendation VARCHAR(20),
  urgency_score INTEGER CHECK (urgency_score BETWEEN 1 AND 10),
  escalation_flag BOOLEAN DEFAULT false,
  escalation_reason TEXT,

  -- AI Reasoning
  reasoning JSONB,

  -- Model Info
  model_name VARCHAR(100) NOT NULL,
  model_version VARCHAR(50),
  prompt_tokens INTEGER,
  completion_tokens INTEGER,
  total_cost NUMERIC(10,6),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ticket Events (Audit Trail)
CREATE TABLE ticket_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,

  event_type VARCHAR(50) NOT NULL,
  event_data JSONB,

  actor_type VARCHAR(20) NOT NULL CHECK (actor_type IN ('system', 'ai', 'agent', 'customer', 'workflow')),
  actor_id UUID,
  actor_name VARCHAR(255),

  workflow_id VARCHAR(100),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routing Rules
CREATE TABLE routing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,

  -- Match criteria
  category VARCHAR(50),
  sub_category VARCHAR(50),
  priority VARCHAR(20),

  -- Target
  team_id UUID REFERENCES teams(id),

  rule_priority INTEGER DEFAULT 100,
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SLA Configurations
CREATE TABLE sla_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,

  priority VARCHAR(20) NOT NULL UNIQUE CHECK (priority IN ('urgent', 'high', 'medium', 'low')),

  first_response_target INTEGER NOT NULL, -- minutes
  resolution_target INTEGER NOT NULL, -- minutes

  business_hours_only BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SLA Tracking
CREATE TABLE sla_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,

  priority VARCHAR(20) NOT NULL,
  first_response_deadline TIMESTAMP WITH TIME ZONE NOT NULL,
  resolution_deadline TIMESTAMP WITH TIME ZONE NOT NULL,

  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'met', 'breached', 'paused')),

  alert_50_sent BOOLEAN DEFAULT false,
  alert_80_sent BOOLEAN DEFAULT false,
  breach_alert_sent BOOLEAN DEFAULT false,

  breached_at TIMESTAMP WITH TIME ZONE,
  breach_duration_minutes INTEGER,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Responses
CREATE TABLE responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,

  direction VARCHAR(20) NOT NULL CHECK (direction IN ('outbound', 'inbound')),
  channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'slack', 'phone', 'chat')),

  subject TEXT,
  body TEXT NOT NULL,
  attachments JSONB DEFAULT '[]'::jsonb,

  sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('agent', 'customer', 'system', 'ai')),
  sender_id UUID,
  sender_name VARCHAR(255),

  was_ai_generated BOOLEAN DEFAULT false,
  ai_draft BOOLEAN DEFAULT false,
  ai_model VARCHAR(100),
  agent_edited BOOLEAN DEFAULT false,

  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Error Logs
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  workflow_name VARCHAR(100),
  workflow_execution_id VARCHAR(100),
  node_name VARCHAR(100),

  error_type VARCHAR(100),
  error_message TEXT NOT NULL,
  error_stack TEXT,

  ticket_id UUID REFERENCES tickets(id),

  severity VARCHAR(20) DEFAULT 'error' CHECK (severity IN ('info', 'warning', 'error', 'critical')),

  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolution_notes TEXT,

  metadata JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics Daily
CREATE TABLE analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE UNIQUE NOT NULL,

  total_tickets INTEGER DEFAULT 0,
  tickets_resolved INTEGER DEFAULT 0,
  tickets_auto_resolved INTEGER DEFAULT 0,
  resolution_rate NUMERIC(5,2),

  avg_first_response_minutes NUMERIC(10,2),
  avg_resolution_hours NUMERIC(10,2),
  median_resolution_hours NUMERIC(10,2),

  sla_compliance_rate NUMERIC(5,2),
  sla_breaches INTEGER DEFAULT 0,

  tickets_by_channel JSONB,
  tickets_by_category JSONB,
  tickets_by_priority JSONB,

  ai_classification_accuracy NUMERIC(5,2),
  ai_responses_generated INTEGER DEFAULT 0,
  ai_responses_sent INTEGER DEFAULT 0,
  avg_ai_confidence NUMERIC(3,2),

  active_agents INTEGER DEFAULT 0,
  avg_tickets_per_agent NUMERIC(10,2),

  total_ai_cost NUMERIC(10,4),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Tickets indexes
CREATE INDEX idx_tickets_status ON tickets(status) WHERE status NOT IN ('resolved', 'closed', 'spam');
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to) WHERE status IN ('assigned', 'in_progress');
CREATE INDEX idx_tickets_sender_email ON tickets(sender_email);
CREATE INDEX idx_tickets_created_at ON tickets(created_at DESC);
CREATE INDEX idx_tickets_sla_deadline ON tickets(sla_deadline) WHERE status NOT IN ('resolved', 'closed', 'spam');
CREATE INDEX idx_tickets_idempotency ON tickets(idempotency_key);
CREATE INDEX idx_tickets_category ON tickets(category);

-- AI Analysis indexes
CREATE INDEX idx_ai_analysis_ticket_id ON ai_analysis(ticket_id);
CREATE INDEX idx_ai_analysis_category ON ai_analysis(category);
CREATE INDEX idx_ai_analysis_confidence ON ai_analysis(confidence);
CREATE INDEX idx_ai_analysis_created_at ON ai_analysis(created_at DESC);

-- Ticket Events indexes
CREATE INDEX idx_ticket_events_ticket_id ON ticket_events(ticket_id, created_at DESC);
CREATE INDEX idx_ticket_events_type ON ticket_events(event_type);
CREATE INDEX idx_ticket_events_created_at ON ticket_events(created_at DESC);

-- Agents indexes
CREATE INDEX idx_agents_team_id ON agents(team_id);
CREATE INDEX idx_agents_is_available ON agents(is_available) WHERE is_available = true;
CREATE INDEX idx_agents_email ON agents(email);

-- Teams indexes
CREATE INDEX idx_teams_name ON teams(name);

-- Routing Rules indexes
CREATE INDEX idx_routing_rules_category ON routing_rules(category) WHERE is_active = true;
CREATE INDEX idx_routing_rules_priority ON routing_rules(rule_priority) WHERE is_active = true;

-- SLA Tracking indexes
CREATE INDEX idx_sla_tracking_ticket_id ON sla_tracking(ticket_id);
CREATE INDEX idx_sla_tracking_status ON sla_tracking(status) WHERE status = 'active';
CREATE INDEX idx_sla_tracking_deadlines ON sla_tracking(resolution_deadline) WHERE status = 'active';

-- Responses indexes
CREATE INDEX idx_responses_ticket_id ON responses(ticket_id, created_at);
CREATE INDEX idx_responses_direction ON responses(direction);
CREATE INDEX idx_responses_ai_generated ON responses(was_ai_generated);

-- Error Logs indexes
CREATE INDEX idx_error_logs_workflow ON error_logs(workflow_name, created_at DESC);
CREATE INDEX idx_error_logs_severity ON error_logs(severity) WHERE resolved = false;
CREATE INDEX idx_error_logs_created_at ON error_logs(created_at DESC);
CREATE INDEX idx_error_logs_ticket_id ON error_logs(ticket_id) WHERE ticket_id IS NOT NULL;

-- Analytics indexes
CREATE INDEX idx_analytics_daily_date ON analytics_daily(date DESC);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routing_rules_updated_at BEFORE UPDATE ON routing_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sla_configurations_updated_at BEFORE UPDATE ON sla_configurations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sla_tracking_updated_at BEFORE UPDATE ON sla_tracking
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analytics_daily_updated_at BEFORE UPDATE ON analytics_daily
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Active tickets with analysis
CREATE VIEW active_tickets_view AS
SELECT
  t.*,
  a.category as ai_category,
  a.sub_category as ai_sub_category,
  a.confidence as ai_confidence,
  a.sentiment_emotion,
  a.sentiment_intensity,
  a.escalation_flag,
  ag.name as agent_name,
  ag.email as agent_email,
  tm.name as team_name
FROM tickets t
LEFT JOIN LATERAL (
  SELECT * FROM ai_analysis
  WHERE ticket_id = t.id
  ORDER BY created_at DESC
  LIMIT 1
) a ON true
LEFT JOIN agents ag ON ag.id = t.assigned_to
LEFT JOIN teams tm ON tm.id = t.team_id
WHERE t.status NOT IN ('resolved', 'closed', 'spam')
ORDER BY
  CASE t.priority
    WHEN 'urgent' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
  END,
  t.created_at ASC;

-- Agent workload
CREATE VIEW agent_workload AS
SELECT
  a.id,
  a.name,
  a.email,
  a.team_id,
  a.is_available,
  a.max_concurrent_tickets,
  COUNT(t.id) as current_tickets,
  a.max_concurrent_tickets - COUNT(t.id) as capacity_remaining,
  ROUND((COUNT(t.id)::NUMERIC / NULLIF(a.max_concurrent_tickets, 0)) * 100, 2) as utilization_percent
FROM agents a
LEFT JOIN tickets t ON t.assigned_to = a.id
  AND t.status IN ('assigned', 'in_progress')
GROUP BY a.id, a.name, a.email, a.team_id, a.is_available, a.max_concurrent_tickets
ORDER BY utilization_percent DESC;

-- SLA breach risk
CREATE VIEW sla_breach_risk AS
SELECT
  t.id,
  t.subject,
  t.priority,
  t.status,
  s.resolution_deadline,
  EXTRACT(EPOCH FROM (s.resolution_deadline - NOW()))/60 as minutes_remaining,
  CASE
    WHEN s.resolution_deadline < NOW() THEN 'BREACHED'
    WHEN s.resolution_deadline < NOW() + INTERVAL '30 minutes' THEN 'CRITICAL'
    WHEN s.resolution_deadline < NOW() + INTERVAL '2 hours' THEN 'WARNING'
    ELSE 'OK'
  END as risk_level
FROM tickets t
JOIN sla_tracking s ON s.ticket_id = t.id
WHERE t.status NOT IN ('resolved', 'closed')
  AND s.status = 'active'
ORDER BY s.resolution_deadline ASC;

COMMENT ON TABLE tickets IS 'Main tickets table - all support requests';
COMMENT ON TABLE ai_analysis IS 'AI model outputs for ticket classification and analysis';
COMMENT ON TABLE ticket_events IS 'Complete audit trail of all ticket state changes';
COMMENT ON TABLE agents IS 'Support team members who handle tickets';
COMMENT ON TABLE teams IS 'Organizational teams for routing';
COMMENT ON TABLE routing_rules IS 'Configurable routing logic';
COMMENT ON TABLE sla_tracking IS 'Active SLA monitoring for open tickets';
COMMENT ON TABLE responses IS 'All customer communications';
COMMENT ON TABLE error_logs IS 'System errors and failures for debugging';
COMMENT ON TABLE analytics_daily IS 'Pre-aggregated daily metrics';
