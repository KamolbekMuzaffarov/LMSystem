import { ArrowRight } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { GlassButton } from "@/components/ui/GlassButton";
import { Stagger, StaggerItem, Reveal } from "@/components/ui/Reveal";
import { TeacherCard } from "@/components/cards/TeacherCard";
import { teachers } from "@/lib/mock/people";

export function TeachersSection() {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <SectionHeading
          eyebrow="Jamoa"
          title={<>Tajribali <span className="gradient-text">o'qituvchilar</span></>}
          subtitle="Har biri o'z sohasining ustasi — sertifikatlangan va natijaga yo'naltirilgan."
        />

        <Stagger className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {teachers.map((t) => (
            <StaggerItem key={t.slug} className="h-full">
              <TeacherCard teacher={t} />
            </StaggerItem>
          ))}
        </Stagger>

        <Reveal className="mt-10 flex justify-center">
          <GlassButton href="/oqituvchilar" variant="glass" size="md">
            Barcha o'qituvchilar <ArrowRight className="h-4 w-4" />
          </GlassButton>
        </Reveal>
      </Container>
    </section>
  );
}
