from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    chapters = relationship("Chapter", back_populates="project", cascade="all, delete-orphan")
    characters = relationship("Character", back_populates="project", cascade="all, delete-orphan")
    reference_docs = relationship("ReferenceDoc", back_populates="project", cascade="all, delete-orphan")

class Chapter(Base):
    __tablename__ = "chapters"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=True)
    title = Column(String, default="Novo Capítulo")
    content = Column(Text, default="")  # The actual prose content
    order = Column(Integer, default=0)
    word_count = Column(Integer, default=0)
    color = Column(String, nullable=True)  # Optional card color
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    project = relationship("Project", back_populates="chapters")
    scenes = relationship("Scene", back_populates="chapter")

class Scene(Base):
    __tablename__ = "scenes"

    id = Column(Integer, primary_key=True, index=True)
    chapter_id = Column(Integer, ForeignKey("chapters.id"))
    title = Column(String)
    content = Column(Text) # The actual prose
    order = Column(Integer)
    
    chapter = relationship("Chapter", back_populates="scenes")

class Character(Base):
    __tablename__ = "characters"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(Integer, ForeignKey("projects.id"))
    name = Column(String, index=True)
    description = Column(Text) # Physical description, personality
    
    project = relationship("Project", back_populates="characters")


class ReferenceDoc(Base):
    """Per-project reference documents: narrative_map or writing_style."""
    __tablename__ = "reference_docs"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)
    doc_type = Column(String, nullable=False)  # "narrative_map" or "writing_style"
    content = Column(Text, default="")
    filename = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    project = relationship("Project", back_populates="reference_docs")

    __table_args__ = (
        UniqueConstraint('project_id', 'doc_type', name='uq_project_doc_type'),
    )
