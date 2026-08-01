import { AppShell } from "@/components/AppShell";
import { SetsPage } from "@/components/sets/SetsPage";

export const metadata = {
  title: "Sets — Destiny 2 Build Creator",
};

export default function SetsRoute() {
  return (
    <AppShell active="sets">
      <SetsPage />
    </AppShell>
  );
}
