"""
API Routes for Reference Documents (Narrative Map & Writing Style).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from database import get_db
from models import ReferenceDoc

router = APIRouter(prefix="/references", tags=["Reference Documents"])

VALID_DOC_TYPES = {"narrative_map", "writing_style"}


class ReferenceDocCreate(BaseModel):
    project_id: int
    content: str
    filename: Optional[str] = None


class ReferenceDocResponse(BaseModel):
    id: int
    project_id: int
    doc_type: str
    content: str
    filename: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ReferenceDocSummary(BaseModel):
    """Minimal data for listing."""
    id: int
    doc_type: str
    filename: Optional[str]
    preview: str
    updated_at: datetime

    class Config:
        from_attributes = True


def get_preview(content: str, max_chars: int = 120) -> str:
    if not content:
        return ""
    clean = content.replace('\n', ' ').strip()
    if len(clean) <= max_chars:
        return clean
    return clean[:max_chars].rsplit(' ', 1)[0] + "..."


@router.get("", response_model=List[ReferenceDocSummary])
def list_references(project_id: int, db: Session = Depends(get_db)):
    """List all reference docs for a project."""
    docs = db.query(ReferenceDoc).filter(
        ReferenceDoc.project_id == project_id
    ).all()
    return [
        ReferenceDocSummary(
            id=doc.id,
            doc_type=doc.doc_type,
            filename=doc.filename,
            preview=get_preview(doc.content),
            updated_at=doc.updated_at,
        )
        for doc in docs
    ]


@router.get("/{doc_type}", response_model=Optional[ReferenceDocResponse])
def get_reference(doc_type: str, project_id: int, db: Session = Depends(get_db)):
    """Get a specific reference doc by type for a project."""
    if doc_type not in VALID_DOC_TYPES:
        raise HTTPException(status_code=400, detail=f"Tipo inválido. Use: {VALID_DOC_TYPES}")
    doc = db.query(ReferenceDoc).filter(
        ReferenceDoc.project_id == project_id,
        ReferenceDoc.doc_type == doc_type,
    ).first()
    return doc


@router.put("/{doc_type}", response_model=ReferenceDocResponse)
def upsert_reference(doc_type: str, data: ReferenceDocCreate, db: Session = Depends(get_db)):
    """Create or replace a reference doc for a project."""
    if doc_type not in VALID_DOC_TYPES:
        raise HTTPException(status_code=400, detail=f"Tipo inválido. Use: {VALID_DOC_TYPES}")

    doc = db.query(ReferenceDoc).filter(
        ReferenceDoc.project_id == data.project_id,
        ReferenceDoc.doc_type == doc_type,
    ).first()

    if doc:
        doc.content = data.content
        doc.filename = data.filename
        doc.updated_at = datetime.utcnow()
    else:
        doc = ReferenceDoc(
            project_id=data.project_id,
            doc_type=doc_type,
            content=data.content,
            filename=data.filename,
        )
        db.add(doc)

    db.commit()
    db.refresh(doc)
    return doc


@router.delete("/{doc_type}")
def delete_reference(doc_type: str, project_id: int, db: Session = Depends(get_db)):
    """Delete a reference doc."""
    if doc_type not in VALID_DOC_TYPES:
        raise HTTPException(status_code=400, detail=f"Tipo inválido. Use: {VALID_DOC_TYPES}")

    doc = db.query(ReferenceDoc).filter(
        ReferenceDoc.project_id == project_id,
        ReferenceDoc.doc_type == doc_type,
    ).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Documento de referência não encontrado")

    db.delete(doc)
    db.commit()
    return {"message": "Documento removido"}
