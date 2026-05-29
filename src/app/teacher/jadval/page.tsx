import type { Metadata } from "next";
import { PageIntro } from "@/components/panel/PageIntro";
import { GlassCard } from "@/components/ui/GlassCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: "Jadval" };

type Lesson = { time: string; title: string; room: string; gradient: string };

const L: Record<string, Lesson> = {
  a1: { time: "10:00", title: "IELTS-A1", room: "101-xona", gradient: "from-aurora-violet to-aurora-blue" },
  b2: { time: "14:30", title: "IELTS-B2", room: "Online", gradient: "from-aurora-pink to-aurora-violet" },
  ge: { time: "18:00", title: "GE-Eve", room: "204-xona", gradient: "from-aurora-cyan to-aurora-indigo" },
  kids: { time: "16:00", title: "Kids-Sat", room: "102-xona", gradient: "from-aurora-fuchsia to-aurora-pink" },
};

const week: { day: string; date: string; today?: boolean; lessons: Lesson[] }[] = [
  { day: "Dushanba", date: "25-may", lessons: [L.a1, L.b2, L.ge] },
  { day: "Seshanba", date: "26-may", lessons: [L.a1, L.ge] },
  { day: "Chorshanba", date: "27-may", lessons: [L.a1, L.b2, L.ge] },
  { day: "Payshanba", date: "28-may", lessons: [L.a1, L.ge] },
  { day: "Juma", date: "29-may", today: true, lessons: [L.a1, L.b2, L.ge] },
  { day: "Shanba", date: "30-may", lessons: [L.kids] },
];

export default function TeacherSchedulePage() {
  return (
    <div>
      <PageIntro title="Jadval" subtitle="Haftalik dars jadvalingiz" />

      <Stagger className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {week.map((d) => (
          <StaggerItem key={d.day} className="h-full">
            <GlassCard
              glow={d.today ? "violet" : "none"}
              className={cn(
                "flex h-full flex-col p-5",
                d.today && "ring-1 ring-inset ring-aurora-violet/40",
              )}
            >
              <div className="mb-4 flex items-baseline justify-between">
                <h3 className="font-semibold text-white">{d.day}</h3>
                <span className="text-xs text-white/45">{d.date}</span>
              </div>

              {d.today && (
                <span className="mb-3 inline-flex w-fit rounded-full bg-aurora-violet/20 px-2.5 py-1 text-xs font-medium text-violet-200 ring-1 ring-inset ring-aurora-violet/40">
                  Bugun
                </span>
              )}

              <div className="space-y-3">
                {d.lessons.map((l, i) => (
                  <div key={i} className="flex items-stretch gap-3">
                    <span className="w-11 shrink-0 pt-0.5 text-sm font-semibold text-white/90">
                      {l.time}
                    </span>
                    <span
                      className={cn(
                        "w-1 shrink-0 rounded-full bg-gradient-to-b",
                        l.gradient,
                      )}
                    />
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-white">{l.title}</p>
                      <p className="text-xs text-white/45">{l.room}</p>
                    </div>
                  </div>
                ))}
              </div>
            </GlassCard>
          </StaggerItem>
        ))}
      </Stagger>
    </div>
  );
}
