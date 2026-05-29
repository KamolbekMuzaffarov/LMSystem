import { cn } from "@/lib/utils";
import type { ReactNode } from "react";

export function Badge({
  children,
  className,
  dot,
}: {
  children: ReactNode;
  className?: string;
  dot?: boolean;
}) {
  return (
    <span
      className={cn(
        "glass glass-edge inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-sm font-medium text-white/80",
        className,
      )}
    >
      {dot && (
        <span className="relative flex h-2 w-2">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-aurora-violet opacity-75" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-aurora-violet" />
        </span>
      )}
      {children}
    </span>
  );
}
