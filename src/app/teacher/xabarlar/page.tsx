import type { Metadata } from "next";
import { Send, Search } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { GlassCard } from "@/components/ui/GlassCard";
import { Avatar } from "@/components/ui/Avatar";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: "Xabarlar" };

const convos = [
  { name: "Kamolbek Muzaffarov", initials: "KM", gradient: "from-aurora-violet to-aurora-blue", last: "Rahmat, tushunarli!", time: "10:24", unread: 0, active: true },
  { name: "IELTS-A1 guruhi", initials: "A1", gradient: "from-aurora-pink to-aurora-violet", last: "Bekzod: Dars qachon?", time: "09:48", unread: 2 },
  { name: "Bekzod Olimov", initials: "BO", gradient: "from-aurora-fuchsia to-aurora-violet", last: "Essayni yubordim", time: "09:10", unread: 1 },
  { name: "GE-Eve guruhi", initials: "GE", gradient: "from-aurora-cyan to-aurora-indigo", last: "Siz: Video yuklandi", time: "Kecha", unread: 0 },
  { name: "Madina Saidova", initials: "MS", gradient: "from-aurora-pink to-aurora-cyan", last: "Tushundim, rahmat 🙏", time: "Kecha", unread: 0 },
];

const thread = [
  { me: false, text: "Ustoz, Writing Task 2 ni qayta yuborsam bo'ladimi?", time: "10:18" },
  { me: true, text: "Albatta, ertaga 18:00 gacha yuboring.", time: "10:20" },
  { me: false, text: "Rahmat! Coherence bo'yicha maslahat bera olasizmi?", time: "10:22" },
  { me: true, text: "Har paragraf bitta asosiy fikrga ega bo'lsin va linking words ishlating.", time: "10:23" },
  { me: false, text: "Rahmat, tushunarli!", time: "10:24" },
];

export default function TeacherMessagesPage() {
  return (
    <div>
      <PageIntro title="Xabarlar" subtitle="O'quvchilar va guruhlar bilan aloqa" />

      <GlassCard className="grid h-[calc(100vh-13rem)] min-h-[28rem] grid-cols-1 overflow-hidden md:grid-cols-[18rem_1fr]">
        {/* Conversation list */}
        <div className="hidden flex-col border-r border-white/10 md:flex">
          <div className="p-3">
            <label className="flex items-center gap-2.5 rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2">
              <Search className="h-4 w-4 shrink-0 text-white/40" />
              <input
                placeholder="Qidirish..."
                className="w-full bg-transparent text-sm text-white placeholder:text-white/40 outline-none"
              />
            </label>
          </div>
          <div className="flex-1 overflow-y-auto px-2 pb-2">
            {convos.map((c) => (
              <button
                key={c.name}
                className={cn(
                  "flex w-full items-center gap-3 rounded-2xl px-2.5 py-2.5 text-left transition-colors",
                  c.active ? "bg-white/10" : "hover:bg-white/5",
                )}
              >
                <Avatar initials={c.initials} gradient={c.gradient} size="sm" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <p className="truncate text-sm font-medium text-white">{c.name}</p>
                    <span className="shrink-0 text-[11px] text-white/40">{c.time}</span>
                  </div>
                  <p className="truncate text-xs text-white/45">{c.last}</p>
                </div>
                {c.unread > 0 && (
                  <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-aurora-pink px-1.5 text-[11px] font-semibold text-white">
                    {c.unread}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Active thread */}
        <div className="flex min-w-0 flex-col">
          <div className="flex items-center gap-3 border-b border-white/10 px-4 py-3">
            <Avatar initials="KM" gradient="from-aurora-violet to-aurora-blue" size="sm" />
            <div>
              <p className="text-sm font-medium text-white">Kamolbek Muzaffarov</p>
              <p className="text-xs text-emerald-400">Onlayn</p>
            </div>
          </div>

          <div className="flex flex-1 flex-col gap-3 overflow-y-auto p-4">
            {thread.map((m, i) => (
              <div
                key={i}
                className={cn(
                  "flex max-w-[80%] flex-col gap-1",
                  m.me ? "self-end items-end" : "self-start items-start",
                )}
              >
                <div
                  className={cn(
                    "px-4 py-2.5 text-sm",
                    m.me
                      ? "rounded-2xl rounded-br-md bg-gradient-to-br from-aurora-violet to-aurora-indigo text-white"
                      : "glass glass-edge rounded-2xl rounded-bl-md text-white/85",
                  )}
                >
                  {m.text}
                </div>
                <span className="px-1 text-[11px] text-white/35">{m.time}</span>
              </div>
            ))}
          </div>

          <div className="border-t border-white/10 p-3">
            <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-white/5 py-1.5 pl-4 pr-1.5">
              <input
                placeholder="Xabar yozing..."
                className="w-full bg-transparent text-sm text-white placeholder:text-white/40 outline-none"
              />
              <button
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-aurora-violet to-aurora-indigo text-white shadow-glow-violet"
                aria-label="Yuborish"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </GlassCard>
    </div>
  );
}
