"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Sparkles, Search, Bell, Menu, LogOut, ArrowLeft } from "lucide-react";
import { site } from "@/lib/mock/site";
import { Avatar } from "@/components/ui/Avatar";
import { cn } from "@/lib/utils";
import { studentNav, teacherNav, adminNav, type NavItem } from "@/lib/mock/panel";

const navByRole = {
  student: studentNav,
  teacher: teacherNav,
  admin: adminNav,
} as const;

interface DashboardShellProps {
  role: "student" | "teacher" | "admin";
  roleLabel: string;
  userName: string;
  userInitials: string;
  gradient: string;
  children: ReactNode;
}

function NavList({
  nav,
  basePath,
  idPrefix,
  onNavigate,
}: {
  nav: NavItem[];
  basePath: string;
  idPrefix: string;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();
  return (
    <nav className="flex flex-1 flex-col gap-1">
      {nav.map((item) => {
        const Icon = item.icon;
        const active =
          pathname === item.href ||
          (item.href !== basePath && pathname.startsWith(item.href + "/"));
        return (
          <Link
            key={item.href}
            href={item.href}
            onClick={onNavigate}
            className={cn(
              "group relative flex items-center gap-3 rounded-2xl px-3.5 py-2.5 text-sm font-medium transition-colors",
              active ? "text-white" : "text-white/55 hover:text-white",
            )}
          >
            {active && (
              <motion.span
                layoutId={idPrefix}
                className="absolute inset-0 -z-10 rounded-2xl bg-gradient-to-r from-aurora-violet/30 to-aurora-pink/20 ring-1 ring-inset ring-white/15"
                transition={{ type: "spring", stiffness: 400, damping: 32 }}
              />
            )}
            <Icon
              className={cn(
                "h-[18px] w-[18px] shrink-0 transition-colors",
                active ? "text-white" : "text-white/45 group-hover:text-white/80",
              )}
            />
            <span className="truncate">{item.label}</span>
            {item.badge ? (
              <span className="ml-auto flex h-5 min-w-[20px] items-center justify-center rounded-full bg-aurora-pink px-1.5 text-[11px] font-semibold text-white">
                {item.badge}
              </span>
            ) : null}
          </Link>
        );
      })}
    </nav>
  );
}

function SidebarInner({
  nav,
  basePath,
  roleLabel,
  idPrefix,
  onNavigate,
}: {
  nav: NavItem[];
  basePath: string;
  roleLabel: string;
  idPrefix: string;
  onNavigate?: () => void;
}) {
  return (
    <div className="glass-strong glass-edge flex h-full flex-col rounded-3xl p-4">
      <Link
        href="/"
        onClick={onNavigate}
        className="flex items-center gap-2.5 rounded-2xl px-1.5 py-1.5"
      >
        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-aurora-violet to-aurora-pink shadow-glow-violet">
          <Sparkles className="h-5 w-5 text-white" />
        </span>
        <span className="flex flex-col leading-tight">
          <span className="text-sm font-semibold tracking-tight text-white">
            {site.name}
          </span>
          <span className="text-xs text-white/45">{roleLabel} paneli</span>
        </span>
      </Link>

      <div className="my-4 h-px bg-white/10" />

      <NavList
        nav={nav}
        basePath={basePath}
        idPrefix={idPrefix}
        onNavigate={onNavigate}
      />

      <div className="mt-4 flex flex-col gap-1 border-t border-white/10 pt-4">
        <Link
          href="/"
          onClick={onNavigate}
          className="flex items-center gap-3 rounded-2xl px-3.5 py-2.5 text-sm font-medium text-white/55 transition-colors hover:bg-white/5 hover:text-white"
        >
          <ArrowLeft className="h-[18px] w-[18px]" /> Saytga qaytish
        </Link>
        <Link
          href="/kirish"
          onClick={onNavigate}
          className="flex items-center gap-3 rounded-2xl px-3.5 py-2.5 text-sm font-medium text-white/55 transition-colors hover:bg-white/5 hover:text-white"
        >
          <LogOut className="h-[18px] w-[18px]" /> Chiqish
        </Link>
      </div>
    </div>
  );
}

export function DashboardShell({
  role,
  roleLabel,
  userName,
  userInitials,
  gradient,
  children,
}: DashboardShellProps) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  const nav = navByRole[role];
  const basePath = nav[0].href;

  // Close the mobile drawer whenever the route changes.
  useEffect(() => setOpen(false), [pathname]);

  return (
    <div className="flex min-h-screen">
      {/* Desktop sidebar */}
      <aside className="sticky top-0 hidden h-screen w-[16.5rem] shrink-0 p-3 lg:block">
        <SidebarInner
          nav={nav}
          basePath={basePath}
          roleLabel={roleLabel}
          idPrefix="dash-pill-desktop"
        />
      </aside>

      {/* Mobile drawer */}
      <AnimatePresence>
        {open && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setOpen(false)}
              className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
            />
            <motion.aside
              initial={{ x: "-105%" }}
              animate={{ x: 0 }}
              exit={{ x: "-105%" }}
              transition={{ type: "spring", stiffness: 320, damping: 34 }}
              className="fixed inset-y-0 left-0 z-50 w-[17rem] p-3 lg:hidden"
            >
              <SidebarInner
                nav={nav}
                basePath={basePath}
                roleLabel={roleLabel}
                idPrefix="dash-pill-mobile"
                onNavigate={() => setOpen(false)}
              />
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      {/* Main column */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 border-b border-white/5 bg-ink/50 backdrop-blur-xl">
          <div className="flex h-16 items-center gap-3 px-4 sm:px-6">
            <button
              onClick={() => setOpen(true)}
              className="flex h-10 w-10 items-center justify-center rounded-xl text-white transition-colors hover:bg-white/5 lg:hidden"
              aria-label="Menyu"
            >
              <Menu className="h-6 w-6" />
            </button>

            <label className="hidden items-center gap-2.5 rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2 transition focus-within:border-aurora-violet/50 sm:flex sm:w-72">
              <Search className="h-4 w-4 shrink-0 text-white/40" />
              <input
                placeholder="Qidirish..."
                className="w-full bg-transparent text-sm text-white placeholder:text-white/40 outline-none"
              />
            </label>

            <div className="ml-auto flex items-center gap-2 sm:gap-3">
              <button
                className="relative flex h-10 w-10 items-center justify-center rounded-xl text-white/70 transition-colors hover:bg-white/5 hover:text-white"
                aria-label="Bildirishnomalar"
              >
                <Bell className="h-5 w-5" />
                <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full bg-aurora-pink ring-2 ring-ink" />
              </button>

              <div className="flex items-center gap-2.5 rounded-2xl border border-white/10 bg-white/5 py-1 pl-1 pr-1 sm:pr-3">
                <Avatar initials={userInitials} gradient={gradient} size="sm" />
                <span className="hidden flex-col leading-tight sm:flex">
                  <span className="text-sm font-medium text-white">{userName}</span>
                  <span className="text-xs text-white/45">{roleLabel}</span>
                </span>
              </div>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 lg:px-8">
          {children}
        </main>
      </div>
    </div>
  );
}
