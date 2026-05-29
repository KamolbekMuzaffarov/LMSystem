import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedNumber } from "@/components/ui/AnimatedNumber";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { stats } from "@/lib/mock/site";

export function StatsSection() {
  return (
    <section className="py-12">
      <Container>
        <Stagger className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          {stats.map((s) => (
            <StaggerItem key={s.label}>
              <GlassCard className="flex h-full flex-col items-center justify-center p-6 text-center sm:p-8">
                <span className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-white/5 text-aurora-violet">
                  <s.icon className="h-6 w-6" />
                </span>
                <div className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">
                  <AnimatedNumber
                    value={s.value}
                    suffix={s.suffix}
                    decimals={s.decimals}
                  />
                </div>
                <div className="mt-1 text-sm text-white/55">{s.label}</div>
              </GlassCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
