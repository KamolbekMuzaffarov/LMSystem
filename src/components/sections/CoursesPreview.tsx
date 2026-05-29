import { ArrowRight } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { GlassButton } from "@/components/ui/GlassButton";
import { Stagger, StaggerItem, Reveal } from "@/components/ui/Reveal";
import { CourseCard } from "@/components/cards/CourseCard";
import { courses } from "@/lib/mock/courses";

export function CoursesPreview() {
  const featured = courses.slice(0, 3);
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <div className="flex flex-col items-start justify-between gap-6 sm:flex-row sm:items-end">
          <SectionHeading
            center={false}
            eyebrow="Kurslar"
            title={<>Eng ko'p tanlangan <span className="gradient-text">dasturlar</span></>}
            subtitle="Maqsadingizga mos kursni tanlang va bugundan o'rganishni boshlang."
          />
          <Reveal direction="left">
            <GlassButton href="/kurslar" variant="glass" size="md">
              Barcha kurslar <ArrowRight className="h-4 w-4" />
            </GlassButton>
          </Reveal>
        </div>

        <Stagger className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {featured.map((c) => (
            <StaggerItem key={c.slug} className="h-full">
              <CourseCard course={c} />
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </section>
  );
}
