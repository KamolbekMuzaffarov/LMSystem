"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import type { ReactNode } from "react";

type Variant = "primary" | "glass" | "ghost";
type Size = "sm" | "md" | "lg";

const base =
  "relative inline-flex items-center justify-center gap-2 rounded-full font-medium tracking-tight transition-colors duration-300 select-none glass-sheen overflow-hidden disabled:opacity-50 disabled:pointer-events-none";

const variants: Record<Variant, string> = {
  primary:
    "text-white bg-gradient-to-br from-aurora-violet via-aurora-indigo to-aurora-blue shadow-[0_10px_40px_-10px_rgba(124,58,237,0.7)] hover:shadow-[0_14px_50px_-8px_rgba(124,58,237,0.85)] border border-white/20",
  glass:
    "glass glass-edge text-white hover:bg-white/10",
  ghost:
    "text-white/80 hover:text-white hover:bg-white/5 border border-white/10",
};

const sizes: Record<Size, string> = {
  sm: "h-9 px-4 text-sm",
  md: "h-11 px-6 text-[15px]",
  lg: "h-14 px-8 text-base",
};

interface CommonProps {
  variant?: Variant;
  size?: Size;
  className?: string;
  children: ReactNode;
}

type ButtonProps = CommonProps & {
  href?: undefined;
  onClick?: () => void;
  type?: "button" | "submit";
  disabled?: boolean;
};

type LinkProps = CommonProps & {
  href: string;
};

const spring = { type: "spring" as const, stiffness: 400, damping: 17 };

export function GlassButton(props: ButtonProps | LinkProps) {
  const { variant = "primary", size = "md", className, children } = props;
  const classes = cn(base, variants[variant], sizes[size], className);

  if ("href" in props && props.href) {
    return (
      <motion.div whileTap={{ scale: 0.96 }} transition={spring} className="inline-flex">
        <Link href={props.href} className={classes}>
          {children}
        </Link>
      </motion.div>
    );
  }

  const { onClick, type = "button", disabled } = props as ButtonProps;
  return (
    <motion.button
      whileTap={{ scale: 0.96 }}
      transition={spring}
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={classes}
    >
      {children}
    </motion.button>
  );
}
