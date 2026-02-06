#!/usr/bin/env python3
"""
ZenWriter Backend - Standalone Entry Point
This script is used by PyInstaller to create a standalone executable.
"""
import os
import sys
import uvicorn

# Add the backend directory to path for imports
if getattr(sys, 'frozen', False):
    # Running as compiled executable
    BASE_DIR = os.path.dirname(sys.executable)
else:
    # Running as script
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Set the data directory for SQLite database
DATA_DIR = os.path.expanduser("~/Library/Application Support/ZenWriter")
os.makedirs(DATA_DIR, exist_ok=True)

# Set environment variable for database path
os.environ["ZENWRITER_DATA_DIR"] = DATA_DIR

# Change to backend directory for relative imports
os.chdir(BASE_DIR)
sys.path.insert(0, BASE_DIR)

def main():
    """Start the FastAPI server."""
    print(f"ZenWriter Backend starting...")
    print(f"Data directory: {DATA_DIR}")
    print(f"Base directory: {BASE_DIR}")
    
    # Import here after path setup
    from main import app
    
    # Run uvicorn
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8001,
        log_level="info",
    )

if __name__ == "__main__":
    main()
