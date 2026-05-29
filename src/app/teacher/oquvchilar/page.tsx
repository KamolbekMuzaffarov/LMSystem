import type { Metadata } from "next";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";

export const metadata: Metadata = { title: "O'quvchilar" };

const students = [
  { name: "Kamolbek Muzaffarov", initials: "KM", gradient: "from-aurora-violet to-aurora-blue", group: "IELTS-A1", attendance: 96, avg: "7.5", status: "Faol" },
  { name: "Bekzod Olimov", initials: "BO", gradient: "from-aurora-fuchsia to-aurora-violet", group: "IELTS-B2", attendance: 88, avg: "6.5", status: "Faol" },
  { name: "Madina Saidova", initials: "MS", gradient: "from-aurora-pink to-aurora-cyan", group: "IELTS-A1", attendance: 92, avg: "7.0", status: "Faol" },
  { name: "Jasur Komilov", initials: "JK", gradient: "from-aurora-cyan to-aurora-indigo", group: "GE-Eve", attendance: 74, avg: "68", status: "Nofaol" },
  { name: "Nilufar Tosheva", initials: "NT", gradient: "from-aurora-violet to-aurora-pink", group: "IELTS-B2", attendance: 99, avg: "7.8", status: "Faol" },
  { name: "Sardor Yaxshiboyev", initials: "SY", gradient: "from-aurora-blue to-aurora-indigo", group: "GE-Eve", attendance: 81, avg: "72", status: "Faol" },
  { name: "Kamola Ergasheva", initials: "KE", gradient: "from-aurora-pink to-aurora-fuchsia", group: "Kids-Sat", attendance: 100, avg: "94", status: "Faol" },
  { name: "Diyor Mahmudov", initials: "DM", gradient: "from-aurora-indigo to-aurora-cyan", group: "IELTS-A1", attendance: 65, avg: "5.5", status: "Nofaol" },
];

export default function TeacherStudentsPage() {
  return (
    <div>
      <PageIntro title="O'quvchilar" subtitle="128 o'quvchi · 4 guruh" />

      <PanelCard title="Barcha o'quvchilar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[44rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">O'quvchi</th>
                <th className="pb-3 font-medium">Guruh</th>
                <th className="pb-3 font-medium">Davomat</th>
                <th className="pb-3 font-medium">O'rtacha</th>
                <th className="pb-3 font-medium">Holat</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {students.map((s) => (
                <tr key={s.name} className="text-white/80">
                  <td className="py-3 pr-4">
                    <span className="flex items-center gap-2.5">
                      <Avatar initials={s.initials} gradient={s.gradient} size="sm" />
                      <span className="font-medium text-white">{s.name}</span>
                    </span>
                  </td>
                  <td className="py-3 pr-4 text-white/60">{s.group}</td>
                  <td className="py-3 pr-4">{s.attendance}%</td>
                  <td className="py-3 pr-4 font-semibold text-white">{s.avg}</td>
                  <td className="py-3 pr-4">
                    <StatusPill
                      label={s.status}
                      tone={s.status === "Faol" ? "emerald" : "slate"}
                    />
                  </td>
                  <td className="py-3 text-right">
                    <GlassButton variant="glass" size="sm">
                      Profil
                    </GlassButton>
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
