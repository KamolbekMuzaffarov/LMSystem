import { CheckCircle2, Sparkles } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import type { ReactNode } from "react";

const perks = [
  "AI yordamida yozma ish tekshiruvi",
  "Jonli darslar va mock testlar",
  "Shaxsiy o'quv yo'l xaritasi",
  "Tugatgach raqamli sertifikat",
];

export function AuthShell({ children }: { children: ReactNode }) {
  return (
    <div className="grid w-full max-w-5xl gap-6 lg:grid-cols-2">
      {/* decorative aside */}
      <div className="hidden lg:block">
        <GlassCard strong glow="violet" className="relative h-full overflow-hidden p-10">
          <div className="pointer-events-none absolute -right-1/4 -top-1/4 h-72 w-72 rounded-full bg-aurora-violet/40 blur-3xl" />
          <div className="pointer-events-none absolute -bottom-1/4 -left-1/4 h-72 w-72 rounded-full bg-aurora-pink/30 blur-3xl" />
          <div className="relative z-10 flex h-full flex-col">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
              <Sparkles className="h-6 w-6 text-white" />
            </span>
            <h2 className="mt-6 text-balance text-4xl font-semibold leading-tight tracking-tight text-white">
              Kelajagingizga <span className="gradient-text">bugun</span> sarmoya kiriting
            </h2>
            <p className="mt-4 text-white/60">
              12 000+ o'quvchi allaqachon Aurora Academy bilan maqsadlariga erishmoqda.
            </p>
            <ul className="mt-8 space-y-4">
              {perks.map((p) => (
                <li key={p} className="flex items-center gap-3 text-white/80">
                  <CheckCircle2 className="h-5 w-5 text-aurora-violet" />
                  {p}
                </li>
              ))}
            </ul>
            <div className="mt-auto flex items-center gap-3 pt-8">
              <div className="flex -space-x-3">
                {["from-aurora-violet to-aurora-pink", "from-aurora-cyan to-aurora-blue", "from-aurora-fuchsia to-aurora-violet"].map((g, i) => (
                  <span key={i} className={`h-9 w-9 rounded-full border-2 border-ink-soft bg-gradient-to-br ${g}`} />
                ))}
              </div>
              <span className="text-sm text-white/55">+12 000 o'quvchi qo'shildi</span>
            </div>
          </div>
        </GlassCard>
      </div>

      {/* form card */}
      <GlassCard className="p-7 sm:p-9">{children}</GlassCard>
    </div>
  );
}
