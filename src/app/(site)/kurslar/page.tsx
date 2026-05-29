import type { Metadata } from "next";
import { PageHeader } from "@/components/layout/PageHeader";
import { CoursesExplorer } from "@/components/sections/CoursesExplorer";

export const metadata: Metadata = { title: "Kurslar" };

export default function CoursesPage() {
  return (
    <>
      <PageHeader
        eyebrow="Kurslar katalogi"
        title={<>O'zingizga mos <span className="gradient-text">kursni</span> toping</>}
        subtitle="IELTS'dan dasturlashgacha — har bir kurs amaliyot, mentor va sertifikat bilan."
      />
      <CoursesExplorer />
    </>
  );
}
