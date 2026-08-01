import path from "node:path";
import { findRepoRoot } from "./repoRoot.mjs";

/** Repo root (Destiny2BuildCreator monorepo). */
export const REPO_ROOT = findRepoRoot();

export const SPECS_DIR = path.join(REPO_ROOT, "specs");
export const DOMAIN_AC_PATH = path.join(SPECS_DIR, "domain-acceptance-criteria.md");
export const DOMAIN_BR_PATH = path.join(SPECS_DIR, "domain-business-rules.md");
export const FEATURE_BR_PATH = path.join(SPECS_DIR, "business-rules.md");

export const UI_RULES_DIR = path.join(REPO_ROOT, "docs", "ui-rules");
export const INVENTORY_PATH = path.join(UI_RULES_DIR, "inventory.yaml");
export const DRAWIO_PATH = path.join(UI_RULES_DIR, "ui-map.drawio");
export const COMPANION_DIR = path.join(UI_RULES_DIR, "companion");
/** Reverse map Atlas screen id → inventory node (served with Atlas). */
export const ATLAS_UI_RULES_LINKS_PATH = path.join(
  REPO_ROOT,
  "docs",
  "atlas",
  "ui-rules-links.json",
);
