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
    consensus: list[str]  # Where they agree
    divergence: list[str]  # Where they disagree


class EditorialCouncil:
    """
    The Tripartite Intelligence Orchestrator.
    Manages Claude (Style), Gemini (Coherence), and GPT (Structure).
    """
    
    def __init__(self):
        # Initialize the three LLMs
        self.claude = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            api_key=os.getenv("ANTHROPIC_API_KEY")
        )
        self.gemini = ChatGoogleGenerativeAI(
            model="gemini-2.5-pro-preview-06-05",
            google_api_key=os.getenv("GOOGLE_API_KEY")
        )
        self.gpt = ChatOpenAI(
            model="gpt-4o",
            api_key=os.getenv("OPENAI_API_KEY")
        )
        
        # System prompts for each role
        self.prompts = {
            "claude_style": """Você é um editor literário especializado em prosa lírica contemporânea.
Seu foco é: ritmo, métrica das frases, eliminação de clichês, e "pátina literária".
Referências de estilo: Rachel Cusk, Ben Lerner, Clarice Lispector.
Analise o texto e sugira refinamentos que elevem a qualidade literária sem perder a voz do autor.""",

            "gemini_coherence": """Você é um analista de continuidade narrativa com memória perfeita.
Seu foco é: inconsistências temporais, espaciais, de personagem, e de enredo.
Você tem acesso ao contexto completo do manuscrito.
Identifique qualquer contradição com o que foi estabelecido anteriormente.""",

            "gpt_structure": """Você é um consultor de estrutura narrativa e psicologia de personagens.
Seu foco é: verossimilhança das ações, arcos de personagem, e lógica causal.
Analise se as ações e decisões dos personagens fazem sentido dado o que sabemos sobre eles.
Use raciocínio de árvore de pensamento para explorar consequências."""
        }
    
    async def flow_mode(self, current_text: str, manuscript_context: str) -> Optional[ConsistencyAlert]:
        """
        FLOW MODE: Passive monitoring by Gemini.
        Only alerts when inconsistency detected.
        """
        prompt = f"""Contexto do manuscrito (capítulos anteriores):
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
        if content == "OK":
            return None
        
        # Parse the JSON response
        import json
        try:
            data = json.loads(content)
            return ConsistencyAlert(**data)
        except:
            return ConsistencyAlert(
                type="unknown",
                severity="low", 
                message=content,
                suggestion=None
            )
    
    async def doubt_mode(self, question: str, text_context: str, character_data: str) -> AnalysisResult:
        """
        DOUBT MODE: GPT leads structural analysis.
        Used when writer has a specific question.
        """
        prompt = f"""Contexto do texto:
{text_context}

Dados dos personagens envolvidos:
{character_data}

Pergunta do escritor:
{question}

Analise usando raciocínio de árvore de pensamento. Considere múltiplas possibilidades."""

        response = await self.gpt.ainvoke([
            SystemMessage(content=self.prompts["gpt_structure"]),
            HumanMessage(content=prompt)
        ])
        
        return AnalysisResult(
            model="GPT-5.2 Thinking",
            focus="structure",
            analysis=response.content,
            suggestions=[]  # Could parse suggestions from response
        )
    
    async def polish_mode(self, text: str, style_dna: str, manuscript_context: str) -> PolishReport:
        """
        POLISH MODE: Full multi-LLM comparison.
        All three analyze in parallel, then synthesis.
        """
        
        # Prepare prompts
        claude_prompt = f"""DNA de Estilo (referências do autor):
{style_dna}

Texto para polir:
{text}

Analise o estilo e sugira refinamentos líricos."""

        gemini_prompt = f"""Contexto do manuscrito:
{manuscript_context}

Texto atual:
{text}

Verifique coerência com o estabelecido."""

        gpt_prompt = f"""Texto para análise estrutural:
{text}

Contexto:
{manuscript_context}

Analise a lógica narrativa e psicologia dos personagens."""

        # Run all three in parallel
        claude_task = self.claude.ainvoke([
            SystemMessage(content=self.prompts["claude_style"]),
            HumanMessage(content=claude_prompt)
        ])
        gemini_task = self.gemini.ainvoke([
            SystemMessage(content=self.prompts["gemini_coherence"]),
            HumanMessage(content=gemini_prompt)
        ])
        gpt_task = self.gpt.ainvoke([
            SystemMessage(content=self.prompts["gpt_structure"]),
            HumanMessage(content=gpt_prompt)
        ])
        
        claude_resp, gemini_resp, gpt_resp = await asyncio.gather(
            claude_task, gemini_task, gpt_task
        )
        
        # Build results
        claude_result = AnalysisResult(
            model="Claude 4.5 Sonnet",
            focus="style",
            analysis=claude_resp.content,
            suggestions=[]
        )
        gemini_result = AnalysisResult(
            model="Gemini 3.0 Pro",
            focus="coherence", 
            analysis=gemini_resp.content,
            suggestions=[]
        )
        gpt_result = AnalysisResult(
            model="GPT-5.2 Thinking",
            focus="structure",
            analysis=gpt_resp.content,
            suggestions=[]
        )
        
        # TODO: Add synthesis logic to find consensus/divergence
        return PolishReport(
            gemini_coherence=gemini_result,
            claude_style=claude_result,
            gpt_structure=gpt_result,
            consensus=[],
            divergence=[]
        )


# Singleton instance
council = EditorialCouncil()
