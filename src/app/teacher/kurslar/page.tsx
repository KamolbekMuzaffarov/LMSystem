import type { Metadata } from "next";
import { Users } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { cn } from "@/lib/utils";
import { teacherGroups } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Kurslarim" };

export default function TeacherGroupsPage() {
  return (
    <div>
      <PageIntro title="Guruhlarim" subtitle="Siz dars beradigan barcha guruhlar" />

      <Stagger className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
        {teacherGroups.map((g) => (
          <StaggerItem key={g.name} className="h-full">
            <GlassCard sheen className="flex h-full flex-col p-5">
              <div className="flex items-center gap-3">
                <span
                  className={cn(
                    "flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br text-white shadow-glass",
                    g.gradient,
                  )}
                >
                  <Users className="h-5 w-5" />
                </span>
                <div className="min-w-0">
                  <h3 className="font-semibold text-white">{g.name}</h3>
                  <p className="truncate text-xs text-white/45">{g.course}</p>
                </div>
              </div>

              <div className="mt-5 grid grid-cols-3 gap-2 text-center">
                <div className="rounded-2xl border border-white/10 bg-white/5 p-3">
                  <p className="text-lg font-semibold text-white">{g.students}</p>
                  <p className="text-[11px] text-white/45">O'quvchi</p>
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-3">
                  <p className="text-lg font-semibold text-white">{g.attendance}%</p>
                  <p className="text-[11px] text-white/45">Davomat</p>
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-3">
                  <p className="text-lg font-semibold text-white">{g.avgScore}</p>
                  <p className="text-[11px] text-white/45">O'rtacha</p>
                </div>
              </div>

              <div className="mt-5 pt-1">
                <GlassButton variant="glass" size="sm" className="w-full">
                  Guruhni ochish
                </GlassButton>
              </div>
            </GlassCard>
          </StaggerItem>
        ))}
      </Stagger>
    </div>
  );
}
