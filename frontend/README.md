# 🎨 Support Intelligence Platform - Frontend

Modern, real-time dashboard for AI-powered customer support automation.

Built with **Next.js 14**, **TypeScript**, **Tailwind CSS**, **shadcn/ui**, and **Supabase Realtime**.

---

## ✨ Features

### 🎯 Agent Dashboard
- **Real-time ticket feed** - See new tickets as they arrive
- **Kanban board** - Drag-and-drop ticket management
- **AI-assisted responses** - One-click AI response generation
- **Live chat** - Direct communication with customers
- **Performance metrics** - Personal KPIs and leaderboard

### 👥 Customer Portal
- **Submit tickets** - Beautiful form with file upload
- **Track status** - Real-time updates on ticket progress
- **Knowledge base** - Self-service articles
- **Satisfaction surveys** - Rate responses and agents

### 📊 Analytics Dashboard
- **Real-time metrics** - Live updates on key KPIs
- **Interactive charts** - Powered by Recharts
- **Category breakdown** - See top issues at a glance
- **SLA tracking** - Monitor breach risks
- **AI performance** - Track classification accuracy and costs

### ⚙️ Admin Panel
- **Agent management** - Add/edit team members
- **Routing rules** - Configure ticket routing
- **Knowledge base** - Manage articles and categories
- **System settings** - Configure SLA, priorities, integrations
- **Audit logs** - Complete system activity history

### 🚀 Advanced Features
- **Real-time updates** via Supabase Realtime
- **Dark mode** toggle
- **Responsive design** - Works on mobile/tablet/desktop
- **Keyboard shortcuts** - Power-user friendly
- **Offline support** - PWA capabilities
- **Export data** - CSV/PDF reports

---

## 🏗️ Architecture

```
frontend/
├── app/                    # Next.js 14 App Router
│   ├── (agent)/           # Agent portal routes
│   │   ├── dashboard/
│   │   ├── tickets/
│   │   ├── analytics/
│   │   └── settings/
│   ├── (customer)/        # Customer portal routes
│   │   ├── submit/
│   │   ├── track/
│   │   └── help/
│   ├── (admin)/           # Admin panel routes
│   │   ├── agents/
│   │   ├── teams/
│   │   ├── routing/
│   │   └── settings/
│   ├── api/               # API routes
│   │   ├── tickets/
│   │   ├── analytics/
│   │   └── webhooks/
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Landing page
│
├── components/            # React components
│   ├── ui/               # shadcn/ui components
│   ├── tickets/          # Ticket-related components
│   ├── analytics/        # Chart and metric components
│   ├── agents/           # Agent management components
│   └── layout/           # Layout components (nav, sidebar)
│
├── lib/                   # Utilities
│   ├── supabase.ts       # Supabase client & helpers
│   ├── utils.ts          # Utility functions
│   ├── api.ts            # API client
│   └── constants.ts      # App constants
│
├── hooks/                 # Custom React hooks
│   ├── useTickets.ts     # Ticket management
│   ├── useRealtime.ts    # Realtime subscriptions
│   ├── useAnalytics.ts   # Analytics data
│   └── useAuth.ts        # Authentication
│
├── types/                 # TypeScript definitions
│   ├── database.ts       # Supabase types
│   ├── tickets.ts        # Ticket types
│   └── api.ts            # API types
│
└── styles/
    └── globals.css       # Global styles with Tailwind
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure Environment

Create `.env.local`:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# N8N Webhook (for ticket submission)
NEXT_PUBLIC_N8N_WEBHOOK_URL=https://your-n8n.cloud/webhook/ticket-intake

# App Config
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_COMPANY_NAME="Your Company"
```

### 3. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 📱 Pages & Routes

### Agent Portal
- `/agent/dashboard` - Main dashboard with ticket overview
- `/agent/tickets` - Full ticket list with filters
- `/agent/tickets/[id]` - Ticket detail view
- `/agent/analytics` - Personal performance metrics
- `/agent/settings` - Agent preferences

### Customer Portal
- `/submit` - Submit new support ticket
- `/track/[id]` - Track ticket status
- `/help` - Knowledge base and FAQs
- `/help/[article]` - Individual help article

### Admin Panel
- `/admin/overview` - System overview and metrics
- `/admin/agents` - Manage agents and teams
- `/admin/routing` - Configure routing rules
- `/admin/knowledge` - Knowledge base management
- `/admin/settings` - System settings
- `/admin/logs` - Audit logs

---

## 🎨 Components Library

### Pre-built shadcn/ui Components

Run these commands to add components as needed:

```bash
# Button component
npx shadcn-ui@latest add button

# Form components
npx shadcn-ui@latest add input
npx shadcn-ui@latest add textarea
npx shadcn-ui@latest add select
npx shadcn-ui@latest add label

# Layout components
npx shadcn-ui@latest add card
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add dropdown-menu

# Data display
npx shadcn-ui@latest add table
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add avatar

# Feedback
npx shadcn-ui@latest add toast
npx shadcn-ui@latest add alert
npx shadcn-ui@latest add progress
```

