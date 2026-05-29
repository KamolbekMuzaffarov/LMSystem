import { Star, Users } from "lucide-react";
import { TiltCard } from "@/components/ui/TiltCard";
import { GlassCard } from "@/components/ui/GlassCard";
import { Avatar } from "@/components/ui/Avatar";
import type { Teacher } from "@/lib/mock/people";
import { formatNumber } from "@/lib/utils";

export function TeacherCard({ teacher }: { teacher: Teacher }) {
  return (
    <TiltCard className="h-full" intensity={8}>
      <GlassCard sheen className="group flex h-full flex-col items-center p-6 text-center">
        <Avatar
          initials={teacher.initials}
          gradient={teacher.gradient}
          size="lg"
          className="transition-transform duration-500 group-hover:scale-105"
        />
        <h3 className="mt-4 text-lg font-semibold text-white">{teacher.name}</h3>
        <p className="mt-1 text-sm text-white/55">{teacher.role}</p>

        <div className="mt-3 flex items-center gap-4 text-xs text-white/60">
          <span className="flex items-center gap-1">
            <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
            {teacher.rating}
          </span>
          <span className="flex items-center gap-1">
            <Users className="h-3.5 w-3.5" /> {formatNumber(teacher.students)}
          </span>
          <span>{teacher.experience}</span>
        </div>

        <div className="mt-4 flex flex-wrap justify-center gap-2">
          {teacher.badges.map((b) => (
            <span
              key={b}
              className="glass rounded-full px-2.5 py-1 text-xs font-medium text-white/70"
            >
              {b}
            </span>
          ))}
        </div>
      </GlassCard>
    </TiltCard>
  );
}
