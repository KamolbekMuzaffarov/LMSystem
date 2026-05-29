import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { steps } from "@/lib/mock/site";

export function StepsSection() {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <SectionHeading
          eyebrow="Qanday ishlaydi"
          title={<>4 qadamda <span className="gradient-text">maqsadingizga</span></>}
          subtitle="Ro'yxatdan o'tishdan sertifikatgacha — yo'l oddiy va aniq."
        />

        <Stagger className="mt-14 grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {steps.map((s) => (
            <StaggerItem key={s.number}>
              <GlassCard className="relative h-full overflow-hidden p-7">
                <span className="block bg-gradient-to-br from-white/90 to-white/20 bg-clip-text text-6xl font-bold text-transparent">
                  {s.number}
                </span>
                <h3 className="mt-4 text-lg font-semibold text-white">{s.title}</h3>
                <p className="mt-2 text-sm text-white/55">{s.text}</p>
              </GlassCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
