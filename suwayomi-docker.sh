#!/bin/bash

# Suwayomi Docker Management Script

case "$1" in
    start)
        echo "🚀 Starting Suwayomi Server..."
        mkdir -p docker-data/downloads docker-data/data
        docker compose up -d
        echo "✅ Server started on http://localhost:4568"
        ;;
    stop)
        echo "🛑 Stopping Suwayomi Server..."
        docker compose down
        echo "✅ Server stopped"
        ;;
    restart)
        echo "🔄 Restarting Suwayomi Server..."
        docker compose down
        docker compose up -d
        echo "✅ Server restarted on http://localhost:4568"
        ;;
    logs)
        echo "📋 Showing server logs (Ctrl+C to exit)..."
        docker compose logs -f suwayomi_server
        ;;
    status)
        echo "📊 Server status:"
        docker compose ps
        echo ""
        echo "🌐 Testing connection..."
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:4568/ | grep -q "200"; then
            echo "✅ Server is responding at http://localhost:4568"
        else
            echo "❌ Server is not responding"
        fi
        ;;
    update)
        echo "🔄 Updating Suwayomi Server..."
        docker compose pull
        docker compose down
        docker compose up -d
        echo "✅ Server updated and restarted"
        ;;
    backup)
        echo "💾 Creating backup of server data..."
        BACKUP_NAME="suwayomi-backup-$(date +%Y%m%d-%H%M%S)"
        tar -czf "${BACKUP_NAME}.tar.gz" docker-data/
        echo "✅ Backup created: ${BACKUP_NAME}.tar.gz"
        ;;
    *)
        echo "Suwayomi Docker Management Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|update|backup}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the server"
        echo "  stop    - Stop the server"
        echo "  restart - Restart the server"
        echo "  logs    - Show server logs"
        echo "  status  - Show server status"
        echo "  update  - Update to latest version"
        echo "  backup  - Create backup of server data"
        echo ""
        echo "Server URL: http://localhost:4568"
        exit 1
        ;;
esac