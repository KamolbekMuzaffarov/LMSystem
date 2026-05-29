import type { Metadata } from "next";
import { Play, FileText } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { ProgressBar } from "@/components/panel/ProgressBar";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { cn } from "@/lib/utils";
import { studentCourses } from "@/lib/mock/panel";

export const metadata: Metadata = { title: "Kurslarim" };

const courses = studentCourses.map((c, i) => ({
  ...c,
  teacher: ["Dilnoza Karimova", "Javohir Tursunov", "Sardor Aliyev"][i],
  lessonsDone: [34, 18, 7][i],
  lessonsTotal: [50, 44, 30][i],
}));

export default function StudentCoursesPage() {
  return (
    <div>
      <PageIntro
        title="Kurslarim"
        subtitle="Siz yozilgan barcha kurslar va ularning holati"
      />

      <Stagger className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
        {courses.map((c) => (
          <StaggerItem key={c.title} className="h-full">
            <GlassCard sheen className="flex h-full flex-col overflow-hidden">
              <div
                className={cn(
                  "relative flex h-28 items-end bg-gradient-to-br p-4",
                  c.gradient,
                )}
              >
                <span className="absolute right-4 top-3 text-4xl opacity-90">
                  {c.emoji}
                </span>
              </div>
              <div className="flex flex-1 flex-col p-5">
                <h3 className="font-semibold tracking-tight text-white">{c.title}</h3>
                <p className="text-xs text-white/45">{c.teacher}</p>

                <div className="mt-4 flex items-center justify-between text-sm">
                  <span className="text-white/60">
                    {c.lessonsDone}/{c.lessonsTotal} dars
                  </span>
                  <span className="font-semibold text-white">{c.progress}%</span>
                </div>
                <ProgressBar value={c.progress} gradient={c.gradient} className="mt-2" />

                <p className="mt-3 text-xs text-white/45">Keyingi: {c.nextLesson}</p>

                <div className="mt-5 flex gap-2 pt-1">
                  <GlassButton size="sm" className="flex-1">
                    <Play className="h-4 w-4" /> Davom etish
                  </GlassButton>
                  <GlassButton variant="glass" size="sm">
                    <FileText className="h-4 w-4" />
                    <span className="sr-only">Materiallar</span>
                  </GlassButton>
                </div>
              </div>
            </GlassCard>
          </StaggerItem>
        ))}
      </Stagger>
    </div>
  );
}
