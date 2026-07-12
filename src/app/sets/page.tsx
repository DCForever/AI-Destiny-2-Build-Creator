import { AppShell } from "@/components/AppShell";

export const metadata = {
  title: "Sets — Destiny 2 Build Creator",
};

export default function SetsRoute() {
  return (
    <AppShell active="sets">
      <div className="flex-1 max-w-3xl mx-auto p-6 space-y-3">
        <h1 className="text-lg text-foreground">Sets</h1>
        <p className="text-sm text-muted leading-relaxed">
          Production Sets library is next. Until then use{" "}
          <a href="/debug/sets" className="text-accent hover:text-accent-strong">
            /debug/sets
          </a>{" "}
          to curate weapon, armor, pair, and fashion sets.
        </p>
      </div>
    </AppShell>
  );
}
