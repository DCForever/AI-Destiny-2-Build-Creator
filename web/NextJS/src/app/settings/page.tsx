import { AppShell } from "@/components/AppShell";
import { SettingsPage } from "@/components/settings/SettingsPage";

export const metadata = {
  title: "Settings — Destiny 2 Build Creator",
};

export default function SettingsRoute() {
  return (
    <AppShell active="settings">
      <SettingsPage />
    </AppShell>
  );
}
