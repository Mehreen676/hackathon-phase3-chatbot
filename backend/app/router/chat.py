# backend/app/router/chat.py

from typing import Optional, List, Any, Dict
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select

from app.db import get_session
from app.models import Conversation, Message
from app.agent_runner import run_chat  # ✅ use Agent Runner (spec flow)

router = APIRouter()


class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[int] = None


class ChatResponse(BaseModel):
    reply: str
    conversation_id: int
    tool_calls: List[Any] = []


def _get_or_create_conversation(session: Session, user_id: str, conversation_id: Optional[int]) -> Conversation:
    if conversation_id is not None:
        conv = session.get(Conversation, conversation_id)
        if not conv or conv.user_id != user_id:
            raise HTTPException(status_code=404, detail="Conversation not found")
        return conv

    latest = session.exec(
        select(Conversation)
        .where(Conversation.user_id == user_id)
        .order_by(Conversation.id.desc())
        .limit(1)
    ).first()
    if latest:
        return latest

    conv = Conversation(user_id=user_id, created_at=datetime.utcnow())
    session.add(conv)
    session.commit()
    session.refresh(conv)
    return conv


def _save_message(session: Session, conversation_id: int, role: str, content: str) -> None:
    session.add(
        Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
            created_at=datetime.utcnow(),
        )
    )
    session.commit()


@router.post("/{user_id}/chat", response_model=ChatResponse)
async def chat(user_id: str, payload: ChatRequest, session: Session = Depends(get_session)):
    text = (payload.message or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Empty message")

    # Ensure conversation exists/belongs to user (if provided)
    conv = _get_or_create_conversation(session, user_id, payload.conversation_id)

    # Delegate to agent runner (it loads history + stores messages + calls MCP tools)
    try:
        result = await run_chat(
            user_id=user_id,
            message=text,
            conversation_id=conv.id,
        )
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    # NOTE: agent_runner already stores user+assistant messages.
    # If you want to keep router responsible for storing, remove storage from agent_runner.
    return {
        "reply": result["reply"],
        "conversation_id": result["conversation_id"],
        "tool_calls": result.get("tool_calls", []),
    }
