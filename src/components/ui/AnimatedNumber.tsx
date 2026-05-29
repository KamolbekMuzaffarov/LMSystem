"use client";

import { useEffect, useRef } from "react";
import {
  useInView,
  useMotionValue,
  useSpring,
  useTransform,
  motion,
} from "framer-motion";

interface AnimatedNumberProps {
  value: number;
  suffix?: string;
  prefix?: string;
  decimals?: number;
}

// Deterministic Uzbek-style format (space thousands, comma decimal).
// IMPORTANT: do NOT use toLocaleString("uz-UZ") here — Node and the browser
// format that locale differently (server "0,0" vs client "0.0"), which causes
// a React hydration mismatch. toFixed() is identical in every environment.
function formatUz(v: number, decimals: number) {
  const fixed = Math.abs(v).toFixed(decimals);
  const [intPart, fracPart = ""] = fixed.split(".");
  const grouped = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  const sign = v < 0 ? "-" : "";
  return `${sign}${grouped}${fracPart ? "," + fracPart : ""}`;
}

// Counts up with a spring when scrolled into view.
export function AnimatedNumber({
  value,
  suffix = "",
  prefix = "",
  decimals = 0,
}: AnimatedNumberProps) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-40px" });
  const mv = useMotionValue(0);
  const spring = useSpring(mv, { stiffness: 70, damping: 22 });
  const display = useTransform(
    spring,
    (v) => `${prefix}${formatUz(v, decimals)}${suffix}`,
  );

  useEffect(() => {
    if (inView) mv.set(value);
  }, [inView, value, mv]);

  return <motion.span ref={ref}>{display}</motion.span>;
}
