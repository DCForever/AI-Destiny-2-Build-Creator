"use client";

import { themePreferenceLabel } from "@/lib/ui/theme";

import { useTheme } from "./ThemeProvider";

/**
 * Cycles dark → light → system. Shows resolved mode + preference in the label.
 */
export function ThemeToggle({ className = "" }: { className?: string }) {
  const { preference, resolved, cyclePreference } = useTheme();
  const label = themePreferenceLabel(preference);
  const title = `Theme: ${label} (showing ${resolved}). Click to cycle Dark / Light / System.`;

return (
    <button
      type="button"
      onClick={cyclePreference}
      title={title}
      aria-label={title}
      className={`shrink-0 font-display text-[10px] sm:text-[11px] tracking-[0.12em] uppercase px-1.5 sm:px-2 py-1 border border-accent/50 text-accent bg-[color-mix(in_srgb,var(--accent)_12%,transparent)] hover:opacity-90 transition-opacity ${className}`.trim()}
    >
      <span className="sm:hidden" aria-hidden>
        {resolved === "light" ? "LT" : "DK"}
      </span>
      <span className="hidden sm:inline">
        {label}
        {preference === "system" ? ` · ${resolved === "light" ? "LT" : "DK"}` : ""}
      </span>
    </button>
  );
}
