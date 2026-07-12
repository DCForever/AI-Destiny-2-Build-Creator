import { AppShell } from "@/components/AppShell";
import { LoadoutsPage } from "@/components/LoadoutsPage";

export const metadata = {
  title: "In-Game Loadouts — Destiny 2 Build Creator",
};

export default function LoadoutsRoute() {
  return (
    <AppShell active="loadouts">
      <LoadoutsPage />
    </AppShell>
  );
}
