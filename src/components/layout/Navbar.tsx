"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Menu, X, Sparkles } from "lucide-react";
import { navLinks, site } from "@/lib/mock/site";
import { GlassButton } from "@/components/ui/GlassButton";
import { Container } from "@/components/ui/Container";
import { cn } from "@/lib/utils";

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => setOpen(false), [pathname]);

  return (
    <header className="fixed inset-x-0 top-0 z-50">
      <motion.div
        initial={{ y: -80, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
      >
        <Container className="pt-3 sm:pt-4">
          <nav
            className={cn(
              "flex h-16 items-center justify-between rounded-full px-3 pl-5 transition-all duration-500 glass-edge",
              scrolled ? "glass-strong" : "glass",
            )}
          >
            <Link href="/" className="flex items-center gap-2.5">
              <span className="flex h-9 w-9 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
                <Sparkles className="h-5 w-5 text-white" />
              </span>
              <span className="text-lg font-semibold tracking-tight text-white">
                {site.name}
              </span>
            </Link>

            <div className="hidden items-center gap-1 lg:flex">
              {navLinks.map((link) => {
                const active = pathname === link.href;
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={cn(
                      "relative rounded-full px-4 py-2 text-sm font-medium transition-colors",
                      active ? "text-white" : "text-white/65 hover:text-white",
                    )}
                  >
                    {active && (
                      <motion.span
                        layoutId="nav-pill"
                        className="absolute inset-0 -z-10 rounded-full bg-white/10"
                        transition={{ type: "spring", stiffness: 400, damping: 32 }}
                      />
                    )}
                    {link.label}
                  </Link>
                );
              })}
            </div>

            <div className="hidden items-center gap-2 lg:flex">
              <GlassButton href="/kirish" variant="ghost" size="sm">
                Kirish
              </GlassButton>
              <GlassButton href="/royxat" variant="primary" size="sm">
                Ro'yxatdan o'tish
              </GlassButton>
            </div>

            <button
              onClick={() => setOpen((v) => !v)}
              className="flex h-10 w-10 items-center justify-center rounded-full text-white lg:hidden"
              aria-label="Menyu"
            >
              {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </nav>
        </Container>
      </motion.div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.25 }}
            className="lg:hidden"
          >
            <Container className="mt-2">
              <div className="glass-strong glass-edge flex flex-col gap-1 rounded-3xl p-3">
                {navLinks.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="rounded-2xl px-4 py-3 text-base font-medium text-white/80 transition-colors hover:bg-white/10 hover:text-white"
                  >
                    {link.label}
                  </Link>
                ))}
                <div className="mt-2 grid grid-cols-2 gap-2">
                  <GlassButton href="/kirish" variant="glass" size="md">
                    Kirish
                  </GlassButton>
                  <GlassButton href="/royxat" variant="primary" size="md">
                    Ro'yxat
                  </GlassButton>
                </div>
              </div>
            </Container>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
}
