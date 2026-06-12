import { AppShell } from "@/components/AppShell";
import { AnalyzerPage } from "@/components/analyze/AnalyzerPage";

export const metadata = {
  title: "Analyzer — Destiny 2 Build Creator",
};

export default function AnalyzeRoute() {
  return (
    <AppShell active="analyzer">
      <AnalyzerPage />
    </AppShell>
  );
}
