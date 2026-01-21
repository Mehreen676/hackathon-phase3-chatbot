🧠 Hackathon II — Phase 3
Agent-Based Todo Chatbot (Stateful & Tool-Driven)

This project implements a Phase-3 compliant Todo Chatbot using the OpenAI Agents SDK with MCP tools and persistent conversation memory.
The focus of Phase-3 is agent correctness, tool-only actions, and real statefulness — not UI novelty or Phase-4 features.

✅ What Was Built

A full-stack Todo application where users manage tasks via natural-language chat.

Users can:

Add tasks

List tasks

Complete tasks

Delete tasks

All actions are executed only through MCP tools, not directly by the agent.

🔧 Backend Architecture (Core of Phase-3)

OpenAI Agents SDK integrated

MCP (Model Context Protocol) tools implemented:

add_task

list_tasks

complete_task

delete_task

update_task

Agent is tool-driven only

❌ No direct DB access by the agent

FastAPI backend

Neon PostgreSQL for persistence:

Tasks

Conversations

Messages

Chat API
POST /api/{user_id}/chat


Agent receives:

USER_ID explicitly in the prompt

Conversation history from database

Agent interprets natural language and triggers MCP tools

💬 Conversation Memory (Statefulness)

This chatbot is not stateless and not in-memory.

Implemented:

conversations table

messages table

User + assistant messages persisted

Same conversation_id maintains context

Memory survives server restarts

✅ Confirms true stateful chatbot, as required in Phase-3.

🖥️ Frontend Integration

Built with Next.js (App Router)

Chatbot integrated directly into the dashboard

Users can manage tasks in real time via chat

Dashboard task list stays in sync with chatbot actions

Toast notifications shown on:

task add

task complete

task delete

🎨 Chat UI Design Note (Important)

The chatbot UI is a custom ChatKit-style UI.

Why not official ChatKit?
The official ChatKit React package is incompatible with Next.js App Router + Turbopack.

Instead:

A custom ChatKit-style UI was implemented

Same interaction flow

Continuous conversation experience

Fully functional and Phase-3 compliant

This avoids framework instability while preserving required behavior.

📸 Screenshots (Verification Proof)

Screenshots are included to demonstrate:

Dashboard with chatbot visible

Tasks added via chatbot

Tasks deleted/completed via chatbot

Dashboard reflecting real-time updates

Screenshots folder contains:

dashboard-chatbot.png

chatbot-delete-task.png

These screenshots validate:

Agent → MCP → Database → UI flow

Correct Phase-3 behavior

📋 Phase-3 Requirement Checklist
Requirement	Status
OpenAI Agents SDK	✅
MCP Tools Usage	✅
Tool-Only Task Management	✅
Stateful Conversation Memory	✅
Database Persistence	✅
Chat API	✅
Frontend Chatbot Integration	✅
ChatKit-style UX	✅ (Custom)
🚫 Explicitly Not Included (By Design)

❌ Embeddings

❌ Vector search

❌ Semantic retrieval

❌ Phase-4 features

These are intentionally out of scope for Phase-3.

🏁 Final Assessment

This project delivers:

A real agent system, not a scripted chatbot

Strict tool-driven task execution

Persistent conversation memory

Clean separation of concerns

Stable frontend + backend integration

✅ Phase-3: COMPLETE & FULLY COMPLIANT