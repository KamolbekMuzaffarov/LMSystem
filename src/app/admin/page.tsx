import type { Metadata } from "next";
import { Download } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { KpiGrid } from "@/components/panel/KpiGrid";
import { PanelCard } from "@/components/panel/PanelCard";
import { BarChart } from "@/components/panel/BarChart";
import { StatusPill, toneForStatus } from "@/components/panel/StatusPill";
import { Reveal } from "@/components/ui/Reveal";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";
import { adminKpis, revenueData, applications } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Boshqaruv paneli" };

const quickStats = [
  { label: "Bugungi arizalar", value: "24" },
  { label: "Faol guruhlar", value: "52" },
  { label: "To'lov kutilmoqda", value: "31" },
  { label: "O'rtacha NPS", value: "72" },
];

const systems = [
  { label: "Server", ok: true },
  { label: "To'lov shlyuzi (Payme/Click)", ok: true },
  { label: "Telegram bot", ok: true },
  { label: "Zoom integratsiyasi", ok: true },
];

export default function AdminDashboard() {
  return (
    <div className="space-y-6">
      <PageIntro
        title="Administrator paneli"
        subtitle="Markazning umumiy ko'rsatkichlari va so'nggi faollik."
        action={
          <GlassButton href="/admin/hisobotlar" size="md">
            <Download className="h-4 w-4" /> Hisobot
          </GlassButton>
        }
      />

      <KpiGrid items={adminKpis} />

      <div className="grid gap-5 lg:grid-cols-3">
        {/* Left column */}
        <div className="space-y-5 lg:col-span-2">
          <Reveal>
            <PanelCard title="Daromad dinamikasi" subtitle="Oxirgi 6 oy (mln so'm)">
              <BarChart data={revenueData} />
            </PanelCard>
          </Reveal>

          <Reveal delay={0.05}>
            <PanelCard
              title="So'nggi arizalar"
              action={
                <a
                  href="/admin/foydalanuvchilar"
                  className="text-sm font-medium text-aurora-violet hover:text-aurora-pink"
                >
                  Barchasi
                </a>
              }
            >
              <div className="overflow-x-auto">
                <table className="w-full min-w-[42rem] text-left text-sm">
                  <thead>
                    <tr className="text-xs uppercase tracking-wide text-white/40">
                      <th className="pb-3 font-medium">Nomzod</th>
                      <th className="pb-3 font-medium">Kurs</th>
                      <th className="pb-3 font-medium">Vaqt</th>
                      <th className="pb-3 font-medium">Holat</th>
                      <th className="pb-3 text-right font-medium">Amal</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {applications.map((a) => (
                      <tr key={a.name} className="text-white/80">
                        <td className="py-3 pr-4">
                          <span className="flex items-center gap-2.5">
                            <Avatar
                              initials={a.initials}
                              gradient={a.gradient}
                              size="sm"
                            />
                            <span className="font-medium text-white">{a.name}</span>
                          </span>
                        </td>
                        <td className="py-3 pr-4 text-white/60">{a.course}</td>
                        <td className="py-3 pr-4 text-white/50">{a.time}</td>
                        <td className="py-3 pr-4">
                          <StatusPill label={a.status} tone={toneForStatus(a.status)} />
                        </td>
                        <td className="py-3 text-right">
                          <GlassButton variant="glass" size="sm">
                            Ko'rish
                          </GlassButton>
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
            <PanelCard title="Tezkor statistika">
              <div className="grid grid-cols-2 gap-3">
                {quickStats.map((s) => (
                  <div
                    key={s.label}
                    className="rounded-2xl border border-white/10 bg-white/5 p-4"
                  >
                    <p className="text-2xl font-semibold text-white">{s.value}</p>
                    <p className="mt-1 text-xs text-white/50">{s.label}</p>
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>

          <Reveal delay={0.15}>
            <PanelCard title="Tizim holati">
              <div className="space-y-3">
                {systems.map((s) => (
                  <div
                    key={s.label}
                    className="flex items-center justify-between gap-3"
                  >
                    <span className="text-sm text-white/75">{s.label}</span>
                    <span className="flex items-center gap-2 text-xs font-medium text-emerald-400">
                      <span className="h-2 w-2 rounded-full bg-emerald-400 shadow-[0_0_10px_rgba(52,211,153,0.8)]" />
                      Faol
                    </span>
                  </div>
                ))}
              </div>
            </PanelCard>
          </Reveal>
        </div>
      </div>
    </div>
  );
}
