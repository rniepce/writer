#!/bin/bash
# Backend launcher script for ZenWriter
# This is executed by the Tauri app on startup

cd "$(dirname "$0")/../backend" || exit 1

# Check if required files exist
if [ ! -f "main.py" ]; then
    echo "Error: main.py not found"
    exit 1
fi

# Kill any existing process on port 8001
lsof -ti:8001 | xargs kill -9 2>/dev/null

# Use venv if available, otherwise use system python
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start the backend
exec python -m uvicorn main:app --host 127.0.0.1 --port 8001 --log-level warning
