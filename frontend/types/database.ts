export type Database = {
  public: {
    Tables: {
      tickets: {
        Row: {
          id: string
          idempotency_key: string
          channel: 'email' | 'slack' | 'api' | 'web' | 'phone'
          sender_email: string
          sender_name: string | null
          subject: string
          body: string
          attachments: any
          category: string | null
          sub_category: string | null
          tags: string[] | null
          status: 'new' | 'analyzing' | 'analyzed' | 'assigned' | 'in_progress' | 'waiting_customer' | 'resolved' | 'closed' | 'spam'
          priority: 'urgent' | 'high' | 'medium' | 'low'
          assigned_to: string | null
          assigned_at: string | null
          team_id: string | null
          sla_deadline: string | null
          first_response_at: string | null
          resolved_at: string | null
          closed_at: string | null
          is_spam: boolean
          is_escalated: boolean
          escalated_to: string | null
          raw_metadata: any
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['tickets']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['tickets']['Insert']>
      }
      ai_analysis: {
        Row: {
          id: string
          ticket_id: string
          category: string
          sub_category: string | null
          confidence: number
          sentiment_emotion: string | null
          sentiment_intensity: number | null
          priority_recommendation: string | null
          urgency_score: number | null
          escalation_flag: boolean
          escalation_reason: string | null
          reasoning: any
          model_name: string
          model_version: string | null
          prompt_tokens: number | null
          completion_tokens: number | null
          total_cost: number | null
          created_at: string
        }
      }
      agents: {
        Row: {
          id: string
          email: string
          name: string
          avatar_url: string | null
          team_id: string | null
          role: 'agent' | 'senior_agent' | 'team_lead' | 'manager'
          skill_level: 'junior' | 'mid' | 'senior' | 'expert'
          specializations: string[] | null
          max_concurrent_tickets: number
          is_available: boolean
          availability_status: 'online' | 'away' | 'busy' | 'offline'
          slack_user_id: string | null
          slack_dm_channel_id: string | null
          created_at: string
          updated_at: string
          last_active_at: string | null
        }
      }
      teams: {
        Row: {
          id: string
          name: string
          description: string | null
          handles_categories: string[] | null
          slack_channel_id: string | null
          slack_channel_name: string | null
          created_at: string
          updated_at: string
        }
      }
      responses: {
        Row: {
          id: string
          ticket_id: string
          direction: 'outbound' | 'inbound'
          channel: 'email' | 'slack' | 'phone' | 'chat'
          subject: string | null
          body: string
          attachments: any
          sender_type: 'agent' | 'customer' | 'system' | 'ai'
          sender_id: string | null
          sender_name: string | null
          was_ai_generated: boolean
          ai_draft: boolean
          ai_model: string | null
          agent_edited: boolean
          sent_at: string | null
          created_at: string
        }
      }
      analytics_daily: {
        Row: {
          id: string
          date: string
          total_tickets: number
          tickets_resolved: number
          tickets_auto_resolved: number
          resolution_rate: number | null
          avg_first_response_minutes: number | null
          avg_resolution_hours: number | null
          median_resolution_hours: number | null
          sla_compliance_rate: number | null
          sla_breaches: number
          tickets_by_channel: any
          tickets_by_category: any
          tickets_by_priority: any
          ai_classification_accuracy: number | null
          ai_responses_generated: number
          ai_responses_sent: number
          avg_ai_confidence: number | null
          active_agents: number
          avg_tickets_per_agent: number | null
          total_ai_cost: number | null
          created_at: string
          updated_at: string
        }
      }
    }
    Views: {
      active_tickets_view: {
        Row: Database['public']['Tables']['tickets']['Row'] & {
          ai_category: string | null
          ai_sub_category: string | null
          ai_confidence: number | null
          sentiment_emotion: string | null
          sentiment_intensity: number | null
          escalation_flag: boolean | null
          agent_name: string | null
          agent_email: string | null
          team_name: string | null
        }
      }
      agent_workload: {
        Row: {
          id: string
          name: string
          email: string
          team_id: string | null
          is_available: boolean
          max_concurrent_tickets: number
          current_tickets: number
          capacity_remaining: number
          utilization_percent: number
        }
      }
      sla_breach_risk: {
        Row: {
          id: string
          subject: string
          priority: string
          status: string
          resolution_deadline: string
          minutes_remaining: number
          risk_level: 'OK' | 'WARNING' | 'CRITICAL' | 'BREACHED'
        }
      }
    }
  }
}
