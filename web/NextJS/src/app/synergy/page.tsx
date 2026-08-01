import { AppShell } from "@/components/AppShell";
import { SynergyPage } from "@/components/synergy/SynergyPage";

export const metadata = {
  title: "Synergy — Destiny 2 Build Creator",
};

export default function SynergyRoute() {
  return (
    <AppShell active="synergy">
      <SynergyPage />
    </AppShell>
  );
}
