import { describe, expect, it } from "vitest";

import {
  isThemePreference,
  nextThemePreference,
  resolveTheme,
} from "@/lib/ui/theme";

describe("theme", () => {
  it("resolves system from OS preference", () => {
    expect(resolveTheme("system", true)).toBe("light");
    expect(resolveTheme("system", false)).toBe("dark");
    expect(resolveTheme("light", false)).toBe("light");
    expect(resolveTheme("dark", true)).toBe("dark");
  });

it("cycles preference with visible change from system", () => {
    expect(nextThemePreference("system", "dark")).toBe("light");
    expect(nextThemePreference("system", "light")).toBe("dark");
    expect(nextThemePreference("light", "light")).toBe("dark");
    expect(nextThemePreference("dark", "dark")).toBe("system");
  });

  it("guards preference values", () => {
    expect(isThemePreference("dark")).toBe(true);
    expect(isThemePreference("neon")).toBe(false);
  });
});
