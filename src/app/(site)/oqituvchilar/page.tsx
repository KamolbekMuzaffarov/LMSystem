import type { Metadata } from "next";
import { Container } from "@/components/ui/Container";
import { PageHeader } from "@/components/layout/PageHeader";
import { TeacherCard } from "@/components/cards/TeacherCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { teachers } from "@/lib/mock/people";

export const metadata: Metadata = { title: "O'qituvchilar" };

export default function TeachersPage() {
  return (
    <>
      <PageHeader
        eyebrow="Jamoa"
        title={<>Bizning <span className="gradient-text">o'qituvchilar</span></>}
        subtitle="Sertifikatlangan, tajribali va natijaga yo'naltirilgan mutaxassislar."
      />
      <Container className="pb-10">
        <Stagger className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {teachers.map((t) => (
            <StaggerItem key={t.slug} className="h-full">
              <TeacherCard teacher={t} />
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </>
  );
}
