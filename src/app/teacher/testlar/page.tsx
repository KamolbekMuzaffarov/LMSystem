import type { Metadata } from "next";
import { Plus } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill, type Tone } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";

export const metadata: Metadata = { title: "Testlar" };

const tests = [
  { title: "IELTS Reading Mock", group: "IELTS-B2", submissions: 16, status: "Faol" },
  { title: "Grammar Unit 7 Quiz", group: "IELTS-A1", submissions: 14, status: "Faol" },
  { title: "Vocabulary Midterm", group: "GE-Eve", submissions: 18, status: "Yopilgan" },
  { title: "Kids Spelling Test", group: "Kids-Sat", submissions: 8, status: "Qoralama" },
];

const toneMap: Record<string, Tone> = {
  Faol: "emerald",
  Yopilgan: "slate",
  Qoralama: "amber",
};

export default function TeacherTestsPage() {
  return (
    <div>
      <PageIntro
        title="Testlar"
        subtitle="Yaratgan testlaringiz va natijalari"
        action={
          <GlassButton size="md">
            <Plus className="h-4 w-4" /> Yangi test
          </GlassButton>
        }
      />

      <PanelCard title="Testlar ro'yxati">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[40rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Test nomi</th>
                <th className="pb-3 font-medium">Guruh</th>
                <th className="pb-3 font-medium">Topshirganlar</th>
                <th className="pb-3 font-medium">Holat</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {tests.map((t) => (
                <tr key={t.title} className="text-white/80">
                  <td className="py-3 pr-4 font-medium text-white">{t.title}</td>
                  <td className="py-3 pr-4 text-white/60">{t.group}</td>
                  <td className="py-3 pr-4">{t.submissions} ta</td>
                  <td className="py-3 pr-4">
                    <StatusPill label={t.status} tone={toneMap[t.status]} />
                  </td>
                  <td className="py-3 text-right">
                    <GlassButton variant="glass" size="sm">
                      Natijalar
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
