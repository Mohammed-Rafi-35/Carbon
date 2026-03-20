#!/bin/bash

echo "🚀 Carbon Backend - Docker Deployment"
echo "======================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Get host IP address
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
elif [[ "$OSTYPE" == "darwin"* ]]; then
    HOST_IP=$(ipconfig getifaddr en0)
else
    HOST_IP=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "📡 Network Configuration:"
echo "   Host IP: $HOST_IP"
echo "   Backend will be accessible at: http://$HOST_IP:8000"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from .env.docker template..."
    cp .env.docker .env
    echo "✅ Created .env file. Please review and update if needed."
fi

# Build and start containers
echo "🔨 Building Docker images..."
docker-compose build

echo ""
echo "🚀 Starting containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✅ Carbon Backend is running!"
    echo ""
    echo "📚 Access Points:"
    echo "   API Docs:    http://$HOST_IP:8000/docs"
    echo "   Health:      http://$HOST_IP:8000/health"
    echo "   Database:    localhost:5432"
    echo ""
    echo "📱 Mobile App Configuration:"
    echo "   1. Open Carbon app"
    echo "   2. Long-press logo on login screen"
    echo "   3. Enter: http://$HOST_IP:8000"
    echo "   4. Test connection and save"
    echo ""
    echo "🔍 View logs: docker-compose logs -f"
    echo "🛑 Stop: docker-compose down"
else
    echo ""
    echo "❌ Failed to start services. Check logs:"
    echo "   docker-compose logs"
fi
