"use client";

import { motion } from "framer-motion";
import { ArrowRight, PlayCircle, Star, Sparkles, Flame, Trophy } from "lucide-react";
import { GlassButton } from "@/components/ui/GlassButton";
import { GlassCard } from "@/components/ui/GlassCard";
import { Badge } from "@/components/ui/Badge";
import { Container } from "@/components/ui/Container";

const ease = [0.22, 1, 0.36, 1] as const;
const up = {
  hidden: { opacity: 0, y: 28, filter: "blur(10px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)" },
};

export function Hero() {
  return (
    <section className="relative overflow-hidden pb-20 pt-10 sm:pt-16">
      <Container>
        <motion.div
          initial="hidden"
          animate="show"
          transition={{ staggerChildren: 0.12 }}
          className="relative z-10 mx-auto flex max-w-4xl flex-col items-center text-center"
        >
          <motion.div variants={up} transition={{ duration: 0.7, ease }}>
            <Badge dot>
              <Sparkles className="h-3.5 w-3.5 text-aurora-violet" />
              Yangi: AI yozma ish tekshiruvi ishga tushdi
            </Badge>
          </motion.div>

          <motion.h1
            variants={up}
            transition={{ duration: 0.8, ease }}
            className="mt-7 text-balance text-5xl font-semibold leading-[0.95] tracking-tight text-white sm:text-7xl lg:text-[7.5rem]"
          >
            Bilimga{" "}
            <span className="gradient-text-violet">yangicha</span> qarash
          </motion.h1>

          <motion.p
            variants={up}
            transition={{ duration: 0.8, ease }}
            className="mt-6 max-w-xl text-pretty text-lg text-white/60 sm:text-xl"
          >
            IELTS, ingliz tili, dasturlash va dizayn — jonli darslar, AI
            yordamchi va sertifikat bilan. O'rganishni tajribaga aylantiramiz.
          </motion.p>

          <motion.div
            variants={up}
            transition={{ duration: 0.8, ease }}
            className="mt-9 flex flex-col items-center gap-3 sm:flex-row"
          >
            <GlassButton href="/royxat" size="lg">
              Bepul boshlash <ArrowRight className="h-5 w-5" />
            </GlassButton>
            <GlassButton href="/kurslar" variant="glass" size="lg">
              <PlayCircle className="h-5 w-5" /> Kurslarni ko'rish
            </GlassButton>
          </motion.div>

          <motion.div
            variants={up}
            transition={{ duration: 0.8, ease }}
            className="mt-10 flex items-center gap-4 text-sm text-white/55"
          >
            <div className="flex -space-x-3">
              {["from-aurora-violet to-aurora-pink", "from-aurora-cyan to-aurora-blue", "from-aurora-fuchsia to-aurora-violet", "from-aurora-blue to-aurora-indigo"].map(
                (g, i) => (
                  <span
                    key={i}
                    className={`h-9 w-9 rounded-full border-2 border-ink bg-gradient-to-br ${g}`}
                  />
                ),
              )}
            </div>
            <div className="text-left">
              <div className="flex items-center gap-1 text-amber-400">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Star key={i} className="h-3.5 w-3.5 fill-amber-400" />
                ))}
              </div>
              <span className="text-white/55">12 000+ o'quvchi bizni tanladi</span>
            </div>
          </motion.div>
        </motion.div>

        {/* Layer 3: floating spatial glass chips */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.8, duration: 1, ease }}
          className="pointer-events-none absolute left-[6%] top-[18%] hidden xl:block"
        >
          <div className="animate-float">
            <GlassCard strong className="flex items-center gap-3 px-4 py-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-aurora-violet to-aurora-pink">
                <Trophy className="h-5 w-5 text-white" />
              </span>
              <div className="text-left">
                <div className="text-sm font-semibold text-white">IELTS 8.0</div>
                <div className="text-xs text-white/50">Kamolbek M.</div>
              </div>
            </GlassCard>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 1, duration: 1, ease }}
          className="pointer-events-none absolute right-[7%] top-[26%] hidden xl:block"
        >
          <div className="animate-float [animation-delay:-3s]">
            <GlassCard strong className="flex items-center gap-3 px-4 py-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-orange-400 to-aurora-pink">
                <Flame className="h-5 w-5 text-white" />
              </span>
              <div className="text-left">
                <div className="text-sm font-semibold text-white">12 kunlik streak</div>
                <div className="text-xs text-white/50">Davom eting! 🔥</div>
              </div>
            </GlassCard>
          </div>
        </motion.div>
      </Container>
    </section>
  );
}
