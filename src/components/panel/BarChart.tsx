"use client";

import { motion } from "framer-motion";

interface BarChartProps {
  data: { month: string; value: number }[];
  unit?: string;
}

export function BarChart({ data, unit = "" }: BarChartProps) {
  const max = Math.max(...data.map((d) => d.value));
  return (
    <div className="flex h-56 items-end gap-2.5 sm:gap-4">
      {data.map((d, i) => (
        <div key={d.month} className="flex flex-1 flex-col items-center gap-2">
          <span className="text-xs font-medium text-white/70">
            {d.value}
            {unit}
          </span>
          <div className="flex h-full w-full items-end">
            <motion.div
              initial={{ height: 0 }}
              whileInView={{ height: `${(d.value / max) * 100}%` }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1], delay: i * 0.08 }}
              className="w-full rounded-t-xl bg-gradient-to-t from-aurora-violet/30 via-aurora-violet/70 to-aurora-pink ring-1 ring-inset ring-white/10"
            />
          </div>
          <span className="text-xs text-white/45">{d.month}</span>
        </div>
      ))}
    </div>
  );
}