Or add all at once:
```bash
npx shadcn-ui@latest add button input textarea select label card tabs dialog dropdown-menu table badge avatar toast alert progress separator
```

### Custom Components

Key custom components included:

- `<TicketCard />` - Displays ticket with status, priority, AI insights
- `<TicketList />` - Filterable, sortable ticket list
- `<TicketDetail />` - Full ticket view with timeline
- `<AIResponseEditor />` - AI-assisted response composition
- `<MetricCard />` - Dashboard metric display
- `<LineChart />` - Time-series data visualization
- `<CategoryPieChart />` - Category distribution
- `<AgentAvatar />` - Agent profile picture with status indicator
- `<StatusBadge />` - Colored status indicators
- `<PriorityIcon />` - Priority level icons

---

## 🔌 Real-time Features

### Subscribe to Ticket Updates

```typescript
import { useRealtime } from '@/hooks/useRealtime'

function TicketFeed() {
  const { tickets, loading } = useRealtime('tickets', {
    event: '*',
    schema: 'public',
    table: 'tickets',
  })

  return (
    <div>
      {tickets.map(ticket => (
        <TicketCard key={ticket.id} ticket={ticket} />
      ))}
    </div>
  )
}
```

### Live Agent Status

```typescript
import { subscribeToAgentStatus } from '@/lib/supabase'

useEffect(() => {
  const subscription = subscribeToAgentStatus((payload) => {
    // Update agent status in real-time
    updateAgentStatus(payload.new)
  })

  return () => subscription.unsubscribe()
}, [])
```

---

## 📊 Analytics Integration

### Fetch Daily Metrics

```typescript
import { analyticsQueries } from '@/lib/supabase'

const metrics = await analyticsQueries.getDailyMetrics(7)

// Display in charts
<LineChart
  data={metrics}
  xKey="date"
  yKeys={['total_tickets', 'tickets_resolved']}
/>
```

### Real-time SLA Monitoring

```typescript
const slaRisks = await analyticsQueries.getSLABreachRisk()

// Show alerts for tickets at risk
{slaRisks.filter(t => t.risk_level === 'CRITICAL').map(ticket => (
  <Alert variant="destructive">
    Ticket #{ticket.id} breaching SLA in {ticket.minutes_remaining} minutes
  </Alert>
))}
```

---

## 🎨 Theming

### Custom Theme Colors

Edit `styles/globals.css`:

```css
:root {
  --primary: 221 83% 53%;     /* Blue */
  --secondary: 210 40% 96%;   /* Light gray */
  --accent: 142 76% 36%;      /* Green */
  --destructive: 0 84% 60%;   /* Red */
}

.dark {
  --primary: 217 91% 60%;
  --secondary: 217 33% 17%;
}
```

### Dark Mode Toggle

```typescript
import { useTheme } from 'next-themes'

function ThemeToggle() {
  const { theme, setTheme } = useTheme()

  return (
    <Button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>
      Toggle Theme
    </Button>
  )
}
```

---

## 🔐 Authentication (Optional)

### Supabase Auth Integration

```typescript
// lib/auth.ts
import { supabase } from './supabase'

export const signIn = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })
  return { data, error }
}

export const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  return { error }
}

// Protected route example
export const requireAuth = async () => {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) {
    redirect('/login')
  }
  return session
}
```

---

## 🚀 Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel


```

### Docker

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t support-platform-frontend .
docker run -p 3000:3000 support-platform-frontend
```

---

## 🧪 Testing

### Unit Tests (Jest + React Testing Library)

```bash
npm install --save-dev jest @testing-library/react @testing-library/jest-dom
```

Example test:
```typescript
import { render, screen } from '@testing-library/react'
import { TicketCard } from '@/components/tickets/TicketCard'

test('displays ticket subject', () => {
  const ticket = {
    id: '1',
    subject: 'Test Ticket',
    status: 'new',
    priority: 'high',
  }

  render(<TicketCard ticket={ticket} />)
  expect(screen.getByText('Test Ticket')).toBeInTheDocument()
})
```

---

## 📱 Mobile App (Future)

Convert to React Native or use Capacitor:

```bash
# Capacitor setup
npm install @capacitor/core @capacitor/cli
npx cap init
npx cap add ios
npx cap add android
```

---

## 🔧 Troubleshooting

### Build Errors

**"Module not found"**
```bash
rm -rf node_modules .next
npm install
npm run build
```

**Supabase connection issues**
- Check environment variables
- Verify Supabase URL and key
- Check network/firewall

### Real-time Not Working

- Ensure Realtime is enabled in Supabase dashboard
- Check table permissions (RLS policies)
- Verify subscription channel names

---

## 📚 Resources

- **Next.js Docs**: https://nextjs.org/docs
- **shadcn/ui**: https://ui.shadcn.com
- **Supabase Docs**: https://supabase.com/docs
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Recharts**: https://recharts.org

---

## 🎯 Next Steps

1. **Build the Agent Dashboard** - Start with the main ticket feed
2. **Add Real-time Updates** - Implement Supabase subscriptions
3. **Create Customer Portal** - Build ticket submission form
4. **Add Analytics Charts** - Integrate Recharts
5. **Deploy to Vercel** - Get it live!

--
