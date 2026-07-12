import { AppShell } from "@/components/AppShell";

export const metadata = {
  title: "Synergy — Destiny 2 Build Creator",
};

export default function SynergyRoute() {
  return (
    <AppShell active="synergy">
      <div className="flex-1 max-w-3xl mx-auto p-6 space-y-3">
        <h1 className="text-lg text-foreground">Synergy</h1>
        <p className="text-sm text-muted leading-relaxed">
          Production Synergy library is next. Until then use{" "}
          <a href="/debug/synergies" className="text-accent hover:text-accent-strong">
            /debug/synergies
          </a>{" "}
          to curate designations used by Build.
        </p>
      </div>
    </AppShell>
  );
}
