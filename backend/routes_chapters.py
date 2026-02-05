from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from database import get_db
from models import Chapter

router = APIRouter(prefix="/chapters", tags=["chapters"])


# Pydantic Schemas
class ChapterCreate(BaseModel):
    title: Optional[str] = "Novo Capítulo"
    content: Optional[str] = ""
    project_id: Optional[int] = None
    color: Optional[str] = None


class ChapterUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    color: Optional[str] = None


class ChapterResponse(BaseModel):
    id: int
    title: str
    content: str
    order: int
    word_count: int
    color: Optional[str]
    created_at: datetime
    updated_at: datetime
    project_id: Optional[int]

    class Config:
        from_attributes = True


class ChapterCard(BaseModel):
    """Minimal data for card display"""
    id: int
    title: str
    order: int
    word_count: int
    color: Optional[str]
    preview: str  # First ~100 chars of content
    updated_at: datetime

    class Config:
        from_attributes = True


class ReorderRequest(BaseModel):
    chapter_ids: List[int]  # IDs in desired order


# Helper function
def count_words(text: str) -> int:
    return len(text.split()) if text else 0


def get_preview(content: str, max_chars: int = 100) -> str:
    if not content:
        return ""
    clean = content.replace('\n', ' ').strip()
    if len(clean) <= max_chars:
        return clean
    return clean[:max_chars].rsplit(' ', 1)[0] + "..."


# Routes
@router.get("", response_model=List[ChapterCard])
def list_chapters(db: Session = Depends(get_db)):
    """List all chapters as cards (minimal data for sidebar)"""
    chapters = db.query(Chapter).order_by(Chapter.order).all()
    return [
        ChapterCard(
            id=ch.id,
            title=ch.title,
            order=ch.order,
            word_count=ch.word_count,
            color=ch.color,
            preview=get_preview(ch.content),
            updated_at=ch.updated_at
        )
        for ch in chapters
    ]


@router.get("/{chapter_id}", response_model=ChapterResponse)
def get_chapter(chapter_id: int, db: Session = Depends(get_db)):
    """Get full chapter content"""
    chapter = db.query(Chapter).filter(Chapter.id == chapter_id).first()
    if not chapter:
        raise HTTPException(status_code=404, detail="Capítulo não encontrado")
    return chapter


@router.post("", response_model=ChapterResponse)
def create_chapter(chapter: ChapterCreate, db: Session = Depends(get_db)):
    """Create a new chapter"""
    # Get max order
    max_order = db.query(Chapter).count()
    
    db_chapter = Chapter(
        title=chapter.title,
        content=chapter.content or "",
        project_id=chapter.project_id,
        color=chapter.color,
        order=max_order,
        word_count=count_words(chapter.content or "")
    )
    db.add(db_chapter)
    db.commit()
    db.refresh(db_chapter)
    return db_chapter


@router.put("/{chapter_id}", response_model=ChapterResponse)
def update_chapter(chapter_id: int, update: ChapterUpdate, db: Session = Depends(get_db)):
    """Update chapter (used for saving)"""
    chapter = db.query(Chapter).filter(Chapter.id == chapter_id).first()
    if not chapter:
        raise HTTPException(status_code=404, detail="Capítulo não encontrado")
    
    if update.title is not None:
        chapter.title = update.title
    if update.content is not None:
        chapter.content = update.content
        chapter.word_count = count_words(update.content)
    if update.color is not None:
        chapter.color = update.color
    
    chapter.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(chapter)
    return chapter


@router.delete("/{chapter_id}")
def delete_chapter(chapter_id: int, db: Session = Depends(get_db)):
    """Delete a chapter"""
    chapter = db.query(Chapter).filter(Chapter.id == chapter_id).first()
    if not chapter:
        raise HTTPException(status_code=404, detail="Capítulo não encontrado")
    
    db.delete(chapter)
    db.commit()
    return {"message": "Capítulo removido"}


@router.patch("/reorder")
def reorder_chapters(request: ReorderRequest, db: Session = Depends(get_db)):
    """Reorder chapters by providing list of IDs in desired order"""
    for idx, chapter_id in enumerate(request.chapter_ids):
        chapter = db.query(Chapter).filter(Chapter.id == chapter_id).first()
        if chapter:
            chapter.order = idx
    
    db.commit()
    return {"message": "Capítulos reordenados"}
