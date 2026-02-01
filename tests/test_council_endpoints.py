
import requests
import json
import time

def test_polish_endpoint():
    url = "http://127.0.0.1:8001/council/polish"
    
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
            
            print("\n=== Models ===")
            print(f"Claude Focus: {data['claude_style']['focus']}")
            # print(f"Claude Analysis: {data['claude_style']['analysis'][:100]}...")
            
            print(f"Gemini Focus: {data['gemini_coherence']['focus']}")
            
            print(f"GPT Focus: {data['gpt_structure']['focus']}")
            
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"Connection failed: {e}")
        print("Make sure the backend is running.")

if __name__ == "__main__":
    test_polish_endpoint()
