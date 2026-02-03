
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

print("Attempting to import main...")
try:
    from main import app
    print("SUCCESS: main imported successfully.")
except Exception as e:
    print(f"CRITICAL ERROR: Failed to import main. Cause: {e}")
    import traceback
    traceback.print_exc()

print("\nChecking database configuration...")
try:
    from database import engine, Base
    print(f"Database URL: {engine.url}")
except Exception as e:
    print(f"Database Error: {e}")

print("\nChecking orchestrator imports...")
try:
    from orchestrator import council
    print("Orchestrator loaded.")
except Exception as e:
    print(f"Orchestrator Error: {e}")
