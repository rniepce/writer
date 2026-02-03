
import requests
import json
import time
import sys

def test_polish_endpoint(base_url):
    # Ensure no trailing slash
    base_url = base_url.rstrip('/')
    url = f"{base_url}/council/polish"
    
    payload = {
        "text": "O sol batia na janela. Ele sentiu que perdera algo importante. A xícara de café estava fria sobre a mesa de madeira.",
        "manuscript_context": "Protagonista é um filósofo cínico que acabou de perder a esposa.",
        "project_name": "O Vazio da Tarde",
        "style_ref": "Prosa de Pensamento (Lerner/Cusk)",
        "chapter": "3",
        "scene": "Café da manhã solitário",
        "emotional_state": "Melancolia analítica"
    }
    
    print(f"Sending payload to {url}...")
    try:
        start_time = time.time()
        response = requests.post(url, json=payload)
        duration = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            print(f"Success! (Took {duration:.2f}s)")
            print("\n=== Polish Report ===")
            print(f"Consensus: {data.get('consensus')}")
            print(f"Divergence: {data.get('divergence')}")
            print(f"Verdict: {data.get('verdict')}")
            return True
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
            return False
            
    except Exception as e:
        print(f"Connection failed: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python verify_remote.py <RAILWAY_URL>")
        sys.exit(1)
        
    url = sys.argv[1]
    test_polish_endpoint(url)
