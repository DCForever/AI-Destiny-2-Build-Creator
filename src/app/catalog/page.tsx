import { AppShell } from "@/components/AppShell";
import { CatalogPage } from "@/components/catalog/CatalogPage";

export const metadata = {
  title: "Catalog — Destiny 2 Build Creator",
};

export default function CatalogRoute() {
  return (
    <AppShell active="catalog">
      <CatalogPage />
    </AppShell>
  );
}
