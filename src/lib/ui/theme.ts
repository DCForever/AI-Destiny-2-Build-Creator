/** Theme preference + resolution for Matte Flap Ledger. */

export const THEME_STORAGE_KEY = "d2bc-theme";

export type ThemePreference = "dark" | "light" | "system";
export type ResolvedTheme = "dark" | "light";

export const THEME_PREFERENCES: ThemePreference[] = ["dark", "light", "system"];

export function isThemePreference(value: unknown): value is ThemePreference {
  return value === "dark" || value === "light" || value === "system";
}

export function resolveTheme(
  preference: ThemePreference,
  systemPrefersLight: boolean,
): ResolvedTheme {
  if (preference === "system") {
    return systemPrefersLight ? "light" : "dark";
  }
  return preference;
}

/**
 * Cycle so each step changes what you *see* when possible.
 * System (resolved dark) → Light → Dark → System …
 * Avoids System→Dark no-op when the OS is already dark.
 */
export function nextThemePreference(
  current: ThemePreference,
  resolved: ResolvedTheme = "dark",
): ThemePreference {
  if (current === "system") {
    return resolved === "dark" ? "light" : "dark";
  }
  if (current === "light") {
    return "dark";
  }
  // dark → system (back to OS)
  return "system";
}

export function themePreferenceLabel(preference: ThemePreference): string {
  switch (preference) {
    case "dark":
      return "Dark";
    case "light":
      return "Light";
    case "system":
      return "System";
  }
}

/** Inline bootstrap — keep in sync with ThemeProvider storage key. */
export const THEME_BOOTSTRAP_SCRIPT = `(function(){try{var k=${JSON.stringify(THEME_STORAGE_KEY)};var t=localStorage.getItem(k);if(t!=="light"&&t!=="dark"&&t!=="system"){t="system";}var r=t==="system"?(window.matchMedia("(prefers-color-scheme: light)").matches?"light":"dark"):t;document.documentElement.setAttribute("data-theme",r);document.documentElement.setAttribute("data-theme-pref",t);}catch(e){document.documentElement.setAttribute("data-theme","dark");document.documentElement.setAttribute("data-theme-pref","system");}})();`;
