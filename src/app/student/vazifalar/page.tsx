import type { Metadata } from "next";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill, toneForStatus } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { studentAssignments, type Assignment } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Vazifalar" };

const all: Assignment[] = [
  ...studentAssignments,
  { title: "Speaking mock #2", course: "IELTS Intensive", due: "30-may", status: "Kutilmoqda" },
  { title: "Vocabulary quiz — Unit 8", course: "General English", due: "28-may", status: "Baholandi", score: "18/20" },
  { title: "React props mashqi", course: "Frontend — React", due: "27-may", status: "Tekshirilmoqda" },
];

const summary = [
  { label: "Kutilmoqda", count: all.filter((a) => a.status === "Kutilmoqda").length, tone: "amber" as const },
  { label: "Tekshirilmoqda", count: all.filter((a) => a.status === "Tekshirilmoqda").length, tone: "sky" as const },
  { label: "Baholandi", count: all.filter((a) => a.status === "Baholandi").length, tone: "emerald" as const },
];

export default function StudentAssignmentsPage() {
  return (
    <div>
      <PageIntro title="Vazifalar" subtitle="Barcha topshiriqlar va ularning holati" />

      <div className="mb-5 grid grid-cols-3 gap-4">
        {summary.map((s) => (
          <PanelCard key={s.label} className="!p-4 text-center sm:!p-5">
            <p className="text-2xl font-semibold text-white sm:text-3xl">{s.count}</p>
            <div className="mt-2 flex justify-center">
              <StatusPill label={s.label} tone={s.tone} />
            </div>
          </PanelCard>
        ))}
      </div>

      <PanelCard title="Barcha vazifalar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[40rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Vazifa</th>
                <th className="pb-3 font-medium">Muddat</th>
                <th className="pb-3 font-medium">Holat</th>
                <th className="pb-3 font-medium">Ball</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {all.map((a) => (
                <tr key={a.title} className="text-white/80">
                  <td className="py-3 pr-4">
                    <p className="font-medium text-white">{a.title}</p>
                    <p className="text-xs text-white/45">{a.course}</p>
                  </td>
                  <td className="py-3 pr-4 text-white/60">{a.due}</td>
                  <td className="py-3 pr-4">
                    <StatusPill label={a.status} tone={toneForStatus(a.status)} />
                  </td>
                  <td className="py-3 pr-4 font-semibold text-white">{a.score ?? "—"}</td>
                  <td className="py-3 text-right">
                    {a.status === "Kutilmoqda" ? (
                      <GlassButton size="sm">Topshirish</GlassButton>
                    ) : (
                      <GlassButton variant="glass" size="sm">
                        Ko'rish
                      </GlassButton>
                    )}
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
