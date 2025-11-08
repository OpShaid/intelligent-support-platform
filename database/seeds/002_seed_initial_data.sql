

INSERT INTO teams (name, description, handles_categories, slack_channel_name) VALUES
  ('Billing Team', 'Handles all billing, payments, refunds, and subscription issues',
   ARRAY['billing'], '#support-billing'),
  ('Technical Support', 'Handles bugs, integrations, API issues, and technical questions',
   ARRAY['technical'], '#support-technical'),
  ('Account Management', 'Handles account access, security, password resets, and upgrades',
   ARRAY['account'], '#support-accounts'),
  ('General Support', 'Handles general questions and unclassified tickets',
   ARRAY['general'], '#support-general');


-- Billing Team Agents
INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Sarah Johnson', 'sarah.johnson@company.com',
  (SELECT id FROM teams WHERE name = 'Billing Team'),
  'senior_agent', 'senior', ARRAY['billing', 'refunds'], 15, true;

INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Mike Chen', 'mike.chen@company.com',
  (SELECT id FROM teams WHERE name = 'Billing Team'),
  'agent', 'mid', ARRAY['billing'], 10, true;

-- Technical Support Agents
INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Alex Rivera', 'alex.rivera@company.com',
  (SELECT id FROM teams WHERE name = 'Technical Support'),
  'senior_agent', 'expert', ARRAY['technical', 'api', 'integrations'], 12, true;

INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Jessica Park', 'jessica.park@company.com',
  (SELECT id FROM teams WHERE name = 'Technical Support'),
  'agent', 'senior', ARRAY['technical', 'bugs'], 10, true;

INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'David Kim', 'david.kim@company.com',
  (SELECT id FROM teams WHERE name = 'Technical Support'),
  'agent', 'mid', ARRAY['technical'], 8, true;

-- Account Management Agents
INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Emily Thompson', 'emily.thompson@company.com',
  (SELECT id FROM teams WHERE name = 'Account Management'),
  'team_lead', 'expert', ARRAY['account', 'security'], 15, true;

INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Carlos Rodriguez', 'carlos.rodriguez@company.com',
  (SELECT id FROM teams WHERE name = 'Account Management'),
  'agent', 'mid', ARRAY['account'], 10, true;

-- General Support Agents
INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Lisa Anderson', 'lisa.anderson@company.com',
  (SELECT id FROM teams WHERE name = 'General Support'),
  'agent', 'mid', ARRAY['general'], 12, true;

INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Tom Wilson', 'tom.wilson@company.com',
  (SELECT id FROM teams WHERE name = 'General Support'),
  'agent', 'junior', ARRAY['general'], 8, true;

-- Manager
INSERT INTO agents (name, email, team_id, role, skill_level, specializations, max_concurrent_tickets, is_available)
SELECT
  'Rachel Martinez', 'rachel.martinez@company.com',
  (SELECT id FROM teams WHERE name = 'General Support'),
  'manager', 'expert', ARRAY['billing', 'technical', 'account', 'general'], 20, true;



INSERT INTO sla_configurations (name, priority, first_response_target, resolution_target, business_hours_only, is_active) VALUES
  ('Urgent Priority SLA', 'urgent', 60, 240, false, true),     
  ('High Priority SLA', 'high', 240, 480, false, true),       
  ('Medium Priority SLA', 'medium', 480, 1440, true, true),    
  ('Low Priority SLA', 'low', 1440, 4320, true, true);        



-- Urgent routing (highest priority)
INSERT INTO routing_rules (name, description, category, priority, team_id, rule_priority, is_active)
SELECT
  'Urgent Billing Issues',
  'Route urgent billing issues to billing team immediately',
  'billing',
  'urgent',
  (SELECT id FROM teams WHERE name = 'Billing Team'),
  10,
  true;

INSERT INTO routing_rules (name, description, category, priority, team_id, rule_priority, is_active)
SELECT
  'Urgent Technical Issues',
  'Route urgent technical issues to senior technical support',
  'technical',
  'urgent',
  (SELECT id FROM teams WHERE name = 'Technical Support'),
  10,
  true;

INSERT INTO routing_rules (name, description, category, priority, team_id, rule_priority, is_active)
SELECT
  'Urgent Account Issues',
  'Route urgent account/security issues to account management',
  'account',
  'urgent',
  (SELECT id FROM teams WHERE name = 'Account Management'),
  10,
  true;

-- Category-based routing (normal priority)
INSERT INTO routing_rules (name, description, category, team_id, rule_priority, is_active)
SELECT
  'Billing Issues',
  'Route all billing-related tickets to billing team',
  'billing',
  (SELECT id FROM teams WHERE name = 'Billing Team'),
  50,
  true;

INSERT INTO routing_rules (name, description, category, team_id, rule_priority, is_active)
SELECT
  'Technical Issues',
  'Route all technical tickets to technical support',
  'technical',
  (SELECT id FROM teams WHERE name = 'Technical Support'),
  50,
  true;

INSERT INTO routing_rules (name, description, category, team_id, rule_priority, is_active)
SELECT
  'Account Issues',
  'Route all account-related tickets to account management',
  'account',
  (SELECT id FROM teams WHERE name = 'Account Management'),
  50,
  true;

INSERT INTO routing_rules (name, description, category, team_id, rule_priority, is_active)
SELECT
  'General Questions',
  'Route general questions to general support team',
  'general',
  (SELECT id FROM teams WHERE name = 'General Support'),
  100,
  true;

-- Fallback rule (lowest priority)
INSERT INTO routing_rules (name, description, team_id, rule_priority, is_active)
SELECT
  'Default Routing',
  'Catch-all rule for unclassified tickets',
  (SELECT id FROM teams WHERE name = 'General Support'),
  999,
  true;


SELECT 'Teams created:' as status, COUNT(*) as count FROM teams;
SELECT name, handles_categories FROM teams;

-- Check agents
SELECT 'Agents created:' as status, COUNT(*) as count FROM agents;
SELECT a.name, a.email, t.name as team, a.role, a.skill_level
FROM agents a
LEFT JOIN teams t ON a.team_id = t.id
ORDER BY t.name, a.name;

-- Check SLA configs
SELECT 'SLA configs created:' as status, COUNT(*) as count FROM sla_configurations;
SELECT priority, first_response_target || ' min' as response_sla, resolution_target || ' min' as resolution_sla
FROM sla_configurations
ORDER BY first_response_target;

-- Check routing rules
SELECT 'Routing rules created:' as status, COUNT(*) as count FROM routing_rules;
SELECT r.name, r.category, r.priority, t.name as routes_to, r.rule_priority
FROM routing_rules r
LEFT JOIN teams t ON r.team_id = t.id
ORDER BY r.rule_priority;

-- Check agent workload (should be 0 initially)
SELECT * FROM agent_workload;
