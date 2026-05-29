import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Deterministic Uzbek-style number format: space thousands separator, comma
// decimal. We deliberately AVOID Intl/toLocaleString("uz-UZ") because Node and
// the browser format that locale differently (e.g. "0,0" vs "0.0", or grouping
// separators), which triggers React hydration mismatches on server-rendered text.
export function formatNumber(value: number, decimals = 0): string {
  const fixed = Math.abs(value).toFixed(decimals);
  const [intPart, fracPart = ""] = fixed.split(".");
  const grouped = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  const sign = value < 0 ? "-" : "";
  return `${sign}${grouped}${fracPart ? "," + fracPart : ""}`;
}

export function formatPrice(value: number): string {
  return formatNumber(value) + " so'm";
}

const UZ_MONTHS = [
  "yanvar", "fevral", "mart", "aprel", "may", "iyun",
  "iyul", "avgust", "sentyabr", "oktyabr", "noyabr", "dekabr",
];

// Deterministic "5 may" style date. Parses an ISO "YYYY-MM-DD" string manually
// so it is both timezone- and locale-independent (no SSR/client mismatch).
export function formatDateUz(date: string): string {
  const [y, m, d] = date.split("T")[0].split("-").map(Number);
  if (!y || !m || !d || m < 1 || m > 12) return date;
  return `${d} ${UZ_MONTHS[m - 1]}`;
}
