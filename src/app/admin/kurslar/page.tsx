import type { Metadata } from "next";
import { Plus } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelCard } from "@/components/panel/PanelCard";
import { StatusPill } from "@/components/panel/StatusPill";
import { GlassButton } from "@/components/ui/GlassButton";
import { cn, formatPrice, formatNumber } from "@/lib/utils";
import { courses } from "@/lib/mock/courses";

export const metadata: Metadata = { title: "Kurslar" };

export default function AdminCoursesPage() {
  return (
    <div>
      <PageIntro
        title="Kurslar"
        subtitle="Barcha kurslarni boshqaring"
        action={
          <GlassButton size="md">
            <Plus className="h-4 w-4" /> Yangi kurs
          </GlassButton>
        }
      />

      <PanelCard title="Kurslar ro'yxati">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[48rem] text-left text-sm">
            <thead>
              <tr className="text-xs uppercase tracking-wide text-white/40">
                <th className="pb-3 font-medium">Kurs</th>
                <th className="pb-3 font-medium">Kategoriya</th>
                <th className="pb-3 font-medium">O'quvchi</th>
                <th className="pb-3 font-medium">Narx</th>
                <th className="pb-3 font-medium">Holat</th>
                <th className="pb-3 text-right font-medium">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {courses.map((c) => (
                <tr key={c.slug} className="text-white/80">
                  <td className="py-3 pr-4">
                    <span className="flex items-center gap-2.5">
                      <span
                        className={cn(
                          "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br text-base",
                          c.gradient,
                        )}
                      >
                        {c.emoji}
                      </span>
                      <span className="font-medium text-white">{c.title}</span>
                    </span>
                  </td>
                  <td className="py-3 pr-4 text-white/60">{c.category}</td>
                  <td className="py-3 pr-4">{formatNumber(c.students)}</td>
                  <td className="py-3 pr-4">{formatPrice(c.price)}</td>
                  <td className="py-3 pr-4">
                    <StatusPill
                      label={c.popular ? "Mashhur" : "Faol"}
                      tone={c.popular ? "violet" : "emerald"}
                    />
                  </td>
                  <td className="py-3 text-right">
                    <GlassButton variant="glass" size="sm">
                      Tahrirlash
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
