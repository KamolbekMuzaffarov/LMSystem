import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AuroraBackground } from "@/components/ui/AuroraBackground";
import { CursorGlow } from "@/components/ui/CursorGlow";
import { site } from "@/lib/mock/site";

export const metadata: Metadata = {
  title: {
    default: `${site.name} — ${site.tagline}`,
    template: `%s — ${site.name}`,
  },
  description:
    "Aurora Academy — IELTS, ingliz tili, dasturlash va dizayn bo'yicha zamonaviy o'quv markazi. Jonli darslar, AI yordamchi va sertifikat.",
  keywords: ["o'quv markazi", "IELTS", "ingliz tili", "dasturlash", "kurslar", "Toshkent"],
};

export const viewport: Viewport = {
  themeColor: "#0a0a14",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="uz" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <AuroraBackground />
        <CursorGlow />
        <div className="grain" aria-hidden />
        <div className="relative z-10">{children}</div>
      </body>
    </html>
  );
}
