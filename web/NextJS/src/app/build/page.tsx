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
          <div className="h-full min-h-0 flex items-start max-w-[1600px] mx-auto w-full px-3 sm:px-6 py-3 sm:py-4 text-sm text-muted">
            Loading builds…
          </div>
        }
      >
        <BuildPage />
      </Suspense>
    </AppShell>
  );
}
