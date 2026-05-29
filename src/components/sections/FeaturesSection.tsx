import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { TiltCard } from "@/components/ui/TiltCard";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { features } from "@/lib/mock/site";
import { cn } from "@/lib/utils";

export function FeaturesSection() {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <SectionHeading
          eyebrow="Nega aynan biz"
          title={<>Bir platforma — <span className="gradient-text">cheksiz imkoniyat</span></>}
          subtitle="Zamonaviy o'quv tajribasi uchun kerak bo'lgan hamma narsa bir joyda jamlangan."
        />

        <Stagger className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <StaggerItem key={f.title}>
              <TiltCard className="h-full" intensity={7}>
                <GlassCard sheen className="group h-full p-7">
                  <span
                    className={cn(
                      "mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br text-white shadow-glass transition-transform duration-500 group-hover:scale-110",
                      f.gradient,
                    )}
                  >
                    <f.icon className="h-7 w-7" />
                  </span>
                  <h3 className="text-xl font-semibold text-white">{f.title}</h3>
                  <p className="mt-2 text-[15px] leading-relaxed text-white/55">
                    {f.text}
                  </p>
                </GlassCard>
              </TiltCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
