"""
API Routes for the Editorial Council (Tripartite Intelligence).
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from .orchestrator import council, ActivationMode, ConsistencyAlert, AnalysisResult, PolishReport

router = APIRouter(prefix="/council", tags=["Editorial Council"])


class FlowRequest(BaseModel):
    current_text: str
    manuscript_context: str


class DoubtRequest(BaseModel):
    question: str
    text_context: str


class PolishRequest(BaseModel):
    text: str
    manuscript_context: str
    # Context specific fields for the Prompt Map
    project_name: str = "Projeto Sem Nome"
    style_ref: str = "Metamodernismo"
    chapter: str = "1"
    scene: str = "1"
    emotional_state: str = "Neutro"


@router.post("/flow", response_model=Optional[ConsistencyAlert])
async def flow_mode(request: FlowRequest):
    """
    FLOW MODE: Passive Gemini monitoring.
    Returns None if no issues, or a ConsistencyAlert if problem detected.
    """
    try:
        alert = await council.flow_mode(
            current_text=request.current_text,
            manuscript_context=request.manuscript_context
        )
        return alert
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/doubt", response_model=AnalysisResult)
async def doubt_mode(request: DoubtRequest):
    """
    DOUBT MODE: GPT-led structural analysis.
    For when the writer has a specific question.
    """
    try:
        result = await council.doubt_mode(
            question=request.question,
            text_context=request.text_context
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/polish", response_model=PolishReport)
async def polish_mode(request: PolishRequest):
    """
    POLISH MODE: Full multi-LLM analysis.
    All three AIs analyze in parallel, results synthesized.
    """
    try:
        report = await council.polish_mode(
            text=request.text,
            manuscript_context=request.manuscript_context,
            project_name=request.project_name,
            style_ref=request.style_ref,
            chapter=request.chapter,
            scene=request.scene,
            emotional_state=request.emotional_state
        )
        return report
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
