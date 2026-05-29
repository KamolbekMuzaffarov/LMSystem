"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Send, CheckCircle2 } from "lucide-react";
import { GlassButton } from "@/components/ui/GlassButton";

const fieldCls =
  "h-12 w-full rounded-2xl border border-white/10 bg-white/5 px-4 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSent(true);
  }

  return (
    <AnimatePresence mode="wait">
      {sent ? (
        <motion.div
          key="ok"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex flex-col items-center justify-center gap-4 py-12 text-center"
        >
          <span className="flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-emerald-500 to-emerald-400 shadow-[0_0_50px_-10px_rgba(16,185,129,0.6)]">
            <CheckCircle2 className="h-8 w-8 text-white" />
          </span>
          <h3 className="text-xl font-semibold text-white">Rahmat! Murojaatingiz yuborildi</h3>
          <p className="max-w-sm text-sm text-white/55">
            Menejerlarimiz tez orada siz bilan bog'lanishadi.
          </p>
          <GlassButton variant="glass" size="md" onClick={() => setSent(false)}>
            Yana yuborish
          </GlassButton>
        </motion.div>
      ) : (
        <motion.form
          key="form"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onSubmit={onSubmit}
          className="flex flex-col gap-4"
        >
          <div className="grid gap-4 sm:grid-cols-2">
            <input required placeholder="Ismingiz" className={fieldCls} />
            <input required type="tel" placeholder="Telefon raqamingiz" className={fieldCls} />
          </div>
          <input type="email" placeholder="Email (ixtiyoriy)" className={fieldCls} />
          <select required defaultValue="" className={fieldCls}>
            <option value="" disabled className="bg-ink">
              Qiziqtirgan yo'nalish
            </option>
            <option className="bg-ink">IELTS</option>
            <option className="bg-ink">Ingliz tili</option>
            <option className="bg-ink">Dasturlash</option>
            <option className="bg-ink">Matematika (DTM)</option>
            <option className="bg-ink">UI/UX Dizayn</option>
          </select>
          <textarea
            placeholder="Xabaringiz..."
            rows={4}
            className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder:text-white/40 outline-none transition focus:border-aurora-violet/60 focus:bg-white/10"
          />
          <GlassButton type="submit" size="lg" className="w-full">
            <Send className="h-5 w-5" /> Murojaat yuborish
          </GlassButton>
        </motion.form>
      )}
    </AnimatePresence>
  );
}
