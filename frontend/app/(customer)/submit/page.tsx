'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { AlertCircle, CheckCircle2, Upload, Send } from 'lucide-react'
import { Alert, AlertDescription } from '@/components/ui/alert'

export default function SubmitTicket() {
  const router = useRouter()
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    category: '',
    subject: '',
    message: '',
  })
  const [files, setFiles] = useState<File[]>([])
  const [submitting, setSubmitting] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [ticketId, setTicketId] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    try {
      // Submit to N8N webhook
      const webhookUrl = process.env.NEXT_PUBLIC_N8N_WEBHOOK_URL

      const response = await fetch(webhookUrl!, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email,
          name: formData.name,
          subject: formData.subject,
          message: formData.message,
          category: formData.category,
          source: 'web_portal',
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to submit ticket')
      }

      const result = await response.json()
      setTicketId(result.ticket_id)
      setSuccess(true)

      // Reset form
      setFormData({
        name: '',
        email: '',
        category: '',
        subject: '',
        message: '',
      })
      setFiles([])
    } catch (err: any) {
      setError(err.message || 'Failed to submit ticket. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (e.target.files) {
      setFiles(Array.from(e.target.files))
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-green-50 to-white dark:from-gray-900 dark:to-gray-800 flex items-center justify-center p-6">
        <Card className="max-w-lg w-full">
          <CardContent className="pt-12 pb-12 text-center">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <CheckCircle2 className="w-10 h-10 text-green-600" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Ticket Submitted Successfully!
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              We've received your support request and our AI is already analyzing it.
              You'll receive an email confirmation shortly.
            </p>
            <div className="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg mb-6">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">Your Ticket ID:</p>
              <p className="text-2xl font-mono font-bold text-blue-600">
                {ticketId.substring(0, 8).toUpperCase()}
              </p>
            </div>
            <div className="flex gap-3 justify-center">
              <Button onClick={() => router.push(`/track/${ticketId}`)}>
                Track Status
              </Button>
              <Button variant="outline" onClick={() => setSuccess(false)}>
                Submit Another
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-2xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-3">
              Submit a Support Request
            </h1>
            <p className="text-lg text-gray-600 dark:text-gray-400">
              Our AI will analyze your request and route it to the right team.
              <br />
              Average response time: <span className="font-semibold text-blue-600">32 minutes</span>
            </p>
          </div>

          {/* Form */}
          <Card>
            <CardHeader>
              <CardTitle>Tell us how we can help</CardTitle>
              <CardDescription>
                Please provide as much detail as possible to help us resolve your issue quickly.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Contact Information */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="name">Full Name *</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="John Doe"
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="email">Email Address *</Label>
                    <Input
                      id="email"
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      placeholder="john@example.com"
                      required
                    />
                  </div>
                </div>

                {/* Category */}
                <div>
                  <Label htmlFor="category">Category *</Label>
                  <Select
                    value={formData.category}
                    onValueChange={(value) => setFormData({ ...formData, category: value })}
                  >
                    <SelectTrigger id="category">
                      <SelectValue placeholder="Select a category" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="billing">💳 Billing & Payments</SelectItem>
                      <SelectItem value="technical">🔧 Technical Support</SelectItem>
                      <SelectItem value="account">👤 Account & Access</SelectItem>
                      <SelectItem value="general">💬 General Question</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Subject */}
                <div>
                  <Label htmlFor="subject">Subject *</Label>
                  <Input
                    id="subject"
                    value={formData.subject}
                    onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                    placeholder="Brief description of your issue"
                    required
                  />
                </div>

                {/* Message */}
                <div>
                  <Label htmlFor="message">Message *</Label>
                  <Textarea
                    id="message"
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                    placeholder="Please describe your issue in detail..."
                    rows={6}
                    required
                  />
                  <p className="text-sm text-gray-500 mt-1">
                    Minimum 20 characters ({formData.message.length}/20)
                  </p>
                </div>

                {/* File Upload */}
                <div>
                  <Label htmlFor="files">Attachments (Optional)</Label>
                  <div className="mt-2">
                    <label
                      htmlFor="files"
                      className="flex items-center justify-center gap-2 w-full p-6 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-blue-500 cursor-pointer transition-colors"
                    >
                      <Upload className="w-5 h-5 text-gray-400" />
                      <span className="text-sm text-gray-600 dark:text-gray-400">
                        {files.length > 0
                          ? `${files.length} file(s) selected`
                          : 'Click to upload or drag and drop'}
                      </span>
                    </label>
                    <input
                      id="files"
                      type="file"
                      multiple
                      onChange={handleFileChange}
                      className="hidden"
                      accept="image/*,.pdf,.doc,.docx"
                    />
                  </div>
                  {files.length > 0 && (
                    <div className="mt-2 space-y-1">
                      {files.map((file, index) => (
                        <div key={index} className="text-sm text-gray-600 dark:text-gray-400">
                          📎 {file.name} ({(file.size / 1024).toFixed(1)} KB)
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Error Alert */}
                {error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                {/* Submit Button */}
                <Button
                  type="submit"
                  disabled={submitting || formData.message.length < 20}
                  className="w-full"
                  size="lg"
                >
                  {submitting ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                      Submitting...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4 mr-2" />
                      Submit Ticket
                    </>
                  )}
                </Button>
              </form>

              {/* Help Text */}
              <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <h4 className="font-semibold text-blue-900 dark:text-blue-300 mb-2">
                  What happens next?
                </h4>
                <ul className="text-sm text-blue-800 dark:text-blue-400 space-y-1">
                  <li>✓ AI will analyze and categorize your ticket</li>
                  <li>✓ You'll receive an email confirmation with your ticket ID</li>
                  <li>✓ Our team will respond within our SLA (typically 1-4 hours)</li>
                  <li>✓ You can track progress using the ticket ID</li>
                </ul>
              </div>
            </CardContent>
          </Card>

          {/* FAQ Section */}
          <div className="mt-8 text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Looking for quick answers?{' '}
              <a href="/help" className="text-blue-600 hover:underline font-medium">
                Check our Knowledge Base
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
