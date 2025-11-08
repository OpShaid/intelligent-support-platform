#!/usr/bin/env node



const crypto = require('crypto');

// Sample data
const firstNames = ['John', 'Sarah', 'Mike', 'Emily', 'David', 'Jessica', 'Carlos', 'Lisa', 'Tom', 'Rachel', 'Alex', 'Jennifer', 'Ryan', 'Amanda', 'Kevin'];
const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Wilson', 'Anderson', 'Taylor'];
const domains = ['gmail.com', 'outlook.com', 'yahoo.com', 'company.com', 'business.co', 'startup.io', 'enterprise.com'];

// Ticket templates by category
const ticketTemplates = {
  billing: [
    {
      subject: "Need refund for double charge",
      body: "I was charged twice for my subscription this month. My card was charged $99 on the 1st and again on the 3rd. Please refund one of these charges immediately.",
      sub_category: "refund_request",
      sentiment: "frustrated",
      intensity: 7
    },
    {
      subject: "Can't update payment method",
      body: "I'm trying to update my credit card information but the form keeps giving me an error. I need to update it before my subscription renews next week.",
      sub_category: "payment_failed",
      sentiment: "confused",
      intensity: 5
    },
    {
      subject: "Question about invoice",
      body: "I received invoice #INV-12345 but I don't recognize one of the line items. Can you explain what 'Additional Users (3x)' means? I only have 2 users on my account.",
      sub_category: "invoice_issue",
      sentiment: "neutral",
      intensity: 3
    },
    {
      subject: "Want to upgrade to Enterprise plan",
      body: "Our team is growing and we need more features. Can you help me upgrade to the Enterprise plan? What's the pricing difference?",
      sub_category: "subscription_upgrade",
      sentiment: "satisfied",
      intensity: 2
    },
    {
      subject: "URGENT: Unauthorized charges on my account",
      body: "I just saw three charges on my credit card from your company totaling $297. I did NOT authorize these. I cancelled my subscription months ago. This is completely unacceptable and I'm disputing these charges with my bank.",
      sub_category: "refund_request",
      sentiment: "angry",
      intensity: 9
    }
  ],
  technical: [
    {
      subject: "API returning 500 errors",
      body: "For the past 2 hours, our production app has been getting 500 Internal Server Error from your API endpoint /api/v1/users. This is breaking our entire application. We need this fixed ASAP.",
      sub_category: "api_error",
      sentiment: "frustrated",
      intensity: 8
    },
    {
      subject: "Dashboard not loading",
      body: "When I try to access my dashboard, I just see a blank white screen. I've tried different browsers (Chrome, Firefox, Safari) and the problem persists. Can you help?",
      sub_category: "bug_report",
      sentiment: "confused",
      intensity: 6
    },
    {
      subject: "Feature request: Export to CSV",
      body: "It would be really helpful if we could export our data to CSV format. Currently we can only export to PDF which doesn't work well for our analysis needs.",
      sub_category: "feature_request",
      sentiment: "neutral",
      intensity: 3
    },
    {
      subject: "Integration with Salesforce not working",
      body: "I followed the integration guide but the data is not syncing between your platform and Salesforce. I've checked all the API keys and they seem correct. What am I missing?",
      sub_category: "integration_issue",
      sentiment: "frustrated",
      intensity: 6
    },
    {
      subject: "Slow performance when loading reports",
      body: "Ever since the update last week, loading reports takes 30+ seconds. It used to be instant. Is there a known issue with the latest version?",
      sub_category: "performance_problem",
      sentiment: "frustrated",
      intensity: 5
    }
  ],
  account: [
    {
      subject: "Can't log into my account",
      body: "I'm getting 'Invalid credentials' error when trying to log in, but I'm 100% sure my password is correct. I need access urgently for a client meeting in 1 hour.",
      sub_category: "cannot_login",
      sentiment: "frustrated",
      intensity: 8
    },
    {
      subject: "Password reset not working",
      body: "I clicked 'Forgot Password' but I never received the reset email. I've checked my spam folder too. Can you manually reset my password?",
      sub_category: "password_reset",
      sentiment: "confused",
      intensity: 5
    },
    {
      subject: "Need to delete my account",
      body: "I no longer need this service and would like to completely delete my account and all associated data. How do I do this?",
      sub_category: "account_deletion",
      sentiment: "neutral",
      intensity: 2
    },
    {
      subject: "Account locked after too many login attempts",
      body: "My account got locked because I forgot my password and tried too many times. Can you unlock it? I need to access my data.",
      sub_category: "account_locked",
      sentiment: "frustrated",
      intensity: 6
    },
    {
      subject: "Security concern - suspicious activity",
      body: "I just received a notification about a login from an IP address in Russia. I'm in the US and have never been to Russia. I think my account may have been compromised. Please help immediately!",
      sub_category: "security_concern",
      sentiment: "worried",
      intensity: 9
    }
  ],
  general: [
    {
      subject: "How do I invite team members?",
      body: "I just signed up and want to add my team members. Where do I find the option to invite users?",
      sub_category: "general_question",
      sentiment: "neutral",
      intensity: 2
    },
    {
      subject: "Love the new feature!",
      body: "Just wanted to say the new dashboard redesign is amazing! So much cleaner and easier to use. Great job!",
      sub_category: "feedback",
      sentiment: "happy",
      intensity: 2
    },
    {
      subject: "Documentation unclear",
      body: "I'm trying to follow the 'Getting Started' guide but step 3 doesn't make sense. The screenshot shows a button that I don't see in my interface. Can you clarify?",
      sub_category: "documentation",
      sentiment: "confused",
      intensity: 4
    },
    {
      subject: "Partnership inquiry",
      body: "I represent a marketing agency with 50+ clients who could benefit from your platform. I'd like to discuss partnership opportunities. Who should I speak with?",
      sub_category: "partnership_inquiry",
      sentiment: "neutral",
      intensity: 2
    }
  ]
};

function randomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generateHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function generateTicket(index) {
  const firstName = randomElement(firstNames);
  const lastName = randomElement(lastNames);
  const email = `${firstName.toLowerCase()}.${lastName.toLowerCase()}@${randomElement(domains)}`;

  const category = randomElement(Object.keys(ticketTemplates));
  const template = randomElement(ticketTemplates[category]);

  const content = `${email}::${template.subject}::${template.body.substring(0, 200)}`;
  const idempotencyKey = generateHash(content);

  const channels = ['email', 'slack', 'web', 'api'];
  const channel = randomElement(channels);

  return {
    idempotency_key: idempotencyKey,
    channel: channel,
    sender_email: email,
    sender_name: `${firstName} ${lastName}`,
    subject: template.subject,
    body: template.body,
    category: category,
    sub_category: template.sub_category,
    expected_sentiment: template.sentiment,
    expected_intensity: template.intensity,
    status: 'new',
    priority: 'medium',
    attachments: '[]',
    is_spam: false,
    raw_metadata: JSON.stringify({
      source: channel,
      generated: true,
      timestamp: new Date().toISOString()
    })
  };
}

function generateSQLInserts(tickets) {
  let sql = "-- Generated Test Tickets\n";
  sql += "-- Generated at: " + new Date().toISOString() + "\n\n";

  tickets.forEach((ticket, index) => {
    sql += `-- Ticket ${index + 1}: ${ticket.category} - ${ticket.subject}\n`;
    sql += `INSERT INTO tickets (idempotency_key, channel, sender_email, sender_name, subject, body, status, priority, raw_metadata, created_at)\n`;
    sql += `VALUES (\n`;
    sql += `  '${ticket.idempotency_key}',\n`;
    sql += `  '${ticket.channel}',\n`;
    sql += `  '${ticket.sender_email}',\n`;
    sql += `  '${ticket.sender_name}',\n`;
    sql += `  $TICKET_${index}_SUBJECT$${ticket.subject}$TICKET_${index}_SUBJECT$,\n`;
    sql += `  $TICKET_${index}_BODY$${ticket.body}$TICKET_${index}_BODY$,\n`;
    sql += `  '${ticket.status}',\n`;
    sql += `  '${ticket.priority}',\n`;
    sql += `  '${ticket.raw_metadata}'::jsonb,\n`;
    sql += `  NOW() - INTERVAL '${Math.floor(Math.random() * 48)} hours'\n`;
    sql += `);\n\n`;
  });

  return sql;
}

function generateJSONOutput(tickets) {
  return JSON.stringify(tickets, null, 2);
}

function generateWebhookPayloads(tickets) {
  return tickets.map(ticket => ({
    email: ticket.sender_email,
    name: ticket.sender_name,
    subject: ticket.subject,
    message: ticket.body,
    source: ticket.channel
  }));
}

// Main execution
const count = parseInt(process.argv[2]) || 20;

console.log(`Generating ${count} test tickets...\n`);

const tickets = [];
for (let i = 0; i < count; i++) {
  tickets.push(generateTicket(i));
}

// Summary
const summary = tickets.reduce((acc, ticket) => {
  acc[ticket.category] = (acc[ticket.category] || 0) + 1;
  return acc;
}, {});

console.log("Summary:");
console.log(`Total tickets: ${tickets.length}`);
Object.entries(summary).forEach(([category, count]) => {
  console.log(`  ${category}: ${count}`);
});
console.log();

// Output options
const outputFormat = process.argv[3] || 'json';

if (outputFormat === 'sql') {
  console.log(generateSQLInserts(tickets));
} else if (outputFormat === 'webhook') {
  console.log(JSON.stringify(generateWebhookPayloads(tickets), null, 2));
} else {
  console.log(generateJSONOutput(tickets));
}

// Usage instructions
if (process.argv.length === 2) {
  console.error('\n===========================================');
  console.error('Usage:');
  console.error('  node generate-test-tickets.js [count] [format]');
  console.error('\nFormats:');
  console.error('  json     - JSON array (default)');
  console.error('  sql      - SQL INSERT statements');
  console.error('  webhook  - Webhook payload format');
  console.error('\nExamples:');
  console.error('  node generate-test-tickets.js 50');
  console.error('  node generate-test-tickets.js 100 sql > test-tickets.sql');
  console.error('  node generate-test-tickets.js 10 webhook');
  console.error('===========================================\n');
}
