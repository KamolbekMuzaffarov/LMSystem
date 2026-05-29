import Link from "next/link";
import { Sparkles, Send, Instagram, Youtube, Phone, Mail, MapPin } from "lucide-react";
import { navLinks, site } from "@/lib/mock/site";
import { paymentMethods } from "@/lib/mock/pricing";
import { Container } from "@/components/ui/Container";
import { GlassCard } from "@/components/ui/GlassCard";

const panels = [
  { label: "O'quvchi paneli", href: "/student" },
  { label: "O'qituvchi paneli", href: "/teacher" },
  { label: "Admin paneli", href: "/admin" },
  { label: "Kirish", href: "/kirish" },
];

export function Footer() {
  return (
    <footer className="relative mt-24 pb-10">
      <Container>
        <GlassCard strong className="overflow-hidden p-8 sm:p-12">
          <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4">
            <div className="lg:col-span-1">
              <Link href="/" className="flex items-center gap-2.5">
                <span className="flex h-9 w-9 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
                  <Sparkles className="h-5 w-5 text-white" />
                </span>
                <span className="text-lg font-semibold tracking-tight text-white">
                  {site.name}
                </span>
              </Link>
              <p className="mt-4 max-w-xs text-sm text-white/55">
                {site.tagline}. Zamonaviy texnologiyalar bilan bilim olishni
                yangicha tajribaga aylantiramiz.
              </p>
              <div className="mt-5 flex gap-2">
                {[Send, Instagram, Youtube].map((Icon, i) => (
                  <a
                    key={i}
                    href="#"
                    className="glass glass-edge flex h-10 w-10 items-center justify-center rounded-full text-white/70 transition-colors hover:text-white"
                    aria-label="Ijtimoiy tarmoq"
                  >
                    <Icon className="h-4 w-4" />
                  </a>
                ))}
              </div>
            </div>

            <div>
              <h4 className="text-sm font-semibold uppercase tracking-wider text-white/40">
                Sahifalar
              </h4>
              <ul className="mt-4 space-y-3">
                {navLinks.map((l) => (
                  <li key={l.href}>
                    <Link href={l.href} className="text-sm text-white/65 transition-colors hover:text-white">
                      {l.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h4 className="text-sm font-semibold uppercase tracking-wider text-white/40">
                Panellar
              </h4>
              <ul className="mt-4 space-y-3">
                {panels.map((l) => (
                  <li key={l.href}>
                    <Link href={l.href} className="text-sm text-white/65 transition-colors hover:text-white">
                      {l.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h4 className="text-sm font-semibold uppercase tracking-wider text-white/40">
                Aloqa
              </h4>
              <ul className="mt-4 space-y-3 text-sm text-white/65">
                <li className="flex items-center gap-2.5">
                  <Phone className="h-4 w-4 text-aurora-violet" /> {site.phone}
                </li>
                <li className="flex items-center gap-2.5">
                  <Mail className="h-4 w-4 text-aurora-violet" /> {site.email}
                </li>
                <li className="flex items-start gap-2.5">
                  <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-aurora-violet" /> {site.address}
                </li>
              </ul>
            </div>
          </div>

          <div className="mt-10 flex flex-col items-center justify-between gap-5 border-t border-white/10 pt-6 sm:flex-row">
            <p className="text-sm text-white/45">
              © {new Date().getFullYear()} {site.name}. Barcha huquqlar himoyalangan.
            </p>
            <div className="flex flex-wrap items-center gap-2">
              {paymentMethods.map((m) => (
                <span
                  key={m}
                  className="glass rounded-full px-3 py-1 text-xs font-medium text-white/60"
                >
                  {m}
                </span>
              ))}
            </div>
          </div>
        </GlassCard>
      </Container>
    </footer>
  );
}
