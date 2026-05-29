import { Star } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { Avatar } from "@/components/ui/Avatar";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { testimonials } from "@/lib/mock/people";

export function TestimonialsSection() {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <SectionHeading
          eyebrow="Sharhlar"
          title={<>Foydalanuvchilar <span className="gradient-text">nima deydi</span></>}
        />

        <Stagger className="mt-14 grid gap-5 md:grid-cols-2">
          {testimonials.map((t) => (
            <StaggerItem key={t.name}>
              <GlassCard className="flex h-full flex-col p-7">
                <div className="flex items-center gap-1 text-amber-400">
                  {Array.from({ length: t.rating }).map((_, i) => (
                    <Star key={i} className="h-4 w-4 fill-amber-400" />
                  ))}
                </div>
                <p className="mt-4 flex-1 text-lg leading-relaxed text-white/80">
                  “{t.text}”
                </p>
                <div className="mt-6 flex items-center gap-3">
                  <Avatar initials={t.initials} gradient={t.gradient} size="md" />
                  <div>
                    <div className="text-sm font-semibold text-white">{t.name}</div>
                    <div className="text-xs text-white/50">{t.role}</div>
                  </div>
                </div>
              </GlassCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
