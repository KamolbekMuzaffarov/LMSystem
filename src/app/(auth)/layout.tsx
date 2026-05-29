import Link from "next/link";
import { ArrowLeft, Sparkles } from "lucide-react";
import { site } from "@/lib/mock/site";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="relative flex min-h-screen flex-col">
      <header className="flex items-center justify-between p-5 sm:p-8">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
            <Sparkles className="h-5 w-5 text-white" />
          </span>
          <span className="text-lg font-semibold tracking-tight text-white">{site.name}</span>
        </Link>
        <Link
          href="/"
          className="flex items-center gap-2 text-sm text-white/60 transition-colors hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" /> Bosh sahifa
        </Link>
      </header>
      <main className="flex flex-1 items-center justify-center px-5 py-8">{children}</main>
    </div>
  );
}
