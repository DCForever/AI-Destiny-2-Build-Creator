import { AppShell } from "@/components/AppShell";
import { AnalyzerPage } from "@/components/analyze/AnalyzerPage";

export const metadata = {
  title: "Analyzer — Destiny 2 Build Creator",
};

/** Off primary nav (Generator/Analyzer retired). Kept for optional import workflows. */
export default function AnalyzeRoute() {
  return (
    <AppShell active="build">
      <AnalyzerPage />
    </AppShell>
  );
}
