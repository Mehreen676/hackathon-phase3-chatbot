from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import re

from app.routes.tasks import TASKS_DB, create_task, list_tasks, toggle_complete, delete_task
from app.schemas import TaskCreate

router = APIRouter()  # <-- IMPORTANT: no /api here

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str

@router.post("/{user_id}/chat", response_model=ChatResponse)
def chat(user_id: str, payload: ChatRequest):
    text = (payload.message or "").strip()

    # Supported commands:
    # add: milk
    # show
    # complete: 1
    # delete: 1
    low = text.lower()

    # add: ...
    m = re.match(r"^add:\s*(.+)$", low)
    if m:
        title = text.split(":", 1)[1].strip()
        if not title:
            raise HTTPException(status_code=400, detail="Empty task title")
        create_task(user_id, TaskCreate(title=title))
        return {"reply": f"Added task: {title}"}

    # show / list
    if low in ["show", "show tasks", "list", "list tasks", "show my tasks"]:
        tasks = list_tasks(user_id)
        if not tasks:
            return {"reply": "No tasks found."}
        lines = []
        for t in tasks:
            status = "✅" if t["completed"] else "⬜"
            lines.append(f'{t["id"]}. {status} {t["title"]}')
        return {"reply": "\n".join(lines)}

    # complete: ID
    m = re.match(r"^complete:\s*(\d+)$", low)
    if m:
        tid = int(m.group(1))
        t = toggle_complete(user_id, tid)
        return {"reply": f'Toggled complete: {t["title"]} (now {"done" if t["completed"] else "not done"})'}

    # delete: ID
    m = re.match(r"^delete:\s*(\d+)$", low)
    if m:
        tid = int(m.group(1))
        delete_task(user_id, tid)
        return {"reply": f"Deleted task {tid}"}

    return {
        "reply": (
            "Commands:\n"
            "add: <task title>\n"
            "show\n"
            "complete: <task id>\n"
            "delete: <task id>"
        )
    }