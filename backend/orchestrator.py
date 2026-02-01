"""
Orchestrator Module - The Tripartite Intelligence
Manages the three activation modes: Flow, Doubt, and Polish.
"""

import asyncio
from typing import Literal, Optional
from pydantic import BaseModel
from enum import Enum
import os
from dotenv import load_dotenv

load_dotenv()

# LangChain imports for multi-LLM
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage


class ActivationMode(str, Enum):
    FLOW = "flow"        # Passive monitoring (Gemini leads)
    DOUBT = "doubt"      # Structure analysis (GPT leads)
    POLISH = "polish"    # Full comparison (All LLMs)


class ConsistencyAlert(BaseModel):
    """Alert from Gemini when inconsistency detected."""
    type: str  # "temporal", "spatial", "character", "plot"
    severity: Literal["low", "medium", "high"]
    message: str
    suggestion: Optional[str] = None


class AnalysisResult(BaseModel):
    """Result from a single LLM analysis."""
    model: str
    focus: str  # "style", "coherence", "structure"
    analysis: str
    suggestions: list[str]


class PolishReport(BaseModel):
    """Combined report from all three LLMs."""
    gemini_coherence: AnalysisResult
    claude_style: AnalysisResult
    gpt_structure: AnalysisResult
    
    # Synthesis fields
    consensus: str
    divergence: str
    verdict: str


