"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Plus } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Reveal } from "@/components/ui/Reveal";
import { faq } from "@/lib/mock/site";
import { cn } from "@/lib/utils";

export function FaqSection() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section className="py-20 sm:py-28">
      <Container className="max-w-3xl">
        <SectionHeading
          eyebrow="Savol-javob"
          title={<>Tez-tez beriladigan <span className="gradient-text">savollar</span></>}
        />

        <div className="mt-12 flex flex-col gap-3">
          {faq.map((item, i) => {
            const active = open === i;
            return (
              <Reveal key={i} delay={i * 0.04}>
                <GlassCard
                  className={cn(
                    "cursor-pointer overflow-hidden p-0 transition-colors",
                    active && "glass-strong",
                  )}
                >
                  <button
                    onClick={() => setOpen(active ? null : i)}
                    className="flex w-full items-center justify-between gap-4 p-5 text-left"
                  >
                    <span className="text-base font-medium text-white sm:text-lg">
                      {item.q}
                    </span>
                    <span
                      className={cn(
                        "flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white/5 text-white transition-transform duration-300",
                        active && "rotate-45 bg-gradient-to-br from-aurora-violet to-aurora-pink",
                      )}
                    >
                      <Plus className="h-5 w-5" />
                    </span>
                  </button>
                  <AnimatePresence initial={false}>
                    {active && (
                      <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
                      >
                        <p className="px-5 pb-5 text-[15px] leading-relaxed text-white/60">
                          {item.a}
                        </p>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </GlassCard>
              </Reveal>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
