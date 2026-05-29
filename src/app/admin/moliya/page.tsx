import type { Metadata } from "next";
import { Download, TrendingUp, TrendingDown, Wallet } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { BarChart } from "@/components/panel/BarChart";
import { StatusPill, toneForStatus } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { cn } from "@/lib/utils";
import { revenueData } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Moliya" };

const fin = [
  { icon: TrendingUp, label: "Oylik daromad", value: "1.24 mlrd", gradient: "from-aurora-cyan to-aurora-blue" },
  { icon: TrendingDown, label: "Xarajatlar", value: "480 mln", gradient: "from-aurora-pink to-aurora-fuchsia" },
  { icon: Wallet, label: "Sof foyda", value: "760 mln", gradient: "from-aurora-violet to-aurora-indigo" },
];

const tx = [
  { date: "28-may", student: "Kamolbek Muzaffarov", course: "IELTS Intensive", amount: "1 290 000", method: "Payme", status: "To'langan" },
  { date: "28-may", student: "Doston Kamolov", course: "Frontend — React", amount: "990 000", method: "Click", status: "To'langan" },
  { date: "27-may", student: "Malika Yusupova", course: "UI/UX Dizayn", amount: "1 190 000", method: "Uzum Bank", status: "Kutilmoqda" },
  { date: "27-may", student: "Akmal To'rayev", course: "DTM Matematika", amount: "690 000", method: "Naqd", status: "To'langan" },
  { date: "26-may", student: "Sevinch Abdullayeva", course: "IELTS Intensive", amount: "1 290 000", method: "Payme", status: "To'langan" },
];

export default function AdminFinancePage() {
  return (
    <div>
      <PageIntro
        title="Moliya"
        subtitle="Daromad, xarajat va tranzaksiyalar"
        action={
          <GlassButton size="md">
            <Download className="h-4 w-4" /> Eksport
          </GlassButton>
        }
      />

      <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-3">
        {fin.map((f) => {
          const Icon = f.icon;
          return (
            <GlassCard key={f.label} sheen className="p-5">
              <div
                className={cn(
                  "mb-4 flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br text-white shadow-glass",
                  f.gradient,
                )}
              >
                <Icon className="h-5 w-5" />
              </div>
              <p className="text-2xl font-semibold tracking-tight text-white sm:text-3xl">
                {f.value}
              </p>
              <p className="mt-1 text-sm text-white/55">{f.label}</p>
            </GlassCard>
          );
        })}
      </div>

      <div className="mb-5">
        <PanelCard title="Daromad dinamikasi" subtitle="Oxirgi 6 oy (mln so'm)">
          <BarChart data={revenueData} />
        </PanelCard>
      </div>

      <PanelCard title="So'nggi tranzaksiyalar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[48rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Sana</th>
                <th className="pb-3 font-medium">O'quvchi</th>
                <th className="pb-3 font-medium">Kurs</th>
                <th className="pb-3 font-medium">Summa</th>
                <th className="pb-3 font-medium">Usul</th>
                <th className="pb-3 text-right font-medium">Holat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {tx.map((t, i) => (
                <tr key={i} className="text-white/80">
                  <td className="py-3 pr-4 text-white/60">{t.date}</td>
                  <td className="py-3 pr-4 font-medium text-white">{t.student}</td>
                  <td className="py-3 pr-4 text-white/60">{t.course}</td>
                  <td className="py-3 pr-4">{t.amount} so'm</td>
                  <td className="py-3 pr-4 text-white/60">{t.method}</td>
                  <td className="py-3 text-right">
                    <StatusPill label={t.status} tone={toneForStatus(t.status)} />
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