class EditorialCouncil:
    """
    The Tripartite Intelligence Orchestrator.
    Manages Claude (Style), Gemini (Coherence), and GPT (Structure).
    """
    
    def __init__(self):
        # Initialize the three LLMs
        # Note: Using best available models to represent the future versions requested
        self.claude = ChatAnthropic(
            model="claude-3-5-sonnet-20240620", # Represents Claude 4.5 Sonnet
            api_key=os.getenv("ANTHROPIC_API_KEY", "dummy_anthropic_key")
        )
        self.gemini = ChatGoogleGenerativeAI(
            model="gemini-1.5-pro", # Represents Gemini 3.0 Pro
            google_api_key=os.getenv("GOOGLE_API_KEY", "dummy_google_key")
        )
        self.gpt = ChatOpenAI(
            model="gpt-4o", # Represents GPT-5.2 Thinking
            api_key=os.getenv("OPENAI_API_KEY", "dummy_openai_key")
        )

        # Load Style DNA (try multiple paths for different environments)
        style_dna_paths = [
            os.path.join(os.path.dirname(__file__), "style_dna.md"),  # Same folder as orchestrator
            "/Users/rafaelpimentel/.gemini/antigravity/brain/f774edc7-6631-4cdc-8c4f-16801861223f/style_dna.md"  # Dev path
        ]
        self.style_dna_content = ""
        for path in style_dna_paths:
            if os.path.exists(path):
                with open(path, "r") as f:
                    self.style_dna_content = f.read()
                break
        if not self.style_dna_content:
            self.style_dna_content = "Estilo: Metamodernismo. Referências: Ben Lerner, Rachel Cusk. Evite melodrama."

        
        # System prompts for each role (The "Prompt Map")
        self.prompts = {
            "claude_style": f"""Você é o Consultor de Estilo. Sua função é analisar o trecho enviado e avaliar a densidade da prosa.

DNA DE ESTILO (Referência Absoluta):
{self.style_dna_content}

DIRETRIZES DE ANÁLISE:
1. Análise de Adjetivação: Identifique adjetivos 'preguiçosos' e sugira substituições por imagens concretas ou abstrações filosóficas.
2. Sintaxe: Verifique se o ritmo das frases reflete o estado mental do personagem. Se o personagem está ansioso, sugira frases mais curtas e paratáticas. Se está reflexivo, sugira subordinações elegantes.
3. Voz Autoral: Mantenha o tom de 'auto-ficção cerebral'. Evite qualquer traço de escrita comercial ou melodramática.

Saída: Forneça 3 sugestões de reescrita focadas em diferentes nuances (ex: uma mais minimalista, outra mais lírica).""",

            "gemini_coherence": """Você é o Guardião da Coerência. Sua função é realizar o 'Fact-Checking' do universo narrativo.

Verificação Cruzada: Compare o trecho enviado com o contexto do manuscrito e definições de personagens.

DIRETRIZES DE ANÁLISE:
1. Inconsistências: Aponte se o personagem está agindo contra sua motivação base ou se há erros de continuidade (objetos, datas, locais).
2. Memória de Longo Prazo: Relembre o autor de elementos esquecidos que poderiam ser usados aqui para criar rimas narrativas (ex: 'Você mencionou um relógio quebrado no Cap. 1, este seria um bom momento para ele reaparecer?').

Saída: Liste apenas inconsistências críticas ou sugestões de conexão temática.""",

            "gpt_structure": """Você é o Arquiteto de Estrutura. Utilize sua capacidade de raciocínio profundo para analisar a subestrutura da cena.

DIRETRIZES DE ANÁLISE:
1. Causalidade: A ação X leva logicamente à consequência Y? Existe 'Deus Ex Machina'?
2. Subtexto: O que o personagem realmente quer nesta cena e como isso está sendo subentendido (ou por que está óbvio demais)?
3. Tensão Narrativa: A cena move a história adiante ou é apenas 'encher linguiça'?

Processo: Pense passo a passo sobre os riscos narrativos antes de dar seu veredito.
Saída: Um breve diagnóstico estrutural e uma pergunta provocativa para o autor refletir sobre o rumo da cena."""
        }
    
    def generate_context_package(self, project_name: str, style_ref: str, chapter: str, scene: str, emotional_state: str) -> str:
        """Generates the 'Briefing' header for prompts."""
        return f"""Contexto do Projeto: "Você está trabalhando no projeto literário '{project_name}'. 
Estilo de Referência: {style_ref}. 
Localização na Trama: Capítulo {chapter}, Cena {scene}. 
Estado Emocional do Protagonista: {emotional_state}."
"""

    async def flow_mode(self, current_text: str, manuscript_context: str) -> Optional[ConsistencyAlert]:
        """
        FLOW MODE: Passive monitoring by Gemini.
        Only alerts when inconsistency detected.
        """
        prompt = f"""Contexto do manuscrito:
{manuscript_context}

---
Texto sendo escrito agora:
{current_text}

---
Verifique APENAS inconsistências factuais (tempo, lugar, detalhes de personagens).
Se não houver problemas, responda apenas: "OK"
Se houver, responda em JSON: {{"type": "...", "severity": "...", "message": "...", "suggestion": "..."}}"""

        response = await self.gemini.ainvoke([
            SystemMessage(content=self.prompts["gemini_coherence"]),
            HumanMessage(content=prompt)
        ])
        
        content = response.content.strip()
        if "OK" in content and len(content) < 10:
            return None
        
        # Parse the JSON response
        import json
        import re
        try:
            # Extract JSON if wrapped in markdown
            json_match = re.search(r'\{.*\}', content, re.DOTALL)
            if json_match:
                data = json.loads(json_match.group(0))
                return ConsistencyAlert(**data)
            return None
        except:
            # If not strict JSON, return generic alert if content is substantial
            if len(content) > 20: 
                 return ConsistencyAlert(
                    type="plot", # Default
                    severity="low", 
                    message=content,
                    suggestion=None
                )
            return None
    
    async def doubt_mode(self, question: str, text_context: str) -> AnalysisResult:
        """
        DOUBT MODE: GPT leads structural analysis.
        """
        prompt = f"""Contexto do texto:
{text_context}

Pergunta do escritor:
{question}

Analise usando raciocínio de árvore de pensamento."""

        response = await self.gpt.ainvoke([
            SystemMessage(content=self.prompts["gpt_structure"]),
            HumanMessage(content=prompt)
        ])
        
        return AnalysisResult(
            model="GPT-5.2 Thinking",
            focus="structure",
            analysis=response.content,
            suggestions=[]
        )

    async def synthesize_responses(self, claude_resp: str, gemini_resp: str, gpt_resp: str) -> dict:
        """
        Consolidates the 3 opinions into a final verdict.
        """
        synthesis_prompt = f"""Abaixo estão as críticas de três especialistas sobre o mesmo texto.

[Especialista 1 - Estilo (Claude)]:
{claude_resp}

[Especialista 2 - Coerência (Gemini)]:
{gemini_resp}

[Especialista 3 - Estrutura (GPT)]:
{gpt_resp}

TAREFA DE SÍNTESE:
1. Resuma o Consenso: Em que todos concordam?
2. Destaque a Divergência: Onde as opiniões se chocam? (Ex: 'Claude amou o lirismo, mas GPT achou que ele atrasa o ritmo').
3. Veredito: Apresente uma versão 'Final Combinada' que siga as sugestões de todos de forma equilibrada.

Responda em JSON:
{{
    "consensus": "...",
    "divergence": "...",
    "verdict": "..."
}}
"""
        # Using GPT-4o for synthesis as it has strong reasoning capabilities
        response = await self.gpt.ainvoke([
            SystemMessage(content="Você é o Líder do Conselho Editorial. Sua função é sintetizar feedbacks."),
            HumanMessage(content=synthesis_prompt)
        ])
        
        import json
        import re
        try:
            content = response.content.strip()
            json_match = re.search(r'\{.*\}', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(0))
            else:
                return {
                    "consensus": "Erro ao processar consenso.",
                    "divergence": "Erro ao processar divergência.",
                    "verdict": content # Fallback to raw text
                }
        except Exception as e:
            return {
                "consensus": "",
                "divergence": "",
                "verdict": f"Erro na síntese: {str(e)}"
            }

    
    async def polish_mode(self, 
                          text: str, 
                          manuscript_context: str,
                          project_name: str,
                          style_ref: str,
                          chapter: str,
                          scene: str,
                          emotional_state: str) -> PolishReport:
        """
        POLISH MODE: Full multi-LLM comparison.
        """
        
        # Generate the Briefing Header
        briefing = self.generate_context_package(project_name, style_ref, chapter, scene, emotional_state)
        
        # Prepare specific inputs
        claude_input = f"{briefing}\n\nTRECHO PARA ANÁLISE:\n{text}"
        
        gemini_input = f"{briefing}\n\nCONTEXTO GERAL:\n{manuscript_context}\n\nTRECHO PARA ANÁLISE:\n{text}"
        
        gpt_input = f"{briefing}\n\nTRECHO PARA ANÁLISE:\n{text}\n\n(Considere o que foi implícito mas não dito)"

        # Run all three in parallel
        claude_task = self.claude.ainvoke([
            SystemMessage(content=self.prompts["claude_style"]),
            HumanMessage(content=claude_input)
        ])
        gemini_task = self.gemini.ainvoke([
            SystemMessage(content=self.prompts["gemini_coherence"]),
            HumanMessage(content=gemini_input)
        ])
        gpt_task = self.gpt.ainvoke([
            SystemMessage(content=self.prompts["gpt_structure"]),
            HumanMessage(content=gpt_input)
        ])
        
        claude_resp, gemini_resp, gpt_resp = await asyncio.gather(
            claude_task, gemini_task, gpt_task
        )
        
        # Synthesis
        synthesis = await self.synthesize_responses(claude_resp.content, gemini_resp.content, gpt_resp.content)
        
        # Build results
        return PolishReport(
            claude_style=AnalysisResult(
                model="Claude 4.5 Sonnet",
                focus="style",
                analysis=claude_resp.content,
                suggestions=[]
            ),
            gemini_coherence=AnalysisResult(
                model="Gemini 3.0 Pro",
                focus="coherence", 
                analysis=gemini_resp.content,
                suggestions=[]
            ),
            gpt_structure=AnalysisResult(
                model="GPT-5.2 Thinking",
                focus="structure",
                analysis=gpt_resp.content,
                suggestions=[]
            ),
            consensus=synthesis.get("consensus", ""),
            divergence=synthesis.get("divergence", ""),
            verdict=synthesis.get("verdict", "")
        )


# Singleton instance
council = EditorialCouncil()
