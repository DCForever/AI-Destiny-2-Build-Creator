import { AppShell } from "@/components/AppShell";

export const metadata = {
  title: "Catalog — Destiny 2 Build Creator",
};

export default function CatalogRoute() {
  return (
    <AppShell active="catalog">
      <div className="flex-1 max-w-3xl mx-auto p-6 space-y-3">
        <h1 className="text-lg text-foreground">Catalog</h1>
        <p className="text-sm text-muted leading-relaxed">
          Production Catalog browse is next. Until then use{" "}
          <a href="/debug/catalog" className="text-accent hover:text-accent-strong">
            /debug/catalog
          </a>
          .
        </p>
      </div>
    </AppShell>
  );
}
