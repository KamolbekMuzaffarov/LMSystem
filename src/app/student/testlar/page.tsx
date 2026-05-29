import type { Metadata } from "next";
import { Clock, ListChecks, Play } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: "Testlar" };

const available = [
  { title: "IELTS Mock — to'liq", emoji: "🎯", q: 80, mins: 165, gradient: "from-aurora-violet to-aurora-blue" },
  { title: "Grammar — Unit 7", emoji: "✍️", q: 25, mins: 30, gradient: "from-aurora-cyan to-aurora-indigo" },
  { title: "Vocabulary B2", emoji: "📚", q: 40, mins: 45, gradient: "from-aurora-fuchsia to-aurora-violet" },
];

const results = [
  { test: "IELTS Listening Mock", date: "25-may", score: "8.5 / 9" },
  { test: "Grammar — Unit 6", date: "22-may", score: "22 / 25" },
  { test: "Reading practice #3", date: "19-may", score: "7.0 / 9" },
];

export default function StudentTestsPage() {
  return (
    <div>
      <PageIntro title="Testlar" subtitle="Mavjud testlar va o'tilgan natijalar" />

      <Stagger className="mb-5 grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
        {available.map((t) => (
          <StaggerItem key={t.title} className="h-full">
            <GlassCard sheen className="flex h-full flex-col p-5">
              <span
                className={cn(
                  "flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br text-2xl shadow-glass",
                  t.gradient,
                )}
              >
                {t.emoji}
              </span>
              <h3 className="mt-4 font-semibold text-white">{t.title}</h3>
              <div className="mt-3 flex items-center gap-4 text-xs text-white/55">
                <span className="flex items-center gap-1.5">
                  <ListChecks className="h-4 w-4" /> {t.q} savol
                </span>
                <span className="flex items-center gap-1.5">
                  <Clock className="h-4 w-4" /> {t.mins} daqiqa
                </span>
              </div>
              <div className="mt-5 pt-1">
                <GlassButton size="sm" className="w-full">
                  <Play className="h-4 w-4" /> Boshlash
                </GlassButton>
              </div>
            </GlassCard>
          </StaggerItem>
        ))}
      </Stagger>

      <PanelCard title="So'nggi natijalar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[32rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Test</th>
                <th className="pb-3 font-medium">Sana</th>
                <th className="pb-3 font-medium">Ball</th>
                <th className="pb-3 text-right font-medium">Holat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {results.map((r, i) => (
                <tr key={i} className="text-white/80">
                  <td className="py-3 pr-4 font-medium text-white">{r.test}</td>
                  <td className="py-3 pr-4 text-white/60">{r.date}</td>
                  <td className="py-3 pr-4 font-semibold text-white">{r.score}</td>
                  <td className="py-3 text-right">
                    <StatusPill label="Baholandi" tone="emerald" />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </PanelCard>
    </div>
  );
}
