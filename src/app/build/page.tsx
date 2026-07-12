import { AppShell } from "@/components/AppShell";
import { BuildPage } from "@/components/build/BuildPage";

export const metadata = {
  title: "Build — Destiny 2 Build Creator",
};

export default function BuildRoute() {
  return (
    <AppShell active="build">
      <BuildPage />
    </AppShell>
  );
}
