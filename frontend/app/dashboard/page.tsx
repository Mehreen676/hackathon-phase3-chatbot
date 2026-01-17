"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";

type Task = {
  id: number;
  user_id: string;
  title: string;
  description?: string | null;
  completed: boolean;
  created_at: string;
  updated_at: string;
};

const API_BASE =
  (process.env.NEXT_PUBLIC_API_BASE?.trim() ||
    "https://mehreenasghar5-todo-fastapi-backend.hf.space").replace(/\/+$/, "");

const AUTH_KEY = "todo_user_id";

type ChatMsg = { role: "user" | "bot"; text: string };

export default function DashboardPage() {
  const router = useRouter();

  const [userId, setUserId] = useState<string>("");
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);

  const [newTitle, setNewTitle] = useState("");
  const [newDesc, setNewDesc] = useState("");
  const [creating, setCreating] = useState(false);

  const [toast, setToast] = useState<string | null>(null);
  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2000);
  };

  // ✅ CHAT (floating) STATES
  const [chatOpen, setChatOpen] = useState(false);
  const [chatInput, setChatInput] = useState("");
  const [chatSending, setChatSending] = useState(false);
  const [chatMsgs, setChatMsgs] = useState<ChatMsg[]>([
    {
      role: "bot",
      text: 'Commands: list, pending, completed, stats, add: Title | optional description, complete: <id>, delete: <id>',
    },
  ]);

  const chatScrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const id = localStorage.getItem(AUTH_KEY);
    if (!id) {
      router.replace("/signin");
      return;
    }
    setUserId(id);
  }, [router]);

  const fetchTasks = async (id: string) => {
    setLoading(true);
    try {
      const url = `${API_BASE}/api/${encodeURIComponent(id)}/tasks/`;
      const res = await fetch(url, { cache: "no-store" });
      const data = await res.json();
      setTasks(Array.isArray(data) ? data : []);
    } catch {
      setTasks([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!userId) return;
    fetchTasks(userId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  const totals = useMemo(() => {
    const total = tasks.length;
    const completed = tasks.filter((t) => t.completed).length;
    return { total, completed, pending: total - completed };
  }, [tasks]);

  const createTask = async () => {
    if (!newTitle.trim()) return;

    setCreating(true);
    try {
      const url = `${API_BASE}/api/${encodeURIComponent(userId)}/tasks/`;
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: newTitle.trim(),
          description: newDesc.trim() || null,
        }),
      });

      if (res.ok) {
        setNewTitle("");
        setNewDesc("");
        await fetchTasks(userId);
        showToast("✅ Task added");
      } else {
        showToast("❌ Add failed");
      }
    } finally {
      setCreating(false);
    }
  };

  const toggleComplete = async (taskId: number) => {
    const url = `${API_BASE}/api/${encodeURIComponent(userId)}/tasks/${taskId}/complete`;
    const res = await fetch(url, { method: "PATCH" });
    if (res.ok) {
      await fetchTasks(userId);
      showToast("✅ Status updated");
    } else {
      showToast("❌ Update failed");
    }
  };

  const deleteTask = async (taskId: number) => {
    const url = `${API_BASE}/api/${encodeURIComponent(userId)}/tasks/${taskId}`;
    const res = await fetch(url, { method: "DELETE" });
    if (res.ok) {
      await fetchTasks(userId);
      showToast("🗑️ Task deleted");
    } else {
      showToast("❌ Delete failed");
    }
  };

  // ✅ CHAT HANDLER (backend expects POST /api/{user_id}/chat)
  const sendChat = async () => {
    const msg = chatInput.trim();
    if (!msg) return;

    setChatSending(true);
    setChatInput("");

    setChatMsgs((prev) => [...prev, { role: "user", text: msg }]);

    try {
      const url = `${API_BASE}/api/${encodeURIComponent(userId)}/chat`;
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: msg }),
      });

      const data = await res.json().catch(() => ({}));

      if (res.ok) {
        const reply =
          typeof data?.reply === "string"
            ? data.reply
            : typeof data === "string"
              ? data
              : JSON.stringify(data);

        setChatMsgs((prev) => [...prev, { role: "bot", text: reply }]);
        await fetchTasks(userId); // chat ke baad refresh
      } else {
        const err =
          typeof data?.detail === "string" ? data.detail : "❌ Chat failed";
        setChatMsgs((prev) => [...prev, { role: "bot", text: err }]);
      }
    } catch {
      setChatMsgs((prev) => [...prev, { role: "bot", text: "❌ Chat failed" }]);
    } finally {
      setChatSending(false);
    }
  };

  useEffect(() => {
    if (!chatOpen) return;
    const el = chatScrollRef.current;
    if (!el) return;
    el.scrollTop = el.scrollHeight;
  }, [chatMsgs, chatOpen]);

  const signOut = () => {
    localStorage.removeItem(AUTH_KEY);
    router.push("/signin");
  };

  return (
    <main className="min-h-screen bg-[#0b0f14] px-4 py-10">
      <div className="mx-auto w-full max-w-6xl">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-[#f5c16c]">My Tasks</h1>
            <p className="text-gray-400 mt-1 text-sm">
              Signed in as <span className="text-gray-200">{userId}</span>
            </p>
          </div>

          <button
            onClick={signOut}
            className="rounded-xl border border-[#1f2937] bg-[#121821] px-4 py-2 text-sm text-gray-200 hover:border-[#f5c16c] transition"
          >
            Sign Out
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatCard label="Total Tasks" value={totals.total} color="text-white" />
          <StatCard label="Completed" value={totals.completed} color="text-green-400" />
          <StatCard label="Pending" value={totals.pending} color="text-orange-400" />
        </div>

        {/* NEW TASK */}
        <div className="bg-[#121821] rounded-2xl p-6 border border-[#1f2937] mb-8">
          <h2 className="text-white font-semibold text-lg mb-4">New Task</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <input
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="Task title"
              className="rounded-xl bg-[#0b0f14] border border-[#1f2937] px-4 py-3 text-white outline-none focus:border-[#f5c16c]"
            />
            <input
              value={newDesc}
              onChange={(e) => setNewDesc(e.target.value)}
              placeholder="Description (optional)"
              className="rounded-xl bg-[#0b0f14] border border-[#1f2937] px-4 py-3 text-white outline-none focus:border-[#f5c16c]"
            />
            <button
              onClick={createTask}
              disabled={creating}
              className="rounded-xl py-3 font-semibold text-black bg-[#f5c16c] hover:brightness-95 transition disabled:opacity-60"
            >
              {creating ? "Adding..." : "Add Task"}
            </button>
          </div>
        </div>

        {/* TASK LIST */}
        <div className="space-y-4">
          {loading ? (
            <div className="text-gray-400">Loading tasks...</div>
          ) : tasks.length === 0 ? (
            <div className="text-gray-400">No tasks yet. Add your first task.</div>
          ) : (
            tasks.map((t) => (
              <div
                key={t.id}
                className="bg-[#121821] rounded-2xl p-5 border border-[#1f2937] flex items-center justify-between"
              >
                <div className="flex items-start gap-4">
                  <button
                    onClick={() => toggleComplete(t.id)}
                    className={[
                      "mt-1 h-5 w-5 rounded border transition",
                      t.completed
                        ? "bg-green-500/20 border-green-500"
                        : "bg-transparent border-[#334155] hover:border-[#f5c16c]",
                    ].join(" ")}
                  />
                  <div>
                    <h3 className={t.completed ? "text-gray-400 line-through" : "text-white font-semibold"}>
                      {t.title}
                    </h3>
                    {t.description && <p className="text-sm text-gray-400 mt-1">{t.description}</p>}
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span
                    className={[
                      "text-xs px-3 py-1 rounded-full border",
                      t.completed
                        ? "border-green-500/40 text-green-300 bg-green-500/10"
                        : "border-orange-500/40 text-orange-300 bg-orange-500/10",
                    ].join(" ")}
                  >
                    {t.completed ? "Completed" : "Pending"}
                  </span>

                  <button
                    onClick={() => deleteTask(t.id)}
                    className="rounded-xl border border-[#1f2937] bg-[#0b0f14] px-4 py-2 text-sm text-gray-200 hover:border-red-500 transition"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* ✅ FLOATING AI BUTTON */}
      <button
        onClick={() => setChatOpen(true)}
        className="fixed bottom-6 right-6 z-40 h-12 w-12 rounded-full bg-[#f5c16c] text-black font-bold shadow-2xl hover:brightness-95 transition"
        aria-label="Open Todo AI Assistant"
      >
        AI
      </button>

      {/* ✅ CHAT MODAL */}
      {chatOpen && (
        <div className="fixed inset-0 z-50">
          {/* overlay */}
          <button
            className="absolute inset-0 bg-black/50"
            onClick={() => setChatOpen(false)}
            aria-label="Close overlay"
          />

          {/* panel */}
          <div className="absolute bottom-6 right-6 w-[360px] max-w-[92vw] rounded-2xl border border-[#1f2937] bg-[#121821] shadow-2xl">
            <div className="flex items-center justify-between px-4 py-3 border-b border-[#1f2937]">
              <div className="flex items-center gap-2">
                <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-[#0b0f14] border border-[#1f2937] text-sm">
                  🤖
                </span>
                <div className="text-sm font-semibold text-[#f5c16c]">Todo AI Assistant</div>
              </div>

              <button
                onClick={() => setChatOpen(false)}
                className="text-gray-300 hover:text-white text-xl leading-none"
                aria-label="Close chat"
              >
                ×
              </button>
            </div>

            <div
              ref={chatScrollRef}
              className="max-h-[320px] overflow-y-auto px-4 py-3 space-y-3"
            >
              {chatMsgs.map((m, idx) => (
                <div key={idx} className={m.role === "user" ? "flex justify-end" : "flex justify-start"}>
                  <div
                    className={[
                      "max-w-[85%] rounded-2xl px-3 py-2 text-sm border",
                      m.role === "user"
                        ? "bg-[#f5c16c] text-black border-[#f5c16c]"
                        : "bg-[#0b0f14] text-gray-100 border-[#1f2937]",
                    ].join(" ")}
                  >
                    <pre className="whitespace-pre-wrap font-sans">{m.text}</pre>
                  </div>
                </div>
              ))}
            </div>

            {/* input row */}
            <div className="px-4 pb-4 pt-2 border-t border-[#1f2937]">
              <div className="flex items-center gap-3">
                {/* ✅ IMPORTANT FIX: input NOT transparent */}
                <input
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") sendChat();
                  }}
                  placeholder='Type: "list" or "add: Buy milk | 2L"'
                  className="
                    flex-1
                    rounded-xl
                    px-4 py-3
                    text-white
                    bg-[#0b0f14]
                    bg-opacity-100
                    border border-[#1f2937]
                    outline-none
                    placeholder:text-gray-400
                    focus:border-[#f5c16c]
                  "
                />

                <button
                  onClick={sendChat}
                  disabled={chatSending || !chatInput.trim()}
                  className="rounded-xl px-5 py-3 font-semibold text-black bg-[#f5c16c] hover:brightness-95 transition disabled:opacity-60"
                >
                  {chatSending ? "..." : "Send"}
                </button>
              </div>

              <div className="mt-2 text-[11px] text-gray-400">
                Examples: <span className="text-gray-300">list</span>,{" "}
                <span className="text-gray-300">pending</span>,{" "}
                <span className="text-gray-300">completed</span>,{" "}
                <span className="text-gray-300">stats</span>,{" "}
                <span className="text-gray-300">add: milk | 2 liters</span>,{" "}
                <span className="text-gray-300">complete: 1</span>,{" "}
                <span className="text-gray-300">delete: 1</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {toast && (
        <div className="fixed bottom-6 right-24 z-50 rounded-xl border border-[#1f2937] bg-[#121821] px-4 py-3 text-sm text-gray-100 shadow-2xl">
          {toast}
        </div>
      )}
    </main>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="bg-[#121821] rounded-2xl p-6 border border-[#1f2937]">
      <p className="text-gray-400 text-sm">{label}</p>
      <p className={`text-2xl font-bold mt-2 ${color}`}>{value}</p>
    </div>
  );
}
