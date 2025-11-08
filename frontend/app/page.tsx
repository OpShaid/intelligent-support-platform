import Link from 'next/link'
import { ArrowRight, Bot, BarChart3, Users, Zap, Shield, Clock } from 'lucide-react'

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 px-4 py-2 rounded-full mb-6">
            <Zap className="w-4 h-4" />
            <span className="text-sm font-medium">AI-Powered Support Intelligence</span>
          </div>

          <h1 className="text-6xl font-bold text-gray-900 dark:text-white mb-6">
            Transform Your Customer Support with{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600">
              AI Automation
            </span>
          </h1>

          <p className="text-xl text-gray-600 dark:text-gray-300 mb-10 max-w-2xl mx-auto">
            Reduce response time by 80%, auto-resolve 40% of tickets, and empower your team
            with intelligent workflows powered by N8N, OpenAI, and Supabase.
          </p>

          <div className="flex gap-4 justify-center">
            <Link
              href="/agent/dashboard"
              className="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors"
            >
              Open Agent Dashboard
              <ArrowRight className="w-5 h-5" />
            </Link>

            <Link
              href="/submit"
              className="inline-flex items-center gap-2 bg-white hover:bg-gray-50 text-gray-900 px-8 py-4 rounded-lg font-semibold text-lg border-2 border-gray-200 transition-colors"
            >
              Submit a Ticket
            </Link>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-3 gap-8 mt-20 max-w-6xl mx-auto">
          <FeatureCard
            icon={<Bot className="w-8 h-8" />}
            title="AI-Powered Triage"
            description="Automatically classify, prioritize, and route tickets with 90%+ accuracy using GPT-4."
          />
          <FeatureCard
            icon={<Clock className="w-8 h-8" />}
            title="60-80% Faster Responses"
            description="Reduce first response time from hours to minutes with intelligent automation."
          />
          <FeatureCard
            icon={<BarChart3 className="w-8 h-8" />}
            title="Real-time Analytics"
            description="Track SLA compliance, agent performance, and customer satisfaction in real-time."
          />
          <FeatureCard
            icon={<Users className="w-8 h-8" />}
            title="Smart Routing"
            description="Load balance across agents with skill-based matching and VIP escalation."
          />
          <FeatureCard
            icon={<Zap className="w-8 h-8" />}
            title="Auto-Resolution"
            description="Resolve 30-40% of simple tickets automatically without human intervention."
          />
          <FeatureCard
            icon={<Shield className="w-8 h-8" />}
            title="Enterprise-Ready"
            description="Production-grade error handling, audit trails, and SLA monitoring."
          />
        </div>

        {/* Stats */}
        <div className="grid md:grid-cols-4 gap-6 mt-20 max-w-5xl mx-auto">
          <StatCard value="90%+" label="AI Accuracy" />
          <StatCard value="40%" label="Auto-Resolved" />
          <StatCard value="95%+" label="SLA Compliance" />
          <StatCard value="$5/day" label="AI Costs (1K tickets)" />
        </div>

        {/* CTA */}
        <div className="mt-20 text-center">
          <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-12 max-w-4xl mx-auto">
            <h2 className="text-3xl font-bold text-white mb-4">
              Ready to Transform Your Support?
            </h2>
            <p className="text-blue-100 mb-8 text-lg">
              Start automating your customer support with AI today.
            </p>
            <div className="flex gap-4 justify-center">
              <Link
                href="/admin/overview"
                className="inline-flex items-center gap-2 bg-white text-blue-600 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
              >
                View Admin Panel
              </Link>
              <a
                href="https://github.com/yourusername/support-intelligence"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 bg-blue-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-400 transition-colors"
              >
                View on GitHub
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow">
      <div className="text-blue-600 dark:text-blue-400 mb-4">{icon}</div>
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">{title}</h3>
      <p className="text-gray-600 dark:text-gray-400">{description}</p>
    </div>
  )
}

function StatCard({ value, label }: { value: string; label: string }) {
  return (
    <div className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700 text-center">
      <div className="text-3xl font-bold text-blue-600 dark:text-blue-400 mb-2">{value}</div>
      <div className="text-sm text-gray-600 dark:text-gray-400">{label}</div>
    </div>
  )
}
