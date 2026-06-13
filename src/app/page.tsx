import { AppShell } from "@/components/AppShell";
import { GeneratorPage } from "@/components/GeneratorPage";
import { isMultiPassEnabled } from "@/lib/config/env";

export default function Home() {
  return (
    <AppShell active="generator">
      <GeneratorPage multiPassAvailable={isMultiPassEnabled()} />
    </AppShell>
  );
}
