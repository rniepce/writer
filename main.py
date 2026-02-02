from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Metadata
from .database import engine, Base
from .routes_council import router as council_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create tables
    Base.metadata.create_all(bind=engine)
    yield
    # Shutdown

app = FastAPI(title="Ghost Writer API", lifespan=lifespan)

# Include routers
app.include_router(council_router)

# CORS (Allowing frontend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Ghost Writer API Operational"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
