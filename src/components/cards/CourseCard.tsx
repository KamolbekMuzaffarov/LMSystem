import Link from "next/link";
import { Star, Clock, Users, ArrowUpRight } from "lucide-react";
import { TiltCard } from "@/components/ui/TiltCard";
import { GlassCard } from "@/components/ui/GlassCard";
import { formatPrice, formatNumber, cn } from "@/lib/utils";
import type { Course } from "@/lib/mock/courses";

export function CourseCard({ course }: { course: Course }) {
  return (
    <TiltCard className="h-full">
      <Link href={`/kurslar/${course.slug}`} className="block h-full">
        <GlassCard
          sheen
          className="group flex h-full flex-col overflow-hidden p-0 transition-shadow duration-500 hover:shadow-glass-lg"
        >
          {/* cover */}
          <div
            className={cn(
              "relative flex h-40 items-center justify-center overflow-hidden bg-gradient-to-br",
              course.gradient,
            )}
          >
            <span className="text-6xl drop-shadow-lg transition-transform duration-500 group-hover:scale-110">
              {course.emoji}
            </span>
            <div className="absolute inset-0 bg-[radial-gradient(120%_100%_at_50%_0%,rgba(255,255,255,0.25),transparent_60%)]" />
            <div className="absolute left-3 top-3 flex gap-2">
              <span className="glass rounded-full px-2.5 py-1 text-xs font-medium text-white">
                {course.category}
              </span>
            </div>
            {course.popular && (
              <span className="absolute right-3 top-3 rounded-full bg-white/90 px-2.5 py-1 text-xs font-semibold text-ink">
                Mashhur
              </span>
            )}
          </div>

          {/* body */}
          <div className="flex flex-1 flex-col p-5">
            <div className="flex items-center gap-3 text-xs text-white/55">
              <span className="flex items-center gap-1">
                <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                {course.rating}
              </span>
              <span className="flex items-center gap-1">
                <Clock className="h-3.5 w-3.5" /> {course.durationWeeks} hafta
              </span>
              <span className="flex items-center gap-1">
                <Users className="h-3.5 w-3.5" /> {formatNumber(course.students)}
              </span>
            </div>

            <h3 className="mt-3 text-lg font-semibold leading-snug text-white">
              {course.title}
            </h3>
            <p className="mt-2 line-clamp-2 flex-1 text-sm text-white/55">
              {course.short}
            </p>

            <div className="mt-5 flex items-end justify-between">
              <div>
                {course.oldPrice && (
                  <span className="block text-xs text-white/40 line-through">
                    {formatPrice(course.oldPrice)}
                  </span>
                )}
                <span className="text-lg font-semibold text-white">
                  {formatPrice(course.price)}
                </span>
              </div>
              <span className="glass glass-edge flex h-10 w-10 items-center justify-center rounded-full text-white transition-transform duration-300 group-hover:rotate-45">
                <ArrowUpRight className="h-5 w-5" />
              </span>
            </div>
          </div>
        </GlassCard>
      </Link>
    </TiltCard>
  );
}
