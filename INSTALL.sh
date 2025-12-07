#!/bin/bash



set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"

echo -e "${NC}"

echo -e "${YELLOW}This script will install:${NC}"
echo "  ✓ Database schema (Supabase/Postgres)"
echo "  ✓ N8N workflows"
echo "  ✓ Next.js frontend application"
echo "  ✓ All dependencies and configuration"
echo ""

read -p "Continue with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi



echo -e "${GREEN}Step 1: Checking Prerequisites${NC}"

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js installed: ${NODE_VERSION}"
else
    echo -e "${RED}✗${NC} Node.js not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm installed: ${NPM_VERSION}"
else
    echo -e "${RED}✗${NC} npm not found. Please install Node.js first."
    exit 1
fi

# Check Docker (optional)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker installed"
    DOCKER_INSTALLED=true
else
    echo -e "${YELLOW}⚠${NC} Docker not found (optional for local N8N)"
    DOCKER_INSTALLED=false
fi



echo -e "${GREEN}Step 2: Environment Configuration${NC}"

# Create main .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env"

    echo ""
    echo -e "${YELLOW}Please edit .env and add your credentials:${NC}"
    echo "  1. Supabase connection string"
    echo "  2. OpenAI API key"
    echo "  3. (Optional) Slack bot token"
    echo "  4. (Optional) Email credentials"
    echo ""
    read -p "Have you configured .env? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Please edit .env and run this script again.${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓${NC} .env file exists"
fi

# Create frontend .env.local
if [ ! -f "frontend/.env.local" ]; then
    echo -e "${YELLOW}Creating frontend/.env.local...${NC}"

    read -p "Enter Supabase URL: " SUPABASE_URL
    read -p "Enter Supabase Anon Key: " SUPABASE_ANON_KEY
    read -p "Enter N8N Webhook URL: " N8N_WEBHOOK_URL

    cat > frontend/.env.local << EOF
# Supabase
NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# N8N
NEXT_PUBLIC_N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL}

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_COMPANY_NAME="Your Company"
EOF

    echo -e "${GREEN}✓${NC} Created frontend/.env.local"
else
    echo -e "${GREEN}✓${NC} frontend/.env.local exists"
fi



echo -e "${GREEN}Step 3: Database Setup${NC}"

echo "Choose database setup method:"
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
        echo "4. Copy and paste: database/migrations/001_create_core_tables.sql"
        echo "5. Click 'Run'"
        echo "6. Copy and paste: database/seeds/002_seed_initial_data.sql"
        echo "7. Click 'Run'"
        echo ""
        read -p "Press Enter when done..."
        ;;
    2)
        echo -e "${YELLOW}Running database migrations...${NC}"
        source .env
        psql "$DATABASE_URL" -f database/migrations/001_create_core_tables.sql
        psql "$DATABASE_URL" -f database/seeds/002_seed_initial_data.sql
        echo -e "${GREEN}✓${NC} Database setup complete"
        ;;
    3)
        echo -e "${GREEN}✓${NC} Skipping database setup"
        ;;
esac


echo -e "${GREEN}Step 4: Frontend Installation${NC}"

cd frontend

echo -e "${YELLOW}Installing frontend dependencies...${NC}"
npm install

echo -e "${YELLOW}Installing shadcn/ui components...${NC}"
npx shadcn-ui@latest init -y

echo -e "${YELLOW}Adding UI components...${NC}"
npx shadcn-ui@latest add button card input textarea select label tabs dialog dropdown-menu table badge avatar toast alert progress separator -y

echo -e "${GREEN}✓${NC} Frontend installation complete"

cd ..



echo -e "${GREEN}Step 5: N8N Setup${NC}"

echo "Choose N8N setup:"
echo "  1. N8N Cloud (Recommended)"
echo "  2. Docker (Local)"
echo "  3. Skip (already done)"
echo ""
read -p "Enter choice (1-3): " n8n_choice

case $n8n_choice in
    1)
        echo ""
        echo -e "${YELLOW}N8N Cloud Setup:${NC}"
        echo "1. Go to: https://n8n.cloud"
        echo "2. Sign up for free account"
        echo "3. Create a new instance"
        echo "4. Follow: docs/n8n-workflow-guide.md"
        echo ""
        read -p "Press Enter when done..."
        ;;
    2)
        if [ "$DOCKER_INSTALLED" = true ]; then
            echo -e "${YELLOW}Starting N8N with Docker...${NC}"
            docker run -d --name n8n \
                -p 5678:5678 \
                -v ~/.n8n:/home/node/.n8n \
                n8nio/n8n

            echo -e "${GREEN}✓${NC} N8N started on http://localhost:5678"
        else
            echo -e "${RED}Docker not installed. Please use N8N Cloud or install Docker.${NC}"
        fi
        ;;
    3)
        echo -e "${GREEN}✓${NC} Skipping N8N setup"
        ;;
esac


echo -e "${GREEN}Step 6: Test Data Generation${NC}"

read -p "Generate test tickets? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "How many test tickets? (default: 20) " ticket_count
    ticket_count=${ticket_count:-20}

    echo -e "${YELLOW}Generating ${ticket_count} test tickets...${NC}"
    node scripts/generate-test-tickets.js $ticket_count sql > database/seeds/003_test_tickets.sql

    echo -e "${GREEN}✓${NC} Test tickets generated: database/seeds/003_test_tickets.sql"
    echo ""
    echo "To load into database:"
    echo "  Option 1: Copy 003_test_tickets.sql into Supabase SQL Editor"
    echo "  Option 2: Run: psql \$DATABASE_URL -f database/seeds/003_test_tickets.sql"
fi



echo -e "${GREEN}Installation Complete! 🎉${NC}"

echo -e "${GREEN}✓ Database schema created${NC}"
echo -e "${GREEN}✓ Frontend installed and configured${NC}"
echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo ""
echo "1. Start the frontend:"
echo "   ${BLUE}cd frontend && npm run dev${NC}"
echo "   Open: http://localhost:3000"
echo ""
echo "2. Build N8N workflows:"
echo "   Follow: ${BLUE}docs/n8n-workflow-guide.md${NC}"
echo ""
echo "3. Test the system:"
echo "   ${BLUE}./scripts/test-webhook.sh${NC}"
echo ""
echo "4. View the documentation:"
echo "   ${BLUE}cat FRONTEND_UPGRADE.md${NC}"
echo ""

echo -e "${GREEN}🎯 Quick Links:${NC}"
echo "   Frontend:  http://localhost:3000"
echo "   N8N:       http://localhost:5678 (if running locally)"
echo "   Supabase:  https://app.supabase.com"
echo ""

echo -e "${BLUE}Need help? Check the documentation or run ./scripts/setup.sh${NC}"
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"
