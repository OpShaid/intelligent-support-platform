'use client'

import { useEffect, useState } from 'react'
import { supabase, subscribeToTickets, analyticsQueries } from '@/lib/supabase'
import { Database } from '@/types/database'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Inbox,
  Clock,
  CheckCircle2,
  AlertTriangle,
  TrendingUp,
  TrendingDown,
  Bot,
  Users,
} from 'lucide-react'

type Ticket = Database['public']['Views']['active_tickets_view']['Row']
type Metrics = {
  total: number
  new: number
  assigned: number
  in_progress: number
  resolved_today: number
  sla_compliance: number
}

export default function AgentDashboard() {
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [metrics, setMetrics] = useState<Metrics | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboard()

    // Real-time subscription
    const subscription = subscribeToTickets((payload) => {
      console.log('New ticket update:', payload)
      loadDashboard() // Refresh dashboard
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  async function loadDashboard() {
    try {
      // Fetch active tickets
      const { data: ticketsData, error: ticketsError } = await supabase
        .from('active_tickets_view')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(10)

      if (ticketsError) throw ticketsError

      // Calculate metrics
      const { count: totalCount } = await supabase
        .from('tickets')
        .select('*', { count: 'exact', head: true })

      const { count: newCount } = await supabase
        .from('tickets')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'new')

      const { count: assignedCount } = await supabase
        .from('tickets')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'assigned')

      const { count: inProgressCount } = await supabase
        .from('tickets')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'in_progress')

      const { count: resolvedToday } = await supabase
        .from('tickets')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'resolved')
        .gte('resolved_at', new Date().toISOString().split('T')[0])

      setTickets(ticketsData || [])
      setMetrics({
        total: totalCount || 0,
        new: newCount || 0,
        assigned: assignedCount || 0,
        in_progress: inProgressCount || 0,
        resolved_today: resolvedToday || 0,
        sla_compliance: 94.5,
      })
      setLoading(false)
    } catch (error) {
      console.error('Error loading dashboard:', error)
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="container mx-auto px-6 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Agent Dashboard
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">
                Welcome back! Here's what's happening today.
              </p>
            </div>
            <div className="flex gap-3">
              <Button variant="outline">
                <Clock className="w-4 h-4 mr-2" />
                Recent Activity
              </Button>
              <Button>
                <Inbox className="w-4 h-4 mr-2" />
                View All Tickets
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-6 py-8">
        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <MetricCard
            title="New Tickets"
            value={metrics?.new || 0}
            icon={<Inbox className="w-5 h-5" />}
            trend={+12}
            color="blue"
          />
          <MetricCard
            title="In Progress"
            value={metrics?.in_progress || 0}
            icon={<Clock className="w-5 h-5" />}
            trend={-5}
            color="yellow"
          />
          <MetricCard
            title="Resolved Today"
            value={metrics?.resolved_today || 0}
            icon={<CheckCircle2 className="w-5 h-5" />}
            trend={+8}
            color="green"
          />
          <MetricCard
            title="SLA Compliance"
            value={`${metrics?.sla_compliance || 0}%`}
            icon={<AlertTriangle className="w-5 h-5" />}
            trend={+2.5}
            color="purple"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Tickets */}
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Recent Tickets</span>
                <Badge variant="secondary">{tickets.length} active</Badge>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {tickets.map((ticket) => (
                  <TicketItem key={ticket.id} ticket={ticket} />
                ))}
              </div>
            </CardContent>
          </Card>

          {/* AI Insights */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Bot className="w-5 h-5 text-blue-600" />
                AI Insights
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <InsightItem
                  title="Classification Accuracy"
                  value="92%"
                  trend="up"
                  description="AI correctly classified 46 of 50 tickets"
                />
                <InsightItem
                  title="Auto-Resolved"
                  value="18 tickets"
                  trend="up"
                  description="36% of tickets auto-resolved today"
                />
                <InsightItem
                  title="Avg Confidence"
                  value="87%"
                  trend="neutral"
                  description="AI confidence remains high"
                />
                <InsightItem
                  title="Top Category"
                  value="Billing"
                  trend="up"
                  description="42% increase in billing inquiries"
                />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Agent Leaderboard */}
        <Card className="mt-6">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5" />
              Team Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <AgentCard name="Sarah Johnson" tickets={34} satisfaction={4.8} rank={1} />
              <AgentCard name="Mike Chen" tickets={28} satisfaction={4.6} rank={2} />
              <AgentCard name="Alex Rivera" tickets={31} satisfaction={4.9} rank={3} />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function MetricCard({ title, value, icon, trend, color }: any) {
  const colors = {
    blue: 'bg-blue-100 text-blue-600',
    yellow: 'bg-yellow-100 text-yellow-600',
    green: 'bg-green-100 text-green-600',
    purple: 'bg-purple-100 text-purple-600',
  }

  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div className={`p-3 rounded-lg ${colors[color]}`}>{icon}</div>
          <div className="flex items-center gap-1 text-sm">
            {trend > 0 ? (
              <TrendingUp className="w-4 h-4 text-green-600" />
            ) : (
              <TrendingDown className="w-4 h-4 text-red-600" />
            )}
            <span className={trend > 0 ? 'text-green-600' : 'text-red-600'}>
              {Math.abs(trend)}%
            </span>
          </div>
        </div>
        <h3 className="text-2xl font-bold mt-4 text-gray-900 dark:text-white">{value}</h3>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">{title}</p>
      </CardContent>
    </Card>
  )
}

function TicketItem({ ticket }: { ticket: Ticket }) {
  const priorityColors = {
    urgent: 'bg-red-100 text-red-800',
    high: 'bg-orange-100 text-orange-800',
    medium: 'bg-yellow-100 text-yellow-800',
    low: 'bg-green-100 text-green-800',
  }

  return (
    <div className="flex items-start gap-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer">
      <div className="flex-1">
        <div className="flex items-center gap-2 mb-1">
          <h4 className="font-semibold text-gray-900 dark:text-white">{ticket.subject}</h4>
          <Badge className={priorityColors[ticket.priority]}>{ticket.priority}</Badge>
          {ticket.sentiment_emotion && (
            <Badge variant="outline">{ticket.sentiment_emotion}</Badge>
          )}
        </div>
        <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-1">{ticket.body}</p>
        <div className="flex items-center gap-3 mt-2 text-xs text-gray-500">
          <span>{ticket.sender_name}</span>
          <span>•</span>
          <span>{ticket.ai_category || 'Uncategorized'}</span>
          <span>•</span>
          <span>{new Date(ticket.created_at).toLocaleTimeString()}</span>
        </div>
      </div>
      <Button size="sm" variant="ghost">View</Button>
    </div>
  )
}

function InsightItem({ title, value, trend, description }: any) {
  return (
    <div className="flex items-start justify-between">
      <div>
        <p className="text-sm font-medium text-gray-900 dark:text-white">{title}</p>
        <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">{description}</p>
      </div>
      <div className="text-right">
        <p className="font-semibold text-gray-900 dark:text-white">{value}</p>
        {trend === 'up' && <TrendingUp className="w-4 h-4 text-green-600 ml-auto" />}
      </div>
    </div>
  )
}

function AgentCard({ name, tickets, satisfaction, rank }: any) {
  const medals = ['🥇', '🥈', '🥉']

  return (
    <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
      <div className="flex items-center gap-3">
        <div className="text-2xl">{medals[rank - 1]}</div>
        <div className="flex-1">
          <h4 className="font-semibold text-gray-900 dark:text-white">{name}</h4>
          <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
            <span>{tickets} tickets</span>
            <span>⭐ {satisfaction}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
