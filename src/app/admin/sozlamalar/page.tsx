import type { Metadata } from "next";
import type { InputHTMLAttributes } from "react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { site } from "@/lib/mock/site";

export const metadata: Metadata = { title: "Sozlamalar" };

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

function Toggle({ label, defaultChecked }: { label: string; defaultChecked?: boolean }) {
  return (
    <label className="flex cursor-pointer items-center justify-between gap-4 py-2">
      <span className="text-sm text-white/75">{label}</span>
      <span className="relative inline-flex h-6 w-11 shrink-0">
        <input type="checkbox" defaultChecked={defaultChecked} className="peer sr-only" />
        <span className="h-6 w-11 rounded-full bg-white/15 transition-colors peer-checked:bg-aurora-violet" />
        <span className="absolute left-0.5 top-0.5 h-5 w-5 rounded-full bg-white transition-transform duration-300 peer-checked:translate-x-5" />
      </span>
    </label>
  );
}

export default function AdminSettingsPage() {
  return (
    <div>
      <PageIntro title="Sozlamalar" subtitle="Markaz va tizim sozlamalari" />

      <div className="grid gap-5 lg:grid-cols-2">
        <PanelCard title="Umumiy sozlamalar">
          <div className="grid gap-4">
            <Field label="Markaz nomi" defaultValue={site.name} />
            <Field label="Telefon" defaultValue={site.phone} />
            <Field label="Email" type="email" defaultValue={site.email} />
            <Field label="Manzil" defaultValue={site.address} />
          </div>
          <div className="mt-5">
            <GlassButton size="md">Saqlash</GlassButton>
          </div>
        </PanelCard>

        <div className="space-y-5">
          <PanelCard title="Bildirishnomalar">
            <div className="divide-y divide-white/5">
              <Toggle label="Email bildirishnomalar" defaultChecked />
              <Toggle label="SMS eslatmalar" defaultChecked />
              <Toggle label="Telegram bot xabarlari" defaultChecked />
              <Toggle label="Push bildirishnomalar (PWA)" />
            </div>
          </PanelCard>

          <PanelCard title="Integratsiyalar">
            <div className="divide-y divide-white/5">
              <Toggle label="Payme / Click to'lovlari" defaultChecked />
              <Toggle label="Zoom jonli darslar" defaultChecked />
              <Toggle label="Google Calendar sinxronizatsiyasi" />
            </div>
          </PanelCard>
        </div>
      </div>
    </div>
  );
}
