
import sys
import os

# Add the parent directory to sys.path
sys.path.append(os.getcwd())

try:
    print("Attempting to import backend.orchestrator...")
    from backend.orchestrator import council
    print("Import successful.")
    print("Editorial Council initialized:", council)
except Exception as e:
    print(f"FAILED to import/init: {e}")
    import traceback
    traceback.print_exc()
