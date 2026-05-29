import type { Metadata } from "next";
import { Plus } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { cn } from "@/lib/utils";
import { teacherGroups } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Guruhlar" };

const teachers = [
  "Dilnoza Karimova",
  "Dilnoza Karimova",
  "Javohir Tursunov",
  "Kamola Rashidova",
];

const groups = teacherGroups.map((g, i) => ({ ...g, teacher: teachers[i] }));

export default function AdminGroupsPage() {
  return (
    <div>
      <PageIntro
        title="Guruhlar"
        subtitle="Markazdagi barcha o'quv guruhlari"
        action={
          <GlassButton size="md">
            <Plus className="h-4 w-4" /> Yangi guruh
          </GlassButton>
        }
      />

      <PanelCard title="Faol guruhlar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[46rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Guruh</th>
                <th className="pb-3 font-medium">Kurs</th>
                <th className="pb-3 font-medium">O'qituvchi</th>
                <th className="pb-3 font-medium">O'quvchi</th>
                <th className="pb-3 font-medium">Davomat</th>
                <th className="pb-3 text-right font-medium">O'rtacha</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {groups.map((g) => (
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
                  <td className="py-3 pr-4 text-white/60">{g.teacher}</td>
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
    </div>
  );
}
