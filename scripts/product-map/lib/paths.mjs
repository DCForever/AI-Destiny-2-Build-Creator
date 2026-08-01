import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const REPO_ROOT = path.resolve(__dirname, "../../..");
export const PRODUCT_MAP_DIR = path.join(REPO_ROOT, "docs", "product-map");
export const META_PATH = path.join(PRODUCT_MAP_DIR, "meta.yaml");
export const PLATFORMS_PATH = path.join(PRODUCT_MAP_DIR, "platforms.yaml");
export const SURFACES_PATH = path.join(PRODUCT_MAP_DIR, "surfaces.yaml");
export const FLOWS_PATH = path.join(PRODUCT_MAP_DIR, "flows.yaml");
export const TRANSITIONS_PATH = path.join(PRODUCT_MAP_DIR, "transitions.yaml");

export const UI_RULES_DIR = path.join(REPO_ROOT, "docs", "ui-rules");
export const INVENTORY_PATH = path.join(UI_RULES_DIR, "inventory.yaml");
export const DRAWIO_PATH = path.join(UI_RULES_DIR, "ui-map.drawio");

export const ATLAS_DIR = path.join(REPO_ROOT, "docs", "atlas");
export const ATLAS_MANIFEST_PATH = path.join(ATLAS_DIR, "manifest.json");
export const ATLAS_LINKS_PATH = path.join(ATLAS_DIR, "ui-rules-links.json");
