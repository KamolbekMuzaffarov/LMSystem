import { Quote, TrendingUp } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { TiltCard } from "@/components/ui/TiltCard";
import { Avatar } from "@/components/ui/Avatar";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { graduates } from "@/lib/mock/people";

export function SuccessStories() {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <SectionHeading
          eyebrow="Bitiruvchilar"
          title={<>Natijalar o'zi <span className="gradient-text">gapiradi</span></>}
          subtitle="Minglab o'quvchilar maqsadlariga erishdi. Mana ulardan ba'zilari."
        />

        <Stagger className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {graduates.map((g) => (
            <StaggerItem key={g.name} className="h-full">
              <TiltCard className="h-full" intensity={6}>
                <GlassCard sheen className="flex h-full flex-col p-6">
                  <Quote className="h-7 w-7 text-aurora-violet/70" />
                  <p className="mt-3 flex-1 text-[15px] leading-relaxed text-white/75">
                    “{g.quote}”
                  </p>
                  <div className="mt-5 flex items-center gap-3 border-t border-white/10 pt-4">
                    <Avatar initials={g.initials} gradient={g.gradient} size="md" />
                    <div className="flex-1">
                      <div className="text-sm font-semibold text-white">{g.name}</div>
                      <div className="text-xs text-white/50">{g.company}</div>
                    </div>
                    <div className="text-right">
                      <div className="flex items-center gap-1 text-sm font-semibold text-emerald-300">
                        <TrendingUp className="h-4 w-4" /> {g.result}
                      </div>
                      <div className="text-xs text-white/45">{g.detail}</div>
                    </div>
                  </div>
                </GlassCard>
              </TiltCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
