import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // Dart/Flutter/Jaspr workspace (not Next ESLint scope)
    "flutter/**",
    // Generated / vendored assets
    "public/destiny-icons/**",
    "docs/atlas/**",
  ]),
  {
    rules: {
      // Existing effects sync props/cache into local state; cascading-render risk
      // is accepted until those call sites are refactored to derived state.
      "react-hooks/set-state-in-effect": "off",
    },
  },
]);

export default eslintConfig;
