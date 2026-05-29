import { Hero } from "@/components/sections/Hero";
import { StatsSection } from "@/components/sections/StatsSection";
import { FeaturesSection } from "@/components/sections/FeaturesSection";
import { CoursesPreview } from "@/components/sections/CoursesPreview";
import { StepsSection } from "@/components/sections/StepsSection";
import { TeachersSection } from "@/components/sections/TeachersSection";
import { SuccessStories } from "@/components/sections/SuccessStories";
import { TestimonialsSection } from "@/components/sections/TestimonialsSection";
import { FaqSection } from "@/components/sections/FaqSection";
import { CtaSection } from "@/components/sections/CtaSection";

export default function HomePage() {
  return (
    <>
      <Hero />
      <StatsSection />
      <FeaturesSection />
      <CoursesPreview />
      <StepsSection />
      <TeachersSection />
      <SuccessStories />
      <TestimonialsSection />
      <FaqSection />
      <CtaSection />
    </>
  );
}
