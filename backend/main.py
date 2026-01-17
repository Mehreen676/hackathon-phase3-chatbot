from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.router.tasks import router as tasks_router
from app.router.chat import router as chat_router

app = FastAPI(title="Hackathon Todo API", version="0.1.0")

# CORS (allow all for hackathon demo)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Hackathon Todo API is running"}

@app.get("/health")
def health():
    return {"status": "ok"}

# IMPORTANT: prefix is only here (SINGLE /api)
app.include_router(tasks_router, prefix="/api", tags=["tasks"])
app.include_router(chat_router, prefix="/api", tags=["chat"])