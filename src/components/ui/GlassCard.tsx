import { cn } from "@/lib/utils";
import type { ElementType, HTMLAttributes } from "react";

interface GlassCardProps extends HTMLAttributes<HTMLElement> {
  strong?: boolean;
  edge?: boolean;
  sheen?: boolean;
  glow?: "violet" | "pink" | "none";
  as?: ElementType;
}

export function GlassCard({
  className,
  strong,
  edge = true,
  sheen,
  glow = "none",
  as: Tag = "div",
  children,
  ...props
}: GlassCardProps) {
  return (
    <Tag
      className={cn(
        "relative rounded-3xl",
        strong ? "glass-strong" : "glass",
        edge && "glass-edge",
        sheen && "glass-sheen",
        glow === "violet" && "shadow-glow-violet",
        glow === "pink" && "shadow-glow-pink",
        className,
      )}
      {...props}
    >
      {children}
    </Tag>
  );
}
