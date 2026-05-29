import type { Metadata } from "next";
import { Play, ChevronRight } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { KpiGrid } from "@/components/panel/KpiGrid";
import { PanelCard } from "@/components/panel/PanelCard";
import { ProgressBar } from "@/components/panel/ProgressBar";
import { StatusPill, toneForStatus } from "@/components/panel/StatusPill";
import { Reveal } from "@/components/ui/Reveal";
import { GlassButton } from "@/components/ui/GlassButton";
import { cn } from "@/lib/utils";
import {
  studentKpis,
  studentCourses,
  studentAssignments,
  todaySchedule,
  achievements,
  notificationsFeed,
} from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Boshqaruv paneli" };

export default function StudentDashboard() {
  return (
    <div className="space-y-6">
      <PageIntro
        title="Assalomu alaykum, Kamolbek 👋"
        subtitle="Bugun 3 ta darsingiz va 1 ta topshiriq muddati bor. Davom etamizmi?"
        action={
          <GlassButton href="/student/kurslarim" size="md">
            <Play className="h-4 w-4" /> Darsni davom ettirish
          </GlassButton>
        }
      />

      <KpiGrid items={studentKpis} />

      <div className="grid gap-5 lg:grid-cols-3">
        {/* Left column */}
        <div className="space-y-5 lg:col-span-2">
          <Reveal>
            <PanelCard
              title="Kurslarim"
              subtitle="Davom etayotgan kurslaringiz"
              action={
                <a
                  href="/student/kurslarim"
                  className="text-sm font-medium text-aurora-violet hover:text-aurora-pink"
                >
                  Barchasi
                </a>
              }
            >
              <div className="space-y-5">
                {studentCourses.map((c) => (
                  <div key={c.title} className="flex items-center gap-4">
                    <span
                      className={cn(
                        "flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br text-xl shadow-glass",
                        c.gradient,
                      )}
                    >
                      {c.emoji}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-3">
                        <p className="truncate font-medium text-white">{c.title}</p>
                        <span className="shrink-0 text-sm font-semibold text-white/80">
                          {c.progress}%
                        </span>
                      </div>
                      <ProgressBar
                        value={c.progress}
                        gradient={c.gradient}
                        className="mt-2"
                      />
                      <p className="mt-2 truncate text-xs text-white/45">
                        Keyingi dars: {c.nextLesson}
                      </p>
                    </div>
                    <ChevronRight className="hidden h-5 w-5 shrink-0 text-white/30 sm:block" />
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.05}>
            <PanelCard
              title="So'nggi vazifalar"
              action={
                <a
                  href="/student/vazifalar"
                  className="text-sm font-medium text-aurora-violet hover:text-aurora-pink"
                >
                  Barchasi
                </a>
              }
            >
              <div className="overflow-x-auto">
                <table className="w-full min-w-[34rem] text-left text-sm">
                  <thead>
                    <tr className="text-xs uppercase tracking-wide text-white/40">
                      <th className="pb-3 font-medium">Vazifa</th>
                      <th className="pb-3 font-medium">Muddat</th>
                      <th className="pb-3 font-medium">Holat</th>
                      <th className="pb-3 text-right font-medium">Ball</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {studentAssignments.map((a) => (
                      <tr key={a.title} className="text-white/80">
                        <td className="py-3 pr-4">
                          <p className="font-medium text-white">{a.title}</p>
                          <p className="text-xs text-white/45">{a.course}</p>
                        </td>
                        <td className="py-3 pr-4 text-white/60">{a.due}</td>
                        <td className="py-3 pr-4">
                          <StatusPill label={a.status} tone={toneForStatus(a.status)} />
                        </td>
                        <td className="py-3 text-right font-semibold text-white">
                          {a.score ?? "—"}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </PanelCard>
          </Reveal>
        </div>

        {/* Right column */}
        <div className="space-y-5">
          <Reveal delay={0.1}>
            <PanelCard title="Bugungi jadval">
              <div className="space-y-4">
                {todaySchedule.map((s) => (
                  <div key={s.title} className="flex items-stretch gap-3">
                    <span className="w-12 shrink-0 pt-0.5 text-sm font-semibold text-white">
                      {s.time}
                    </span>
                    <span
                      className={cn(
                        "w-1 shrink-0 rounded-full bg-gradient-to-b",
                        s.gradient,
                      )}
                    />
                    <div className="min-w-0">
                      <p className="truncate font-medium text-white">{s.title}</p>
                      <p className="text-xs text-white/50">
                        {s.teacher} · {s.mode}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.15}>
            <PanelCard title="Yutuqlar">
              <div className="flex flex-wrap gap-2">
                {achievements.map((a) => (
                  <span
                    key={a.label}
                    className="glass glass-edge flex items-center gap-2 rounded-full px-3 py-1.5 text-sm text-white/80"
                  >
                    <span className="text-base leading-none">{a.emoji}</span>
                    {a.label}
                  </span>
                ))}
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.2}>
            <PanelCard title="Bildirishnomalar">
              <div className="space-y-4">
                {notificationsFeed.map((n, i) => {
                  const Icon = n.icon;
                  return (
                    <div key={i} className="flex gap-3">
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white/5 text-aurora-violet ring-1 ring-inset ring-white/10">
                        <Icon className="h-4 w-4" />
                      </span>
                      <div className="min-w-0">
                        <p className="text-sm leading-snug text-white/80">{n.text}</p>
                        <p className="mt-0.5 text-xs text-white/40">{n.time}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </PanelCard>
          </Reveal>
        </div>
      </div>
    </div>
  );
}
