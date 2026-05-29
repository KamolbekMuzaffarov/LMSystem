import { cn } from "@/lib/utils";

export function ProgressBar({
  value,
  gradient = "from-aurora-violet to-aurora-pink",
  className,
}: {
  value: number;
  gradient?: string;
  className?: string;
}) {
  const clamped = Math.min(100, Math.max(0, value));
  return (
    <div
      className={cn("h-2 w-full overflow-hidden rounded-full bg-white/10", className)}
    >
      <div
        className={cn(
          "h-full rounded-full bg-gradient-to-r transition-[width] duration-700 ease-out-soft",
          gradient,
        )}
        style={{ width: `${clamped}%` }}
      />
    </div>
  );
}
