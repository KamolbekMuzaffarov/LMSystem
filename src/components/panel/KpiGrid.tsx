import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { GlassCard } from "@/components/ui/GlassCard";
import { cn } from "@/lib/utils";
import type { KpiCard } from "@/lib/mock/panel";

export function KpiGrid({ items }: { items: KpiCard[] }) {
  return (
    <Stagger className="grid grid-cols-2 gap-4 lg:grid-cols-4">
      {items.map((k) => {
        const Icon = k.icon;
        return (
          <StaggerItem key={k.label} className="h-full">
            <GlassCard sheen className="group h-full overflow-hidden p-5">
              <div
                className={cn(
                  "mb-4 flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br text-white shadow-glass transition-transform duration-500 group-hover:scale-110",
                  k.gradient,
                )}
              >
                <Icon className="h-5 w-5" />
              </div>
              <p className="text-2xl font-semibold tracking-tight text-white sm:text-3xl">
                {k.value}
              </p>
              <p className="mt-1 text-sm text-white/55">{k.label}</p>
              {k.trend && (
                <p className="mt-3 text-xs font-medium text-aurora-cyan">{k.trend}</p>
              )}
            </GlassCard>
          </StaggerItem>
        );
      })}
    </Stagger>
  );
}
