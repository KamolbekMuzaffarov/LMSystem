import { DashboardShell } from "@/components/layout/DashboardShell";
import type { ReactNode } from "react";

export default function StudentLayout({ children }: { children: ReactNode }) {
  return (
    <DashboardShell
      role="student"
      roleLabel="O'quvchi"
      userName="Kamolbek Muzaffarov"
      userInitials="KM"
      gradient="from-aurora-violet to-aurora-blue"
    >
      {children}
    </DashboardShell>
  );
}
