import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ArrowLeft,
  Star,
  Clock,
  Users,
  PlayCircle,
  CheckCircle2,
  BookOpen,
  Award,
  Sparkles,
} from "lucide-react";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { Avatar } from "@/components/ui/Avatar";
import { Reveal } from "@/components/ui/Reveal";
import { courses, getCourse } from "@/lib/mock/courses";
import { getTeacher } from "@/lib/mock/people";
import { formatPrice, formatNumber, cn } from "@/lib/utils";

export function generateStaticParams() {
  return courses.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const course = getCourse(slug);
  return { title: course ? course.title : "Kurs" };
}

export default async function CourseDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const course = getCourse(slug);
  if (!course) notFound();
  const teacher = getTeacher(course.teacherSlug);

  return (
    <Container className="pb-10">
      <Reveal>
        <Link
          href="/kurslar"
          className="mb-6 inline-flex items-center gap-2 text-sm text-white/60 transition-colors hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" /> Barcha kurslar
        </Link>
      </Reveal>

      {/* banner */}
      <Reveal>
        <GlassCard strong className="relative mb-8 overflow-hidden p-0">
          <div className={cn("relative h-52 bg-gradient-to-br sm:h-64", course.gradient)}>
            <div className="absolute inset-0 bg-[radial-gradient(120%_120%_at_50%_0%,rgba(255,255,255,0.25),transparent_55%)]" />
            <span className="absolute right-8 top-1/2 -translate-y-1/2 text-8xl opacity-90 drop-shadow-2xl sm:text-9xl">
              {course.emoji}
            </span>
            <div className="absolute bottom-0 left-0 right-0 p-6 sm:p-8">
              <div className="flex flex-wrap gap-2">
                <span className="glass-strong rounded-full px-3 py-1 text-xs font-medium text-white">
                  {course.category}
                </span>
                <span className="glass-strong rounded-full px-3 py-1 text-xs font-medium text-white">
                  {course.level}
                </span>
              </div>
              <h1 className="mt-3 max-w-2xl text-3xl font-semibold tracking-tight text-white sm:text-4xl">
                {course.title}
              </h1>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-x-6 gap-y-3 px-6 py-4 text-sm text-white/70 sm:px-8">
            <span className="flex items-center gap-1.5">
              <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
              {course.rating} ({course.reviews} sharh)
            </span>
            <span className="flex items-center gap-1.5">
              <Users className="h-4 w-4" /> {formatNumber(course.students)} o'quvchi
            </span>
            <span className="flex items-center gap-1.5">
              <Clock className="h-4 w-4" /> {course.durationWeeks} hafta
            </span>
            <span className="flex items-center gap-1.5">
              <BookOpen className="h-4 w-4" /> {course.lessonsCount} dars
            </span>
          </div>
        </GlassCard>
      </Reveal>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* main */}
        <div className="space-y-8 lg:col-span-2">
          <Reveal>
            <GlassCard className="p-6 sm:p-8">
              <h2 className="text-xl font-semibold text-white">Kurs haqida</h2>
              <p className="mt-3 leading-relaxed text-white/65">{course.description}</p>

              <h3 className="mt-7 text-lg font-semibold text-white">Nimalarga ega bo'lasiz</h3>
              <ul className="mt-4 grid gap-3 sm:grid-cols-2">
                {course.highlights.map((h) => (
                  <li key={h} className="flex items-start gap-2.5 text-sm text-white/70">
                    <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-aurora-violet" />
                    {h}
                  </li>
                ))}
              </ul>
            </GlassCard>
          </Reveal>

          <Reveal>
            <GlassCard className="p-6 sm:p-8">
              <h2 className="text-xl font-semibold text-white">Dastur (silabus)</h2>
              <div className="mt-5 space-y-3">
                {course.modules.map((m, i) => (
                  <div key={m.title} className="rounded-2xl border border-white/10 bg-white/5 p-5">
                    <div className="flex items-center gap-3">
                      <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-aurora-violet to-aurora-indigo text-sm font-semibold text-white">
                        {i + 1}
                      </span>
                      <h4 className="font-semibold text-white">{m.title}</h4>
                    </div>
                    <ul className="mt-3 grid gap-2 pl-12 sm:grid-cols-2">
                      {m.lessons.map((l) => (
                        <li key={l} className="flex items-center gap-2 text-sm text-white/60">
                          <PlayCircle className="h-4 w-4 text-white/40" /> {l}
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            </GlassCard>
          </Reveal>
        </div>

        {/* sidebar */}
        <div className="lg:col-span-1">
          <div className="sticky top-28 space-y-6">
            <Reveal direction="left">
              <GlassCard strong glow="violet" className="p-6">
                <div className="flex items-end gap-2">
                  <span className="text-3xl font-semibold text-white">
                    {formatPrice(course.price)}
                  </span>
                  {course.oldPrice && (
                    <span className="mb-1 text-sm text-white/40 line-through">
                      {formatPrice(course.oldPrice)}
                    </span>
                  )}
                </div>
                <p className="mt-1 text-sm text-white/50">Bo'lib to'lash imkoniyati mavjud</p>

                <div className="mt-5 flex flex-col gap-3">
                  <GlassButton href="/royxat" size="lg" className="w-full">
                    <Sparkles className="h-5 w-5" /> Kursga yozilish
                  </GlassButton>
                  <GlassButton href="/royxat" variant="glass" size="lg" className="w-full">
                    <PlayCircle className="h-5 w-5" /> Bepul demo dars
                  </GlassButton>
                </div>

                <ul className="mt-6 space-y-3 border-t border-white/10 pt-5 text-sm text-white/65">
                  <li className="flex items-center gap-2.5">
                    <Award className="h-4 w-4 text-aurora-violet" /> Tugatgach sertifikat
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Clock className="h-4 w-4 text-aurora-violet" /> Umrbod kirish huquqi
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Users className="h-4 w-4 text-aurora-violet" /> Jonli mentor qo'llab-quvvati
                  </li>
                </ul>
              </GlassCard>
            </Reveal>

            {teacher && (
              <Reveal direction="left">
                <GlassCard className="p-6">
                  <h3 className="text-sm font-semibold uppercase tracking-wider text-white/40">
                    O'qituvchi
                  </h3>
                  <div className="mt-4 flex items-center gap-4">
                    <Avatar initials={teacher.initials} gradient={teacher.gradient} size="md" />
                    <div>
                      <Link
                        href="/oqituvchilar"
                        className="font-semibold text-white hover:text-aurora-violet"
                      >
                        {teacher.name}
                      </Link>
                      <p className="text-xs text-white/50">{teacher.role}</p>
                    </div>
                  </div>
                  <p className="mt-4 text-sm text-white/60">{teacher.bio}</p>
                </GlassCard>
              </Reveal>
            )}
          </div>
        </div>
      </div>
    </Container>
  );
}
