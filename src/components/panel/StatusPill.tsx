import { cn } from "@/lib/utils";

export type Tone = "amber" | "sky" | "emerald" | "violet" | "pink" | "slate";

const tones: Record<Tone, string> = {
  amber: "bg-amber-400/15 text-amber-300 ring-amber-400/30",
  sky: "bg-sky-400/15 text-sky-300 ring-sky-400/30",
  emerald: "bg-emerald-400/15 text-emerald-300 ring-emerald-400/30",
  violet: "bg-aurora-violet/20 text-violet-200 ring-aurora-violet/40",
  pink: "bg-aurora-pink/15 text-pink-300 ring-aurora-pink/30",
  slate: "bg-white/10 text-white/70 ring-white/15",
};

export function StatusPill({
  label,
  tone = "slate",
  className,
}: {
  label: string;
  tone?: Tone;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset",
        tones[tone],
        className,
      )}
    >
      {label}
    </span>
  );
}

/** Maps the known Uzbek status strings used in mock data to a tone. */
export function toneForStatus(status: string): Tone {
  switch (status) {
    case "Baholandi":
    case "Qabul":
    case "To'langan":
      return "emerald";
    case "Tekshirilmoqda":
    case "Ko'rildi":
      return "sky";
    case "Kutilmoqda":
    case "Kutilyapti":
      return "amber";
    case "Yangi":
      return "violet";
    default:
      return "slate";
  }
}
