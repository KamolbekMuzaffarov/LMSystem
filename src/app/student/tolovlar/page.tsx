import type { Metadata } from "next";
import { CreditCard, CalendarClock, CheckCircle2 } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill, toneForStatus } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { paymentMethods } from "@/lib/mock/pricing";

export const metadata: Metadata = { title: "To'lovlar" };

const history = [
  { date: "01-may 2026", desc: "Pro tarif — May oyi", amount: "1 290 000 so'm", method: "Payme", status: "To'langan" },
  { date: "01-apr 2026", desc: "Pro tarif — Aprel oyi", amount: "1 290 000 so'm", method: "Click", status: "To'langan" },
  { date: "01-mar 2026", desc: "Pro tarif — Mart oyi", amount: "1 290 000 so'm", method: "Uzum Bank", status: "To'langan" },
  { date: "01-fev 2026", desc: "Standart — Fevral oyi", amount: "690 000 so'm", method: "Payme", status: "To'langan" },
];

export default function StudentPaymentsPage() {
  return (
    <div>
      <PageIntro title="To'lovlar" subtitle="Tarif, to'lov usullari va to'lovlar tarixi" />

      <div className="mb-5 grid gap-5 lg:grid-cols-2">
        <GlassCard glow="violet" className="relative overflow-hidden p-6">
          <div className="pointer-events-none absolute -right-10 -top-10 h-44 w-44 rounded-full bg-aurora-violet/30 blur-3xl" />
          <div className="relative">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink text-white shadow-glow-violet">
              <CreditCard className="h-5 w-5" />
            </span>
            <p className="mt-4 text-sm text-white/55">Joriy tarif</p>
            <h3 className="text-2xl font-semibold tracking-tight text-white">Pro</h3>
            <p className="mt-1 text-white/70">
              <span className="text-xl font-semibold text-white">1 290 000</span> so'm / oy
            </p>
            <div className="mt-4 flex items-center gap-2 text-sm text-white/60">
              <CalendarClock className="h-4 w-4 text-aurora-cyan" />
              Keyingi to'lov: 01-iyun 2026
            </div>
            <div className="mt-5 flex gap-2">
              <GlassButton size="md">Hozir to'lash</GlassButton>
              <GlassButton variant="glass" size="md">
                Tarifni o'zgartirish
              </GlassButton>
            </div>
          </div>
        </GlassCard>

        <PanelCard title="Qabul qilinadigan usullar" subtitle="Xavfsiz va shifrlangan to'lovlar">
          <div className="flex flex-wrap gap-2.5">
            {paymentMethods.map((m) => (
              <span
                key={m}
                className="glass glass-edge flex items-center gap-2 rounded-2xl px-4 py-2.5 text-sm font-medium text-white/85"
              >
                <CheckCircle2 className="h-4 w-4 text-emerald-400" />
                {m}
              </span>
            ))}
          </div>
          <p className="mt-4 text-sm leading-relaxed text-white/50">
            To'lovlarni bo'lib to'lash imkoniyati mavjud. Har bir to'lovdan so'ng chek
            avtomatik Telegram orqali yuboriladi.
          </p>
        </PanelCard>
      </div>

      <PanelCard title="To'lovlar tarixi">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[42rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Sana</th>
                <th className="pb-3 font-medium">Tavsif</th>
                <th className="pb-3 font-medium">Summa</th>
                <th className="pb-3 font-medium">Usul</th>
                <th className="pb-3 text-right font-medium">Holat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {history.map((h, i) => (
                <tr key={i} className="text-white/80">
                  <td className="py-3 pr-4 text-white/60">{h.date}</td>
                  <td className="py-3 pr-4 font-medium text-white">{h.desc}</td>
                  <td className="py-3 pr-4">{h.amount}</td>
                  <td className="py-3 pr-4 text-white/60">{h.method}</td>
                  <td className="py-3 text-right">
                    <StatusPill label={h.status} tone={toneForStatus(h.status)} />
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
