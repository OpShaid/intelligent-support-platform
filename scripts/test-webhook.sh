#!/bin/bash


GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'


echo -e "${BLUE}   Test Webhook - Send Sample Ticket${NC}"



if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | grep N8N_WEBHOOK_URL | xargs)
fi

if [ -z "$N8N_WEBHOOK_URL" ]; then
    read -p "Enter your N8N webhook URL: " WEBHOOK_URL
else
    WEBHOOK_URL="$N8N_WEBHOOK_URL/webhook/ticket-intake"
    echo -e "${GREEN}Using webhook URL from .env:${NC} $WEBHOOK_URL"
fi

echo ""
echo "Select ticket type to send:"
echo "  1. Password Reset (Account issue)"
echo "  2. Refund Request (Billing issue - angry customer)"
echo "  3. API Error (Technical issue - urgent)"
echo "  4. General Question (Low priority)"
echo "  5. Custom (enter your own)"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        PAYLOAD='{
          "email": "john.doe@example.com",
          "name": "John Doe",
          "subject": "Cannot reset my password",
          "message": "I clicked the forgot password link but never received the reset email. I have checked my spam folder. Please help, I need to access my account urgently."
        }'
        ;;
    2)
        PAYLOAD='{
          "email": "angry.customer@company.com",
          "name": "Sarah Smith",
          "subject": "NEED IMMEDIATE REFUND",
          "message": "I was charged $199 TWICE for my subscription. This is completely unacceptable. I want a full refund immediately or I am disputing the charges with my bank and canceling my account. This is the third time this has happened!"
        }'
        ;;
    3)
        PAYLOAD='{
          "email": "dev@startup.io",
          "name": "Alex Chen",
          "subject": "URGENT: Production API down",
          "message": "Your API has been returning 500 errors for the past hour. Our entire application is broken and we have angry customers. This is affecting our production environment with thousands of users. We need this fixed immediately!"
        }'
        ;;
    4)
        PAYLOAD='{
          "email": "curious@gmail.com",
          "name": "Lisa Johnson",
          "subject": "Question about pricing",
          "message": "Hi! I am considering upgrading to the Pro plan. Can you tell me what the differences are between the Basic and Pro plans? Also, do you offer annual billing discounts? Thanks!"
        }'
        ;;
    5)
        echo ""
        read -p "From email: " email
        read -p "From name: " name
        read -p "Subject: " subject
        echo "Message (press Ctrl+D when done):"
        message=$(cat)

        PAYLOAD=$(cat <<EOF
{
  "email": "$email",
  "name": "$name",
  "subject": "$subject",
  "message": "$message"
}
EOF
)
        ;;
    *)
        echo -e "${YELLOW}Invalid choice, using default test ticket${NC}"
        PAYLOAD='{
          "email": "test@example.com",
          "name": "Test User",
          "subject": "Test ticket",
          "message": "This is a test ticket to verify the system is working."
        }'
        ;;
esac

echo ""
echo -e "${YELLOW}Sending ticket to webhook...${NC}"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

http_body=$(echo "$response" | sed -e 's/HTTP_STATUS\:.*//g')
http_status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo -e "${BLUE}Response:${NC}"
echo "$http_body" | jq . 2>/dev/null || echo "$http_body"
echo ""

if [ "$http_status" -eq 200 ] || [ "$http_status" -eq 201 ]; then
    echo -e "${GREEN}✓ Success!${NC} Ticket created (HTTP $http_status)"
    echo ""
    echo "Next steps:"
    echo "  1. Check your database for the new ticket"
    echo "  2. Watch the AI triage workflow process it"
    echo "  3. See routing and assignment happen"
else
    echo -e "${YELLOW}⚠ Request completed with HTTP $http_status${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  - Verify webhook URL is correct"
    echo "  - Check N8N workflow is active"
    echo "  - Look at N8N execution logs"
fi

echo ""

