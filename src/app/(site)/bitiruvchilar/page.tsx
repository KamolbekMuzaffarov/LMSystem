import type { Metadata } from "next";
import { Trophy, Quote } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { PageHeader } from "@/components/layout/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";
import { TiltCard } from "@/components/ui/TiltCard";
import { Avatar } from "@/components/ui/Avatar";
import { AnimatedNumber } from "@/components/ui/AnimatedNumber";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { graduates } from "@/lib/mock/people";

export const metadata: Metadata = { title: "Bitiruvchilar" };

const galleryStats = [
  { value: 8600, suffix: "+", label: "Bitiruvchilar" },
  { value: 92, suffix: "%", label: "Maqsadga erishganlar" },
  { value: 7.5, decimals: 1, label: "O'rtacha IELTS" },
  { value: 340, suffix: "+", label: "Ishga joylashganlar" },
];

export default function GraduatesPage() {
  return (
    <>
      <PageHeader
        eyebrow="Muvaffaqiyat hikoyalari"
        title={<>Ularning <span className="gradient-text">natijalari</span></>}
        subtitle="Minglab o'quvchilar maqsadlariga erishdi — siz ham keyingisi bo'lishingiz mumkin."
      />

      <Container className="pb-10">
        <Stagger className="mb-12 grid grid-cols-2 gap-4 lg:grid-cols-4">
          {galleryStats.map((s) => (
            <StaggerItem key={s.label}>
              <GlassCard className="p-6 text-center">
                <div className="text-3xl font-semibold text-white sm:text-4xl">
                  <AnimatedNumber value={s.value} suffix={s.suffix} decimals={s.decimals} />
                </div>
                <div className="mt-1 text-sm text-white/55">{s.label}</div>
              </GlassCard>
            </StaggerItem>
          ))}
        </Stagger>

        <Stagger className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {graduates.map((g) => (
            <StaggerItem key={g.name} className="h-full">
              <TiltCard className="h-full" intensity={7}>
                <GlassCard sheen className="flex h-full flex-col p-6">
                  <div className="flex items-center justify-between">
                    <Avatar initials={g.initials} gradient={g.gradient} size="md" />
                    <span className="flex items-center gap-1.5 rounded-full bg-gradient-to-br from-emerald-500/30 to-emerald-400/10 px-3 py-1 text-sm font-semibold text-emerald-300">
                      <Trophy className="h-4 w-4" /> {g.result}
                    </span>
                  </div>
                  <h3 className="mt-4 text-lg font-semibold text-white">{g.name}</h3>
                  <p className="text-sm text-white/50">{g.detail} · {g.company}</p>
                  <Quote className="mt-4 h-6 w-6 text-aurora-violet/60" />
                  <p className="mt-2 flex-1 text-sm leading-relaxed text-white/70">“{g.quote}”</p>
                </GlassCard>
              </TiltCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </>
  );
}
