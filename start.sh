#!/bin/bash
set -e

# Start Redis in background
redis-server --daemonize yes --logfile /tmp/redis.log --port 6379

# Wait for Redis to be ready
for i in {1..10}; do
    if redis-cli ping > /dev/null 2>&1; then
        echo "Redis is ready"
        break
    fi
    echo "Waiting for Redis..."
    sleep 1
done

# Run the FastAPI app
cd services/api
PYTHONPATH=src uvicorn src.main:app --host 0.0.0.0 --port 5000 --reload
