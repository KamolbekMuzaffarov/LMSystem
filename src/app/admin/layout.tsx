import { DashboardShell } from "@/components/layout/DashboardShell";
import type { ReactNode } from "react";

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <DashboardShell
      role="admin"
      roleLabel="Administrator"
      userName="Admin Aurora"
      userInitials="AA"
      gradient="from-aurora-cyan to-aurora-blue"
    >
      {children}
    </DashboardShell>
  );
}
