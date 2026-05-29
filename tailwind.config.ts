import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/app/**/*.{ts,tsx}",
    "./src/components/**/*.{ts,tsx}",
    "./src/lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        ink: {
          DEFAULT: "#0a0a14",
          soft: "#13131f",
        },
        aurora: {
          violet: "#7c3aed",
          indigo: "#4f46e5",
          blue: "#2563eb",
          pink: "#db2777",
          fuchsia: "#c026d3",
          cyan: "#06b6d4",
        },
      },
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
        display: ["var(--font-display)", "var(--font-sans)", "sans-serif"],
      },
      fontSize: {
        "hero-sm": ["3.25rem", { lineHeight: "1.02", letterSpacing: "-0.03em" }],
        hero: ["5.5rem", { lineHeight: "0.96", letterSpacing: "-0.04em" }],
        "hero-lg": ["8.5rem", { lineHeight: "0.92", letterSpacing: "-0.045em" }],
      },
      borderRadius: {
        "4xl": "2rem",
        "5xl": "2.75rem",
      },
      boxShadow: {
        glass:
          "0 8px 32px -8px rgba(8,7,28,0.55), inset 0 1px 0 0 rgba(255,255,255,0.18), inset 0 -1px 1px 0 rgba(255,255,255,0.04)",
        "glass-lg":
          "0 24px 70px -20px rgba(8,7,28,0.7), inset 0 1px 0 0 rgba(255,255,255,0.22), inset 0 -1px 2px 0 rgba(255,255,255,0.05)",
        "glow-violet": "0 0 60px -10px rgba(124,58,237,0.55)",
        "glow-pink": "0 0 60px -10px rgba(219,39,119,0.5)",
      },
      backdropBlur: {
        glass: "28px",
      },
      transitionTimingFunction: {
        spring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
        "out-soft": "cubic-bezier(0.22, 1, 0.36, 1)",
      },
      keyframes: {
        "aurora-drift": {
          "0%": { transform: "translate3d(0,0,0) rotate(0deg) scale(1)" },
          "33%": { transform: "translate3d(4%,-3%,0) rotate(40deg) scale(1.12)" },
          "66%": { transform: "translate3d(-3%,4%,0) rotate(-30deg) scale(0.95)" },
          "100%": { transform: "translate3d(0,0,0) rotate(0deg) scale(1)" },
        },
        "aurora-drift-slow": {
          "0%": { transform: "translate3d(0,0,0) scale(1)" },
          "50%": { transform: "translate3d(-6%,5%,0) scale(1.15)" },
          "100%": { transform: "translate3d(0,0,0) scale(1)" },
        },
        "aurora-spin": {
          "0%": { transform: "translate(-50%,-50%) rotate(0deg)" },
          "100%": { transform: "translate(-50%,-50%) rotate(360deg)" },
        },
        float: {
          "0%,100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-12px)" },
        },
        shimmer: {
          "100%": { transform: "translateX(100%)" },
        },
      },
      animation: {
        "aurora-drift": "aurora-drift 22s ease-in-out infinite",
        "aurora-drift-slow": "aurora-drift-slow 30s ease-in-out infinite",
        "aurora-spin": "aurora-spin 48s linear infinite",
        float: "float 6s ease-in-out infinite",
        shimmer: "shimmer 2.5s infinite",
      },
    },
  },
  plugins: [],
};

export default config;
