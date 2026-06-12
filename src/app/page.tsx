import { AppShell } from "@/components/AppShell";
import { GeneratorPage } from "@/components/GeneratorPage";

export default function Home() {
  return (
    <AppShell active="generator">
      <GeneratorPage />
    </AppShell>
  );
}
