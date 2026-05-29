import { GlassCard } from "@/components/ui/GlassCard";
import type { LucideIcon } from "lucide-react";

export function PanelPlaceholder({
  icon: Icon,
  title,
  description,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
}) {
  return (
    <GlassCard
      glow="violet"
      className="relative flex flex-col items-center justify-center gap-4 overflow-hidden px-6 py-20 text-center"
    >
      <div className="pointer-events-none absolute -top-1/3 left-1/2 h-72 w-72 -translate-x-1/2 rounded-full bg-aurora-violet/20 blur-3xl" />
      <span className="relative flex h-16 w-16 items-center justify-center rounded-3xl bg-gradient-to-br from-aurora-violet to-aurora-pink text-white shadow-glow-violet">
        <Icon className="h-7 w-7" />
      </span>
      <h2 className="relative text-xl font-semibold tracking-tight text-white">
        {title}
      </h2>
      <p className="relative max-w-md text-sm leading-relaxed text-white/55">
        {description}
      </p>
      <span className="glass glass-edge relative rounded-full px-4 py-1.5 text-xs text-white/60">
        Interfeys tayyorlanmoqda — tez orada
      </span>
    </GlassCard>
  );
}
