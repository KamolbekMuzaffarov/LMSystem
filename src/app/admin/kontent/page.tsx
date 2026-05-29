import type { Metadata } from "next";
import { Megaphone } from "lucide-react";
import { PageIntro } from "@/components/panel/PageIntro";
import { PanelPlaceholder } from "@/components/panel/PanelPlaceholder";

export const metadata: Metadata = { title: "Kontent" };

export default function AdminContentPage() {
  return (
    <div>
      <PageIntro title="Kontent (CMS)" subtitle="Landing bloklari, blog va e'lonlar" />
      <PanelPlaceholder
        icon={Megaphone}
        title="Kontent boshqaruvi"
        description="Landing sahifa bloklari, blog maqolalari, bannerlar va push e'lonlarni shu bo'limdan tahrirlaysiz. Drag-and-drop konstruktor tayyorlanmoqda."
      />
    </div>
  );
}
