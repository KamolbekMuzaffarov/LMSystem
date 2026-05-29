import { DashboardShell } from "@/components/layout/DashboardShell";
import type { ReactNode } from "react";

export default function TeacherLayout({ children }: { children: ReactNode }) {
  return (
    <DashboardShell
      role="teacher"
      roleLabel="O'qituvchi"
      userName="Dilnoza Karimova"
      userInitials="DK"
      gradient="from-aurora-pink to-aurora-fuchsia"
    >
      {children}
    </DashboardShell>
  );
}
