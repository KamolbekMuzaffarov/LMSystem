import type { Metadata } from "next";
import { AuthShell } from "@/components/sections/AuthShell";
import { RegisterForm } from "@/components/sections/RegisterForm";

export const metadata: Metadata = { title: "Ro'yxatdan o'tish" };

export default function RegisterPage() {
  return (
    <AuthShell>
      <RegisterForm />
    </AuthShell>
  );
}
