import { GlassCard } from "@/components/ui/GlassCard";
import { cn } from "@/lib/utils";
import type { ReactNode } from "react";

interface PanelCardProps {
  title?: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
}

/** A titled glass section used across all dashboards. */
export function PanelCard({
  title,
  subtitle,
  action,
  children,
  className,
  bodyClassName,
}: PanelCardProps) {
  return (
    <GlassCard className={cn("p-5 sm:p-6", className)}>
      {(title || action) && (
        <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
          <div>
            {title && (
              <h2 className="text-base font-semibold tracking-tight text-white">
                {title}
              </h2>
            )}
            {subtitle && <p className="mt-0.5 text-sm text-white/50">{subtitle}</p>}
          </div>
          {action}
        </div>
      )}
      <div className={bodyClassName}>{children}</div>
    </GlassCard>
  );
}
