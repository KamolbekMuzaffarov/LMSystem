import type { Metadata } from "next";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";
import { gradingQueue, type GradingRow } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Vazifalar" };

const queue: GradingRow[] = [
  ...gradingQueue,
  { student: "Nilufar Tosheva", initials: "NT", gradient: "from-aurora-violet to-aurora-pink", task: "Essay: Globalization", submitted: "Kecha" },
  { student: "Sardor Yaxshiboyev", initials: "SY", gradient: "from-aurora-blue to-aurora-indigo", task: "Grammar test #5", submitted: "Kecha" },
];

const summary = [
  { label: "Tekshirilmagan", value: "12" },
  { label: "Bugun topshirilgan", value: "8" },
  { label: "Bu hafta baholangan", value: "34" },
];

export default function TeacherAssignmentsPage() {
  return (
    <div>
      <PageIntro title="Vazifalar" subtitle="Topshirilgan ishlarni tekshiring va baholang" />

      <div className="mb-5 grid grid-cols-3 gap-4">
        {summary.map((s) => (
          <PanelCard key={s.label} className="!p-4 text-center sm:!p-5">
            <p className="text-2xl font-semibold text-white sm:text-3xl">{s.value}</p>
            <p className="mt-1 text-xs text-white/50 sm:text-sm">{s.label}</p>
          </PanelCard>
        ))}
      </div>

      <PanelCard title="Tekshirish navbati">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[40rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">O'quvchi</th>
                <th className="pb-3 font-medium">Vazifa</th>
                <th className="pb-3 font-medium">Topshirilgan</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {queue.map((g, i) => (
                <tr key={i} className="text-white/80">
                  <td className="py-3 pr-4">
                    <span className="flex items-center gap-2.5">
                      <Avatar initials={g.initials} gradient={g.gradient} size="sm" />
                      <span className="font-medium text-white">{g.student}</span>
                    </span>
                  </td>
                  <td className="py-3 pr-4">{g.task}</td>
                  <td className="py-3 pr-4 text-white/60">{g.submitted}</td>
                  <td className="py-3 text-right">
                    <GlassButton size="sm">Baholash</GlassButton>
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
