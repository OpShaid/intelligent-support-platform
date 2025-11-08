import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
})

// Helper functions for common queries
export const ticketQueries = {
  async getActiveTickets() {
    const { data, error } = await supabase
      .from('active_tickets_view')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    return data
  },

  async getTicketById(id: string) {
    const { data, error } = await supabase
      .from('tickets')
      .select(`
        *,
        ai_analysis (*),
        ticket_events (*),
        responses (*)
      `)
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  },

  async updateTicketStatus(id: string, status: string) {
    const { data, error } = await supabase
      .from('tickets')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  },

  async assignTicket(ticketId: string, agentId: string) {
    const { data, error } = await supabase
      .from('tickets')
      .update({
        assigned_to: agentId,
        assigned_at: new Date().toISOString(),
        status: 'assigned',
      })
      .eq('id', ticketId)
      .select()
      .single()

    if (error) throw error
    return data
  },
}

export const analyticsQueries = {
  async getDailyMetrics(days = 7) {
    const { data, error } = await supabase
      .from('analytics_daily')
      .select('*')
      .gte('date', new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString())
      .order('date', { ascending: false })

    if (error) throw error
    return data
  },

  async getAgentWorkload() {
    const { data, error } = await supabase
      .from('agent_workload')
      .select('*')
      .order('current_tickets', { ascending: false })

    if (error) throw error
    return data
  },

  async getSLABreachRisk() {
    const { data, error } = await supabase
      .from('sla_breach_risk')
      .select('*')
      .order('minutes_remaining', { ascending: true })

    if (error) throw error
    return data
  },
}

// Realtime subscriptions
export const subscribeToTickets = (callback: (payload: any) => void) => {
  return supabase
    .channel('tickets-channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'tickets',
      },
      callback
    )
    .subscribe()
}

export const subscribeToTicketEvents = (ticketId: string, callback: (payload: any) => void) => {
  return supabase
    .channel(`ticket-events-${ticketId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'ticket_events',
        filter: `ticket_id=eq.${ticketId}`,
      },
      callback
    )
    .subscribe()
}
