from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel

from app.database import engine
from app import models  # noqa
from app.router.tasks import router as tasks_router
from app.router.chat import router as chat_router

app = FastAPI(title="Hackathon Todo API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    SQLModel.metadata.create_all(engine)

@app.get("/")
def root():
    return {"message": "Hackathon Todo API running"}

# IMPORTANT
app.include_router(tasks_router)
app.include_router(chat_router)

@app.get("/health")
def health():
    return {"status": "ok"}
