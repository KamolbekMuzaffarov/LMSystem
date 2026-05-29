"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Eye, EyeOff, Mail, Lock, ArrowRight } from "lucide-react";
import { GlassButton } from "@/components/ui/GlassButton";
import { SocialButtons } from "@/components/sections/SocialButtons";
import { cn } from "@/lib/utils";

const fieldWrap = "relative";
const fieldCls =
  "h-12 w-full rounded-2xl border border-white/10 bg-white/5 pl-11 pr-4 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10";

const roles = [
  { label: "O'quvchi", href: "/student" },
  { label: "O'qituvchi", href: "/teacher" },
  { label: "Admin", href: "/admin" },
];

export function LoginForm() {
  const [show, setShow] = useState(false);
  const [role, setRole] = useState(0);
  const router = useRouter();

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    router.push(roles[role].href);
  }

  return (
    <div>
      <h1 className="text-3xl font-semibold tracking-tight text-white">Xush kelibsiz 👋</h1>
      <p className="mt-2 text-sm text-white/55">
        Hisobingizga kiring va o'rganishni davom ettiring.
      </p>

      {/* demo role selector */}
      <div className="mt-6">
        <span className="text-xs uppercase tracking-wider text-white/40">Demo: panel tanlang</span>
        <div className="mt-2 grid grid-cols-3 gap-2">
          {roles.map((r, i) => (
            <button
              key={r.label}
              type="button"
              onClick={() => setRole(i)}
              className={cn(
                "rounded-xl py-2 text-sm font-medium transition-all",
                role === i
                  ? "bg-gradient-to-br from-aurora-violet to-aurora-indigo text-white shadow-glow-violet"
                  : "glass text-white/60 hover:text-white",
              )}
            >
              {r.label}
            </button>
          ))}
        </div>
      </div>

      <form onSubmit={onSubmit} className="mt-6 flex flex-col gap-4">
        <div className={fieldWrap}>
          <Mail className="absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input required type="text" placeholder="Email yoki telefon" className={fieldCls} defaultValue="demo@aurora.uz" />
        </div>
        <div className={fieldWrap}>
          <Lock className="absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input
            required
            type={show ? "text" : "password"}
            placeholder="Parol"
            defaultValue="demo1234"
            className={cn(fieldCls, "pr-11")}
          />
          <button
            type="button"
            onClick={() => setShow((v) => !v)}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/40 hover:text-white"
          >
            {show ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
          </button>
        </div>

        <div className="flex items-center justify-between text-sm">
          <label className="flex items-center gap-2 text-white/60">
            <input type="checkbox" className="h-4 w-4 rounded border-white/20 bg-white/10 accent-aurora-violet" />
            Eslab qolish
          </label>
          <Link href="#" className="text-aurora-violet hover:text-aurora-pink">
            Parolni unutdingizmi?
          </Link>
        </div>

        <GlassButton type="submit" size="lg" className="w-full">
          Kirish <ArrowRight className="h-5 w-5" />
        </GlassButton>
      </form>

      <SocialButtons />

      <p className="mt-6 text-center text-sm text-white/55">
        Hisobingiz yo'qmi?{" "}
        <Link href="/royxat" className="font-medium text-aurora-violet hover:text-aurora-pink">
          Ro'yxatdan o'ting
        </Link>
      </p>
    </div>
  );
}
