import type { Metadata } from "next";
import { Phone, Mail, MapPin, Clock, Send, Instagram, Youtube } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { PageHeader } from "@/components/layout/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";
import { Reveal } from "@/components/ui/Reveal";
import { ContactForm } from "@/components/sections/ContactForm";
import { site } from "@/lib/mock/site";

export const metadata: Metadata = { title: "Aloqa" };

const contactItems = [
  { icon: Phone, label: "Telefon", value: site.phone },
  { icon: Mail, label: "Email", value: site.email },
  { icon: MapPin, label: "Manzil", value: site.address },
  { icon: Clock, label: "Ish vaqti", value: site.hours },
];

export default function ContactPage() {
  return (
    <>
      <PageHeader
        eyebrow="Aloqa"
        title={<>Biz bilan <span className="gradient-text">bog'laning</span></>}
        subtitle="Savollaringiz bormi? Forma to'ldiring yoki to'g'ridan-to'g'ri qo'ng'iroq qiling."
      />

      <Container className="pb-10">
        <div className="grid gap-6 lg:grid-cols-5">
          <Reveal direction="right" className="lg:col-span-2">
            <div className="flex h-full flex-col gap-6">
              <GlassCard className="p-6 sm:p-7">
                <div className="space-y-5">
                  {contactItems.map((c) => (
                    <div key={c.label} className="flex items-start gap-4">
                      <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-indigo text-white">
                        <c.icon className="h-5 w-5" />
                      </span>
                      <div>
                        <div className="text-xs uppercase tracking-wider text-white/40">{c.label}</div>
                        <div className="mt-0.5 text-white">{c.value}</div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-6 flex gap-2 border-t border-white/10 pt-5">
                  {[Send, Instagram, Youtube].map((Icon, i) => (
                    <a
                      key={i}
                      href="#"
                      className="glass glass-edge flex h-11 w-11 items-center justify-center rounded-full text-white/70 transition-colors hover:text-white"
                    >
                      <Icon className="h-5 w-5" />
                    </a>
                  ))}
                </div>
              </GlassCard>

              {/* map placeholder */}
              <GlassCard className="relative flex-1 overflow-hidden p-0">
                <div className="relative flex h-48 items-center justify-center bg-gradient-to-br from-aurora-indigo/40 via-aurora-violet/30 to-aurora-blue/40">
                  <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.06)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.06)_1px,transparent_1px)] bg-[size:28px_28px]" />
                  <div className="relative flex flex-col items-center gap-2 text-white">
                    <MapPin className="h-8 w-8 text-aurora-pink" />
                    <span className="text-sm text-white/70">{site.address}</span>
                  </div>
                </div>
              </GlassCard>
            </div>
          </Reveal>

          <Reveal direction="left" className="lg:col-span-3">
            <GlassCard strong className="h-full p-6 sm:p-8">
              <h2 className="text-xl font-semibold text-white">Murojaat formasi</h2>
              <p className="mt-1 text-sm text-white/55">
                Bir kun ichida javob beramiz.
              </p>
              <div className="mt-6">
                <ContactForm />
              </div>
            </GlassCard>
          </Reveal>
        </div>
      </Container>
    </>
  );
}
