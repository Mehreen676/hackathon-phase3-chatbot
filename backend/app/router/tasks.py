from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas import TaskCreate, TaskRead

router = APIRouter()  # <-- IMPORTANT: no /api here

# In-memory store (demo). Replace with DB if you already have one.
TASKS_DB = {}  # { user_id: [ {id,title,completed}, ... ] }
NEXT_ID = 1

@router.get("/{user_id}/tasks/", response_model=List[TaskRead])
def list_tasks(user_id: str):
    return TASKS_DB.get(user_id, [])

@router.post("/{user_id}/tasks/", response_model=TaskRead)
def create_task(user_id: str, payload: TaskCreate):
    global NEXT_ID
    task = {
        "id": NEXT_ID,
        "user_id": user_id,
        "title": payload.title,
        "completed": False,
    }
    NEXT_ID += 1
    TASKS_DB.setdefault(user_id, []).append(task)
    return task

@router.patch("/{user_id}/tasks/{task_id}/complete/", response_model=TaskRead)
def toggle_complete(user_id: str, task_id: int):
    tasks = TASKS_DB.get(user_id, [])
    for t in tasks:
        if t["id"] == task_id:
            t["completed"] = not t["completed"]
            return t
    raise HTTPException(status_code=404, detail="Task not found")

@router.delete("/{user_id}/tasks/{task_id}")
def delete_task(user_id: str, task_id: int):
    tasks = TASKS_DB.get(user_id, [])
    new_tasks = [t for t in tasks if t["id"] != task_id]
    if len(new_tasks) == len(tasks):
        raise HTTPException(status_code=404, detail="Task not found")
    TASKS_DB[user_id] = new_tasks
    return {"ok": True}