from pydantic import BaseModel

class TaskCreate(BaseModel):
    title: str

class TaskRead(BaseModel):
    id: int
    user_id: str
    title: str
    completed: bool