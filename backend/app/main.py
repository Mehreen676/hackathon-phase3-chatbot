# backend/app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel

from app.database import engine

# ✅ ensure all models are registered
import app.models  # noqa

from app.router import tasks, chat

app = FastAPI(title="Hackathon Todo API")

# ✅ Allowed frontend origins
ALLOW_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3001",
    "https://mehreenasghar-phase3-chatbot.vercel.app",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOW_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ create DB tables on startup
@app.on_event("startup")
def on_startup():
    SQLModel.metadata.create_all(engine)

# ✅ health check (BUILD MARKER)
@app.get("/health")
def health():
    return {"status": "ok", "build": "DAY5-FINAL-MAINPY"}

# ✅ ROUTERS (IMPORTANT)
# /api prefix SIRF yahan hai
app.include_router(tasks.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
