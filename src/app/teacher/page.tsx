import type { Metadata } from "next";
import { Plus, Megaphone, ClipboardCheck } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { KpiGrid } from "@/components/panel/KpiGrid";
import { PanelCard } from "@/components/panel/PanelCard";
import { Reveal } from "@/components/ui/Reveal";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";
import { cn } from "@/lib/utils";
import {
  teacherKpis,
  teacherGroups,
  gradingQueue,
  todaySchedule,
} from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Boshqaruv paneli" };

export default function TeacherDashboard() {
  return (
    <div className="space-y-6">
      <PageIntro
        title="Xush kelibsiz, Dilnoza 👋"
        subtitle="Bugun 5 ta darsingiz va 12 ta tekshirilmagan vazifa bor."
        action={
          <GlassButton href="/teacher/vazifalar" size="md">
            <Plus className="h-4 w-4" /> Yangi vazifa
          </GlassButton>
        }
      />

      <KpiGrid items={teacherKpis} />

      <div className="grid gap-5 lg:grid-cols-3">
        {/* Left column */}
        <div className="space-y-5 lg:col-span-2">
          <Reveal>
            <PanelCard
              title="Guruhlarim"
              action={
                <a
                  href="/teacher/kurslar"
                  className="text-sm font-medium text-aurora-violet hover:text-aurora-pink"
                >
                  Barchasi
                </a>
              }
            >
              <div className="overflow-x-auto">
                <table className="w-full min-w-[40rem] text-left text-sm">
                  <thead>
                    <tr className="text-xs uppercase tracking-wide text-white/40">
                      <th className="pb-3 font-medium">Guruh</th>
                      <th className="pb-3 font-medium">Kurs</th>
                      <th className="pb-3 font-medium">O'quvchi</th>
                      <th className="pb-3 font-medium">Davomat</th>
                      <th className="pb-3 text-right font-medium">O'rtacha</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {teacherGroups.map((g) => (
                      <tr key={g.name} className="text-white/80">
                        <td className="py-3 pr-4">
                          <span className="flex items-center gap-2.5">
                            <span
                              className={cn(
                                "h-7 w-7 shrink-0 rounded-xl bg-gradient-to-br",
                                g.gradient,
                              )}
                            />
                            <span className="font-medium text-white">{g.name}</span>
                          </span>
                        </td>
                        <td className="py-3 pr-4 text-white/60">{g.course}</td>
                        <td className="py-3 pr-4">{g.students}</td>
                        <td className="py-3 pr-4">{g.attendance}%</td>
                        <td className="py-3 text-right font-semibold text-white">
                          {g.avgScore}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.05}>
            <PanelCard title="Bugungi darslar">
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
                      <p className="text-xs text-white/50">{s.mode}</p>
                    </div>
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>
        </div>

        {/* Right column */}
        <div className="space-y-5">
          <Reveal delay={0.1}>
            <PanelCard
              title="Tekshirish navbati"
              subtitle={`${gradingQueue.length} ta vazifa kutilmoqda`}
            >
              <div className="space-y-4">
                {gradingQueue.map((g) => (
                  <div key={g.student} className="flex items-center gap-3">
                    <Avatar initials={g.initials} gradient={g.gradient} size="sm" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-white">
                        {g.student}
                      </p>
                      <p className="truncate text-xs text-white/45">
                        {g.task} · {g.submitted}
                      </p>
                    </div>
                    <GlassButton size="sm">Baholash</GlassButton>
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.15}>
            <PanelCard title="Tezkor amallar">
              <div className="grid grid-cols-1 gap-2.5">
                <GlassButton variant="glass" size="md" className="justify-start">
                  <Plus className="h-4 w-4" /> Yangi dars yaratish
                </GlassButton>
                <GlassButton variant="glass" size="md" className="justify-start">
                  <Megaphone className="h-4 w-4" /> Guruhga e'lon
                </GlassButton>
                <GlassButton variant="glass" size="md" className="justify-start">
                  <ClipboardCheck className="h-4 w-4" /> Davomat olish
                </GlassButton>
              </div>
            </PanelCard>
          </Reveal>
        </div>
      </div>
    </div>
  );
}
