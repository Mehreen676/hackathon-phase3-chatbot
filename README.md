# Hackathon Phase 3 – Todo Chatbot 🤖

This project is **Phase 3** of the Hackathon Todo Application.  
It extends the existing **Phase 2 Full-Stack Todo App** by adding a **chatbot interface** that allows users to manage tasks using **natural language commands**.

---

## 🚀 Features

### ✅ Chatbot Capabilities
Users can control their todo list via chat commands:

- `list` → List all tasks  
- `pending` → Show pending tasks  
- `completed` → Show completed tasks  
- `stats` → Show task statistics  
- `add milk` / `add: Buy milk` → Add a new task  
- `complete: <id>` → Mark a task as completed  
- `delete: <id>` → Delete a task  

The chatbot supports **simple natural language** as well as **strict command syntax**.

---

## 🧠 How It Works

- The chatbot is **NOT a separate AI system**
- It directly interacts with the **same backend & database** used by the Todo app
- All chat actions are reflected instantly in the main UI

---

## 🏗️ Tech Stack

### Frontend
- Next.js (App Router)
- TypeScript
- Tailwind CSS
- Chat modal UI integrated into dashboard

### Backend
- FastAPI
- SQLModel
- PostgreSQL / SQLite
- REST API

### Deployment
- Frontend: Vercel
- Backend: Hugging Face Spaces

---

## 🔌 API Endpoint

Chatbot endpoint:


### Example Request
```json
{
  "message": "add milk"
}

{
  "reply": "Added: 36: milk"
}
🧪 Tested Commands

✔ Add tasks via chat
✔ List tasks
✔ Show pending / completed tasks
✔ Delete tasks by ID
✔ Live sync between chat & UI
✔ Error handling for invalid commands
hackathon-phase3-chatbot
├── frontend
│   └── Next.js app with chat UI
├── backend
│   ├── main.py
│   └── app/router/chat.py
└── README.md
Hackathon Compliance

✔ Separate Phase-3 repository
✔ Chatbot implemented as per PDF requirements
✔ No modification to Phase-2 repo
✔ Backend + frontend fully integrated

👤 Author

Mehreen Asghar
Hackathon Participant
