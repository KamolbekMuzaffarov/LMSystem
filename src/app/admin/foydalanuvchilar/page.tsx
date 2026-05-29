import type { Metadata } from "next";
import { UserPlus } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill, type Tone } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";

export const metadata: Metadata = { title: "Foydalanuvchilar" };

const users = [
  { name: "Kamolbek Muzaffarov", initials: "KM", gradient: "from-aurora-violet to-aurora-blue", role: "O'quvchi", detail: "IELTS-A1", joined: "12-mar 2026", status: "Faol" },
  { name: "Dilnoza Karimova", initials: "DK", gradient: "from-aurora-pink to-aurora-fuchsia", role: "O'qituvchi", detail: "IELTS", joined: "02-yan 2025", status: "Faol" },
  { name: "Doston Kamolov", initials: "DK", gradient: "from-aurora-cyan to-aurora-blue", role: "O'quvchi", detail: "Frontend", joined: "20-may 2026", status: "Yangi" },
  { name: "Javohir Tursunov", initials: "JT", gradient: "from-aurora-fuchsia to-aurora-violet", role: "O'qituvchi", detail: "General English", joined: "15-sen 2024", status: "Faol" },
  { name: "Sevinch Abdullayeva", initials: "SA", gradient: "from-aurora-violet to-aurora-pink", role: "Tashqi", detail: "Mock test", joined: "28-may 2026", status: "Yangi" },
  { name: "Akmal To'rayev", initials: "AT", gradient: "from-aurora-blue to-aurora-indigo", role: "Ota-ona", detail: "—", joined: "10-fev 2026", status: "Faol" },
  { name: "Admin Aurora", initials: "AA", gradient: "from-aurora-cyan to-aurora-blue", role: "Admin", detail: "—", joined: "01-yan 2024", status: "Faol" },
  { name: "Diyor Mahmudov", initials: "DM", gradient: "from-aurora-indigo to-aurora-cyan", role: "O'quvchi", detail: "IELTS-A1", joined: "18-apr 2026", status: "Nofaol" },
];

const roleTone: Record<string, Tone> = {
  "O'qituvchi": "violet",
  "O'quvchi": "sky",
  Admin: "pink",
  "Ota-ona": "amber",
  Tashqi: "slate",
};

const statusTone: Record<string, Tone> = {
  Faol: "emerald",
  Yangi: "violet",
  Nofaol: "slate",
};

export default function AdminUsersPage() {
  return (
    <div>
      <PageIntro
        title="Foydalanuvchilar"
        subtitle="12 480 o'quvchi · 64 o'qituvchi · 8 admin"
        action={
          <GlassButton size="md">
            <UserPlus className="h-4 w-4" /> Qo'shish
          </GlassButton>
        }
      />

      <PanelCard title="Barcha foydalanuvchilar">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[48rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Foydalanuvchi</th>
                <th className="pb-3 font-medium">Rol</th>
                <th className="pb-3 font-medium">Bog'liqlik</th>
                <th className="pb-3 font-medium">Qo'shilgan</th>
                <th className="pb-3 font-medium">Holat</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {users.map((u, i) => (
                <tr key={i} className="text-white/80">
                  <td className="py-3 pr-4">
                    <span className="flex items-center gap-2.5">
                      <Avatar initials={u.initials} gradient={u.gradient} size="sm" />
                      <span className="font-medium text-white">{u.name}</span>
                    </span>
                  </td>
                  <td className="py-3 pr-4">
                    <StatusPill label={u.role} tone={roleTone[u.role] ?? "slate"} />
                  </td>
                  <td className="py-3 pr-4 text-white/60">{u.detail}</td>
                  <td className="py-3 pr-4 text-white/50">{u.joined}</td>
                  <td className="py-3 pr-4">
                    <StatusPill label={u.status} tone={statusTone[u.status] ?? "slate"} />
                  </td>
                  <td className="py-3 text-right">
                    <GlassButton variant="glass" size="sm">
                      Boshqarish
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
