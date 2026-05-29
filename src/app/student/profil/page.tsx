import type { Metadata } from "next";
import type { InputHTMLAttributes } from "react";
import { Camera } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Avatar } from "@/components/ui/Avatar";

export const metadata: Metadata = { title: "Profil" };

const fieldCls =
  "h-12 w-full rounded-2xl border border-white/10 bg-white/5 px-4 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10";

function Field({
  label,
  ...props
}: { label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-sm text-white/60">{label}</span>
      <input className={fieldCls} {...props} />
    </label>
  );
}

export default function StudentProfilePage() {
  return (
    <div>
      <PageIntro title="Profil" subtitle="Shaxsiy ma'lumotlaringizni boshqaring" />

      <div className="grid gap-5 lg:grid-cols-3">
        {/* Identity card */}
        <GlassCard className="flex flex-col items-center p-6 text-center">
          <Avatar initials="KM" gradient="from-aurora-violet to-aurora-blue" size="xl" />
          <h2 className="mt-4 text-lg font-semibold text-white">Kamolbek Muzaffarov</h2>
          <p className="text-sm text-white/50">O'quvchi · Level 7</p>

          <div className="mt-5 grid w-full grid-cols-2 gap-3">
            <div className="rounded-2xl border border-white/10 bg-white/5 p-3">
              <p className="text-lg font-semibold text-white">2 340</p>
              <p className="text-xs text-white/45">XP ballar</p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-3">
              <p className="text-lg font-semibold text-white">3</p>
              <p className="text-xs text-white/45">Faol kurs</p>
            </div>
          </div>

          <GlassButton variant="glass" size="sm" className="mt-5">
            <Camera className="h-4 w-4" /> Rasmni o'zgartirish
          </GlassButton>
        </GlassCard>

        {/* Forms */}
        <div className="space-y-5 lg:col-span-2">
          <PanelCard title="Shaxsiy ma'lumotlar">
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="To'liq ism" defaultValue="Kamolbek Muzaffarov" />
              <Field label="Telefon" defaultValue="+998 90 123 45 67" />
              <Field label="Email" type="email" defaultValue="kamolbek@aurora.uz" />
              <Field label="Tug'ilgan sana" defaultValue="2004-03-15" />
              <label className="block sm:col-span-2">
                <span className="mb-1.5 block text-sm text-white/60">Manzil</span>
                <input
                  className={fieldCls}
                  defaultValue="Toshkent sh., Chilonzor tumani"
                />
              </label>
            </div>
            <div className="mt-5">
              <GlassButton size="md">Saqlash</GlassButton>
            </div>
          </PanelCard>

          <PanelCard title="Parolni o'zgartirish">
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Joriy parol" type="password" placeholder="••••••••" />
              <Field label="Yangi parol" type="password" placeholder="••••••••" />
            </div>
            <div className="mt-5">
              <GlassButton variant="glass" size="md">
                Parolni yangilash
              </GlassButton>
            </div>
          </PanelCard>
        </div>
      </div>
    </div>
  );
}
