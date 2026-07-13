import { Suspense } from "react";

import { AppShell } from "@/components/AppShell";
import { BuildPage } from "@/components/build/BuildPage";

export const metadata = {
  title: "Build — Destiny 2 Build Creator",
};

export default function BuildRoute() {
  return (
    <AppShell active="build">
      <Suspense
        fallback={
          <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6 text-sm text-muted">
            Loading builds…
          </div>
        }
      >
        <BuildPage />
      </Suspense>
    </AppShell>
  );
}
