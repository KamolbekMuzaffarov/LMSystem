import type { Metadata } from "next";
import { Download } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { BarChart } from "@/components/panel/BarChart";
import { ProgressBar } from "@/components/panel/ProgressBar";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { revenueData } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Hisobotlar" };

const kpis = [
  { label: "Konversiya", value: "38%", trend: "ariza → o'quvchi" },
  { label: "O'rtacha to'lov", value: "1.1 mln", trend: "har o'quvchi" },
  { label: "Faol foydalanuvchi", value: "9 240", trend: "oxirgi 30 kun" },
  { label: "Churn darajasi", value: "4.2%", trend: "−0.6% o'tgan oyga" },
];

const dist = [
  { label: "IELTS", value: 42, gradient: "from-aurora-violet to-aurora-blue" },
  { label: "Ingliz tili", value: 28, gradient: "from-aurora-cyan to-aurora-indigo" },
  { label: "Dasturlash", value: 18, gradient: "from-aurora-fuchsia to-aurora-violet" },
  { label: "Dizayn", value: 8, gradient: "from-aurora-pink to-aurora-fuchsia" },
  { label: "Matematika", value: 4, gradient: "from-aurora-blue to-aurora-indigo" },
];

export default function AdminReportsPage() {
  return (
    <div>
      <PageIntro
        title="Hisobotlar"
        subtitle="Markaz ko'rsatkichlari va tahlillar"
        action={
          <GlassButton size="md">
            <Download className="h-4 w-4" /> Yuklab olish
          </GlassButton>
        }
      />

      <Stagger className="mb-5 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {kpis.map((k) => (
          <StaggerItem key={k.label} className="h-full">
            <GlassCard className="h-full p-5">
              <p className="text-2xl font-semibold tracking-tight text-white sm:text-3xl">
                {k.value}
              </p>
              <p className="mt-1 text-sm text-white/55">{k.label}</p>
              <p className="mt-3 text-xs font-medium text-aurora-cyan">{k.trend}</p>
            </GlassCard>
          </StaggerItem>
        ))}
      </Stagger>

      <div className="grid gap-5 lg:grid-cols-2">
        <PanelCard title="Oylik daromad" subtitle="mln so'm">
          <BarChart data={revenueData} />
        </PanelCard>

        <PanelCard title="Kurslar bo'yicha taqsimot" subtitle="O'quvchilar ulushi">
          <div className="space-y-4">
            {dist.map((d) => (
              <div key={d.label}>
                <div className="mb-1.5 flex items-center justify-between text-sm">
                  <span className="text-white/75">{d.label}</span>
                  <span className="font-semibold text-white">{d.value}%</span>
                </div>
                <ProgressBar value={d.value} gradient={d.gradient} />
              </div>
            ))}
          </div>
        </PanelCard>
      </div>
    </div>
  );
}
