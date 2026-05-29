"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Eye, EyeOff, User, Phone, Lock, ArrowRight, ShieldCheck } from "lucide-react";
import { GlassButton } from "@/components/ui/GlassButton";
import { SocialButtons } from "@/components/sections/SocialButtons";
import { cn } from "@/lib/utils";

const fieldCls =
  "h-12 w-full rounded-2xl border border-white/10 bg-white/5 pl-11 pr-4 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10";

export function RegisterForm() {
  const [show, setShow] = useState(false);
  const router = useRouter();

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    router.push("/student");
  }

  return (
    <div>
      <h1 className="text-3xl font-semibold tracking-tight text-white">Hisob yarating ✨</h1>
      <p className="mt-2 text-sm text-white/55">
        1 daqiqada ro'yxatdan o'ting va bepul demo darsdan boshlang.
      </p>

      <form onSubmit={onSubmit} className="mt-6 flex flex-col gap-4">
        <div className="relative">
          <User className="absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input required placeholder="To'liq ism" className={fieldCls} />
        </div>
        <div className="relative">
          <Phone className="absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input required type="tel" placeholder="Telefon raqam" className={fieldCls} defaultValue="+998 90 123 45 67" />
        </div>
        <div className="relative">
          <Lock className="absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input
            required
            type={show ? "text" : "password"}
            placeholder="Parol yarating"
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

        <div className="glass flex items-center gap-2.5 rounded-2xl px-4 py-3 text-xs text-white/55">
          <ShieldCheck className="h-4 w-4 shrink-0 text-emerald-400" />
          Telefoningizga SMS orqali tasdiqlash kodi (OTP) yuboriladi.
        </div>

        <label className="flex items-start gap-2.5 text-sm text-white/60">
          <input required type="checkbox" className="mt-0.5 h-4 w-4 rounded border-white/20 bg-white/10 accent-aurora-violet" />
          <span>
            <Link href="#" className="text-aurora-violet hover:text-aurora-pink">Foydalanish shartlari</Link> va{" "}
            <Link href="#" className="text-aurora-violet hover:text-aurora-pink">maxfiylik siyosati</Link>ga roziman.
          </span>
        </label>

        <GlassButton type="submit" size="lg" className="w-full">
          Ro'yxatdan o'tish <ArrowRight className="h-5 w-5" />
        </GlassButton>
      </form>

      <SocialButtons />

      <p className="mt-6 text-center text-sm text-white/55">
        Hisobingiz bormi?{" "}
        <Link href="/kirish" className="font-medium text-aurora-violet hover:text-aurora-pink">
          Kirish
        </Link>
      </p>
    </div>
  );
}
