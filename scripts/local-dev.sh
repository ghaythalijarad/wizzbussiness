#!/bin/bash

# Local Development Setup Script
# This script sets up the local development environment for testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🛠️  Setting up Local Development Environment"
echo "==========================================="

# Function to install Python dependencies
setup_backend() {
    echo -e "${BLUE}Setting up Python backend...${NC}"
    
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}Creating Python virtual environment...${NC}"
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip install -r requirements.txt
    
    if [ -f "backend/requirements.txt" ]; then
        pip install -r backend/requirements.txt
    fi
    
    # Install development dependencies
    pip install pytest pytest-cov black flake8 boto3 moto
    
    echo -e "${GREEN}✅ Backend setup complete${NC}"
}

# Function to setup Flutter frontend
setup_frontend() {
    echo -e "${BLUE}Setting up Flutter frontend...${NC}"
    
    cd frontend
    
    echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
    flutter pub get
    
    echo -e "${YELLOW}Running Flutter doctor...${NC}"
    flutter doctor
    
    echo -e "${YELLOW}Analyzing Flutter code...${NC}"
    flutter analyze
    
    cd ..
    
    echo -e "${GREEN}✅ Frontend setup complete${NC}"
}

# Function to setup SAM CLI
setup_sam() {
    echo -e "${BLUE}Setting up SAM CLI...${NC}"
    
    if ! command -v sam &> /dev/null; then
        echo -e "${YELLOW}SAM CLI not found. Please install it manually:${NC}"
        echo "https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html"
        return 1
    fi
    
    echo -e "${YELLOW}Building SAM application...${NC}"
    cd infrastructure
    sam build
    cd ..
    
    echo -e "${GREEN}✅ SAM setup complete${NC}"
}

# Function to run tests
run_tests() {
    echo -e "${BLUE}Running tests...${NC}"
    
    # Backend tests
    echo -e "${YELLOW}Running backend tests...${NC}"
    source venv/bin/activate
    cd backend
    python -m pytest tests/ -v
    cd ..
    
    # Frontend tests
    echo -e "${YELLOW}Running frontend tests...${NC}"
    cd frontend
    flutter test
    cd ..
    
    echo -e "${GREEN}✅ All tests passed${NC}"
}

# Function to start local development servers
start_local_servers() {
    echo -e "${BLUE}Starting local development servers...${NC}"
    
    # Start SAM local API
    echo -e "${YELLOW}Starting SAM local API on port 3000...${NC}"
    cd infrastructure
    sam local start-api --port 3000 &
    SAM_PID=$!
    cd ..
    
    # Wait a moment for SAM to start
    sleep 5
    
    # Start Flutter web server
    echo -e "${YELLOW}Starting Flutter web server on port 8080...${NC}"
    cd frontend
    flutter run -d web-server --web-port=8080 &
    FLUTTER_PID=$!
    cd ..
    
    echo -e "${GREEN}✅ Local servers started${NC}"
    echo -e "${BLUE}API: http://localhost:3000${NC}"
    echo -e "${BLUE}Web: http://localhost:8080${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop servers${NC}"
    
    # Cleanup function
    cleanup() {
        echo -e "\n${YELLOW}Stopping servers...${NC}"
        kill $SAM_PID 2>/dev/null || true
        kill $FLUTTER_PID 2>/dev/null || true
        echo -e "${GREEN}Servers stopped${NC}"
        exit 0
    }
    
    trap cleanup INT
    wait
}

# Function to check environment
check_environment() {
    echo -e "${BLUE}Checking development environment...${NC}"
    
    # Check Python
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✅ Python3: $(python3 --version)${NC}"
    else
        echo -e "${RED}❌ Python3 not found${NC}"
        exit 1
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        echo -e "${GREEN}✅ Flutter: $(flutter --version | head -n1)${NC}"
    else
        echo -e "${RED}❌ Flutter not found${NC}"
        exit 1
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        echo -e "${GREEN}✅ AWS CLI: $(aws --version)${NC}"
    else
        echo -e "${YELLOW}⚠️  AWS CLI not found (optional for local development)${NC}"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker not found (needed for SAM local)${NC}"
    fi
}

# Main function
main() {
    case "${1:-setup}" in
        "setup")
            check_environment
            setup_backend
            setup_frontend
            setup_sam
            echo -e "${GREEN}🎉 Development environment setup complete!${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Run tests: ./scripts/local-dev.sh test"
            echo "2. Start servers: ./scripts/local-dev.sh start"
            echo "3. Check status: ./scripts/check-deployment-status.sh"
            ;;
        "test")
            run_tests
            ;;
        "start")
            start_local_servers
            ;;
        "check")
            check_environment
            ;;
        *)
            echo "Usage: $0 [setup|test|start|check]"
            echo ""
            echo "Commands:"
            echo "  setup  - Set up development environment (default)"
            echo "  test   - Run all tests"
            echo "  start  - Start local development servers"
            echo "  check  - Check environment requirements"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
