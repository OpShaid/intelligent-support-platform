#!/bin/bash



set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║   Intelligent Support Triage System - Setup Script        ║
║   AI-Powered Customer Support Automation                  ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running from project root
if [ ! -f "README.md" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 1: Prerequisites Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check for Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js installed: ${NODE_VERSION}"
else
    echo -e "${RED}✗${NC} Node.js not found. Please install Node.js 16+ from https://nodejs.org/"
    exit 1
fi

# Check for psql (optional but helpful)
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✓${NC} PostgreSQL client installed"
else
    echo -e "${YELLOW}⚠${NC} PostgreSQL client (psql) not found. You can still use Supabase web interface."
fi

# Check for curl
if command -v curl &> /dev/null; then
    echo -e "${GREEN}✓${NC} curl installed"
else
    echo -e "${RED}✗${NC} curl not found. Please install curl."
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 2: Environment Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓${NC} .env file created"
    echo -e "${YELLOW}⚠ Important: Edit .env file with your actual credentials${NC}"
    echo ""
else
    echo -e "${GREEN}✓${NC} .env file already exists"
fi

echo -e "${YELLOW}You need to configure:${NC}"
echo "  1. Supabase database connection (DATABASE_URL)"
echo "  2. OpenAI API key (OPENAI_API_KEY)"
echo "  3. Slack bot token (SLACK_BOT_TOKEN) - optional"
echo "  4. Email credentials (EMAIL_IMAP_*, EMAIL_SMTP_*) - optional"
echo ""

read -p "Have you configured your .env file? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please edit the .env file and run this script again.${NC}"
    exit 0
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 3: Database Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Choose your database setup method:"
echo "  1. Supabase (Web Interface) - Recommended"
echo "  2. PostgreSQL (Command Line)"
echo "  3. Skip (already done)"
echo ""
read -p "Enter choice (1-3): " db_choice

case $db_choice in
    1)
        echo ""
        echo -e "${YELLOW}Supabase Setup Instructions:${NC}"
        echo ""
        echo "1. Go to: https://supabase.com/dashboard"
        echo "2. Create a new project (or select existing)"
        echo "3. Go to SQL Editor"
        echo "4. Copy and paste contents of: database/migrations/001_create_core_tables.sql"
        echo "5. Click 'Run' to execute"
        echo "6. Then copy and paste: database/seeds/002_seed_initial_data.sql"
        echo "7. Click 'Run' to execute"
        echo ""
        echo -e "${GREEN}Files location:${NC}"
        echo "  - $(pwd)/database/migrations/001_create_core_tables.sql"
        echo "  - $(pwd)/database/seeds/002_seed_initial_data.sql"
        echo ""
        read -p "Press Enter when done..."
        ;;
    2)
        if [ -z "$DATABASE_URL" ]; then
            echo -e "${RED}ERROR: DATABASE_URL not set in .env file${NC}"
            exit 1
        fi

        echo -e "${YELLOW}Running database migrations...${NC}"

        if command -v psql &> /dev/null; then
            echo "Creating tables..."
            psql "$DATABASE_URL" -f database/migrations/001_create_core_tables.sql

            echo "Seeding initial data..."
            psql "$DATABASE_URL" -f database/seeds/002_seed_initial_data.sql

            echo -e "${GREEN}✓${NC} Database setup complete!"
        else
            echo -e "${RED}psql command not found. Please use Supabase web interface.${NC}"
            exit 1
        fi
        ;;
    3)
        echo -e "${GREEN}✓${NC} Skipping database setup"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 4: Generate Test Data${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -p "Generate test tickets? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "How many test tickets? (default: 20) " ticket_count
    ticket_count=${ticket_count:-20}

    echo -e "${YELLOW}Generating ${ticket_count} test tickets...${NC}"
    node scripts/generate-test-tickets.js $ticket_count sql > database/seeds/003_test_tickets.sql

    echo -e "${GREEN}✓${NC} Test tickets generated: database/seeds/003_test_tickets.sql"
    echo ""
    echo "To load test tickets into database:"
    echo "  Option 1: Copy 003_test_tickets.sql into Supabase SQL Editor"
    echo "  Option 2: Run: psql \$DATABASE_URL -f database/seeds/003_test_tickets.sql"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 5: N8N Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Choose your N8N setup:"
echo "  1. N8N Cloud (Easiest)"
echo "  2. Docker (Local)"
echo "  3. Skip (already done)"
echo ""
read -p "Enter choice (1-3): " n8n_choice

case $n8n_choice in
    1)
        echo ""
        echo -e "${YELLOW}N8N Cloud Setup:${NC}"
        echo ""
        echo "1. Go to: https://n8n.cloud"
        echo "2. Sign up for free account"
        echo "3. Create a new instance"
        echo "4. Follow the workflow setup guide in: docs/n8n-workflow-guide.md"
        echo ""
        read -p "Press Enter when done..."
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Starting N8N with Docker...${NC}"

        if command -v docker &> /dev/null; then
            echo "Starting N8N on http://localhost:5678"
            docker run -d --name n8n \
                -p 5678:5678 \
                -v ~/.n8n:/home/node/.n8n \
                n8nio/n8n

            echo -e "${GREEN}✓${NC} N8N started successfully!"
            echo "Access N8N at: http://localhost:5678"
            echo ""
            echo "Next steps:"
            echo "  1. Open http://localhost:5678 in your browser"
            echo "  2. Create your admin account"
            echo "  3. Follow the workflow setup guide: docs/n8n-workflow-guide.md"
        else
            echo -e "${RED}Docker not found. Please install Docker first.${NC}"
            echo "Download from: https://www.docker.com/get-started"
        fi
        ;;
    3)
        echo -e "${GREEN}✓${NC} Skipping N8N setup"
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}✓ Database schema created${NC}"
echo -e "${GREEN}✓ Initial data seeded${NC}"
echo -e "${GREEN}✓ Environment configured${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Build N8N workflows (see docs/n8n-workflow-guide.md)"
echo "2. Test the system with:"
echo "   - Send test webhook: scripts/test-webhook.sh"
echo "   - Generate test tickets: node scripts/generate-test-tickets.js 10"
echo ""
echo "3. Documentation:"
echo "   - README.md - Project overview"
echo "   - docs/n8n-workflow-guide.md - Workflow setup"
echo "   - docs/troubleshooting.md - Common issues"
echo ""
echo -e "${BLUE}Need help? Check the documentation or file an issue.${NC}"
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"
