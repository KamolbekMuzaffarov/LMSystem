import type { Metadata } from "next";
import { Check, Sparkles } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { PageHeader } from "@/components/layout/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlassButton } from "@/components/ui/GlassButton";
import { Stagger, StaggerItem, Reveal } from "@/components/ui/Reveal";
import { plans, paymentMethods } from "@/lib/mock/pricing";
import { formatPrice, cn } from "@/lib/utils";

export const metadata: Metadata = { title: "Narxlar" };

export default function PricingPage() {
  return (
    <>
      <PageHeader
        eyebrow="Narxlar va tariflar"
        title={<>Sizga mos <span className="gradient-text">tarifni</span> tanlang</>}
        subtitle="Hammasi bitta obunada. Istalgan vaqtda bekor qilish yoki o'zgartirish mumkin."
      />

      <Container className="pb-10">
        <Stagger className="grid items-stretch gap-6 lg:grid-cols-3">
          {plans.map((p) => (
            <StaggerItem key={p.name} className="h-full">
              <GlassCard
                strong={p.popular}
                glow={p.popular ? "violet" : "none"}
                className={cn(
                  "relative flex h-full flex-col p-7",
                  p.popular && "lg:-translate-y-4 lg:scale-[1.03]",
                )}
              >
                {p.popular && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-gradient-to-br from-aurora-violet to-aurora-pink px-4 py-1 text-xs font-semibold text-white shadow-glow-violet">
                    Eng mashhur
                  </span>
                )}
                <h3 className="text-lg font-semibold text-white">{p.name}</h3>
                <p className="mt-1 text-sm text-white/55">{p.description}</p>
                <div className="mt-5 flex items-end gap-1">
                  <span className="text-3xl font-semibold text-white">{formatPrice(p.price)}</span>
                  <span className="mb-1 text-sm text-white/45">/ {p.period}</span>
                </div>

                <ul className="mt-6 flex-1 space-y-3">
                  {p.features.map((f) => (
                    <li key={f} className="flex items-start gap-2.5 text-sm text-white/70">
                      <span className={cn("mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gradient-to-br", p.gradient)}>
                        <Check className="h-3 w-3 text-white" />
                      </span>
                      {f}
                    </li>
                  ))}
                </ul>

                <div className="mt-7">
                  <GlassButton
                    href="/royxat"
                    variant={p.popular ? "primary" : "glass"}
                    size="lg"
                    className="w-full"
                  >
                    {p.popular && <Sparkles className="h-5 w-5" />} {p.cta}
                  </GlassButton>
                </div>
              </GlassCard>
            </StaggerItem>
          ))}
        </Stagger>

        <Reveal className="mt-12">
          <GlassCard className="flex flex-col items-center gap-5 p-8 text-center">
            <p className="text-sm font-semibold uppercase tracking-wider text-white/40">
              To'lov usullari
            </p>
            <div className="flex flex-wrap items-center justify-center gap-3">
              {paymentMethods.map((m) => (
                <span
                  key={m}
                  className="glass glass-edge rounded-2xl px-5 py-2.5 font-medium text-white/80"
                >
                  {m}
                </span>
              ))}
            </div>
            <p className="max-w-md text-sm text-white/50">
              Barcha to'lovlar shifrlangan va xavfsiz. Bo'lib to'lash bo'yicha menejer bilan
              bog'laning.
            </p>
          </GlassCard>
        </Reveal>
      </Container>
    </>
  );
}
