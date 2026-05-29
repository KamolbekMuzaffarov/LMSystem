"use client";

import { useMemo, useState } from "react";
import { Search, SlidersHorizontal } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { Container } from "@/components/ui/Container";
import { CourseCard } from "@/components/cards/CourseCard";
import { courses, categories, type CourseLevel } from "@/lib/mock/courses";
import { cn } from "@/lib/utils";

const levels: ("Barchasi" | CourseLevel)[] = ["Barchasi", "Boshlang'ich", "O'rta", "Yuqori"];

export function CoursesExplorer() {
  const [cat, setCat] = useState<string>("Barchasi");
  const [level, setLevel] = useState<string>("Barchasi");
  const [q, setQ] = useState("");

  const filtered = useMemo(() => {
    return courses.filter((c) => {
      const okCat = cat === "Barchasi" || c.category === cat;
      const okLevel = level === "Barchasi" || c.level === level;
      const okQ =
        q.trim() === "" ||
        c.title.toLowerCase().includes(q.toLowerCase()) ||
        c.short.toLowerCase().includes(q.toLowerCase());
      return okCat && okLevel && okQ;
    });
  }, [cat, level, q]);

  return (
    <Container className="pb-10">
      {/* controls */}
      <div className="glass glass-edge mb-10 flex flex-col gap-5 rounded-3xl p-5">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Kurs qidirish..."
            className="h-12 w-full rounded-2xl border border-white/10 bg-white/5 pl-12 pr-4 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10"
          />
        </div>

        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex flex-wrap gap-2">
            {categories.map((c) => (
              <Chip key={c} active={cat === c} onClick={() => setCat(c)}>
                {c}
              </Chip>
            ))}
          </div>
          <div className="flex items-center gap-2">
            <SlidersHorizontal className="h-4 w-4 text-white/40" />
            {levels.map((l) => (
              <Chip key={l} active={level === l} onClick={() => setLevel(l)} small>
                {l}
              </Chip>
            ))}
          </div>
        </div>
      </div>

      <div className="mb-6 text-sm text-white/50">
        {filtered.length} ta kurs topildi
      </div>

      {filtered.length === 0 ? (
        <div className="glass rounded-3xl p-16 text-center text-white/60">
          Hech narsa topilmadi. Boshqa filtr tanlab ko'ring.
        </div>
      ) : (
        <motion.div layout className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <AnimatePresence mode="popLayout">
            {filtered.map((c) => (
              <motion.div
                key={c.slug}
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
                className="h-full"
              >
                <CourseCard course={c} />
              </motion.div>
            ))}
          </AnimatePresence>
        </motion.div>
      )}
    </Container>
  );
}

function Chip({
  children,
  active,
  onClick,
  small,
}: {
  children: React.ReactNode;
  active: boolean;
  onClick: () => void;
  small?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "rounded-full font-medium transition-all duration-300",
        small ? "px-3 py-1.5 text-xs" : "px-4 py-2 text-sm",
        active
          ? "bg-gradient-to-br from-aurora-violet to-aurora-indigo text-white shadow-glow-violet"
          : "glass text-white/65 hover:text-white",
      )}
    >
      {children}
    </button>
  );
}
