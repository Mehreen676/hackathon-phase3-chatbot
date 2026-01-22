from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel

from app.database import engine

# ✅ register ALL models (Task, Conversation, Message)
import app.models  # noqa

from app.router import tasks, chat

app = FastAPI()

# ✅ DEV + DEPLOY origins
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

@app.on_event("startup")
def on_startup():
    # 🔥 auto-create all tables
    SQLModel.metadata.create_all(engine)

@app.get("/health")
def health():
    return {"status": "ok"}

app.include_router(tasks.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
