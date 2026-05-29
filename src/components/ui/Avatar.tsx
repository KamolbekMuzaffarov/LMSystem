import { cn } from "@/lib/utils";

const sizes = {
  sm: "h-9 w-9 text-xs",
  md: "h-11 w-11 text-sm",
  lg: "h-20 w-20 text-xl",
  xl: "h-28 w-28 text-3xl",
};

export function Avatar({
  initials,
  gradient,
  size = "md",
  className,
}: {
  initials: string;
  gradient: string;
  size?: keyof typeof sizes;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "relative inline-flex items-center justify-center rounded-full bg-gradient-to-br font-semibold text-white shadow-glass",
        gradient,
        sizes[size],
        className,
      )}
    >
      <span className="absolute inset-0 rounded-full bg-[radial-gradient(120%_100%_at_30%_0%,rgba(255,255,255,0.35),transparent_55%)]" />
      <span className="relative">{initials}</span>
    </span>
  );
}
