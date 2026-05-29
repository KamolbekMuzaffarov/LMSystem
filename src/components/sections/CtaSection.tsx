import { ArrowRight, Sparkles } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { Reveal } from "@/components/ui/Reveal";

export function CtaSection() {
  return (
    <section className="py-12">
      <Container>
        <Reveal>
          <GlassCard
            strong
            glow="violet"
            className="relative overflow-hidden px-8 py-16 text-center sm:px-12 sm:py-20"
          >
            {/* inner aurora wash */}
            <div className="pointer-events-none absolute inset-0">
              <div className="absolute -left-1/4 top-0 h-72 w-72 rounded-full bg-aurora-violet/40 blur-3xl" />
              <div className="absolute -right-1/4 bottom-0 h-72 w-72 rounded-full bg-aurora-pink/35 blur-3xl" />
            </div>

            <div className="relative z-10 mx-auto max-w-2xl">
              <span className="mx-auto mb-6 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
                <Sparkles className="h-7 w-7 text-white" />
              </span>
              <h2 className="text-balance text-4xl font-semibold tracking-tight text-white sm:text-6xl">
                Bugun boshlang —{" "}
                <span className="gradient-text">ertaga kech bo'ladi</span>
              </h2>
              <p className="mx-auto mt-5 max-w-lg text-lg text-white/65">
                Bepul demo dars va sinov testidan o'ting. Hech qanday majburiyatsiz.
              </p>
              <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
                <GlassButton href="/royxat" size="lg">
                  Bepul ro'yxatdan o'tish <ArrowRight className="h-5 w-5" />
                </GlassButton>
                <GlassButton href="/aloqa" variant="glass" size="lg">
                  Biz bilan bog'lanish
                </GlassButton>
              </div>
            </div>
          </GlassCard>
        </Reveal>
      </Container>
    </section>
  );
}
