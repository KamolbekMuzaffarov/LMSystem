import { Container } from "@/components/ui/Container";
import { Badge } from "@/components/ui/Badge";
import { Reveal } from "@/components/ui/Reveal";
import type { ReactNode } from "react";

export function PageHeader({
  eyebrow,
  title,
  subtitle,
}: {
  eyebrow?: string;
  title: ReactNode;
  subtitle?: ReactNode;
}) {
  return (
    <section className="relative pb-6 pt-8 sm:pt-12">
      <Container className="flex flex-col items-center text-center">
        {eyebrow && (
          <Reveal>
            <Badge dot>{eyebrow}</Badge>
          </Reveal>
        )}
        <Reveal delay={0.05}>
          <h1 className="mt-6 max-w-4xl text-balance text-5xl font-semibold tracking-tight text-white sm:text-6xl lg:text-7xl">
            {title}
          </h1>
        </Reveal>
        {subtitle && (
          <Reveal delay={0.1}>
            <p className="mx-auto mt-5 max-w-2xl text-pretty text-lg text-white/60">
              {subtitle}
            </p>
          </Reveal>
        )}
      </Container>
    </section>
  );
}
