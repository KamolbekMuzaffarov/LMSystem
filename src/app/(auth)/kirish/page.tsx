import type { Metadata } from "next";
import { AuthShell } from "@/components/sections/AuthShell";
import { LoginForm } from "@/components/sections/LoginForm";

export const metadata: Metadata = { title: "Kirish" };

export default function LoginPage() {
  return (
    <AuthShell>
      <LoginForm />
    </AuthShell>
  );
}
