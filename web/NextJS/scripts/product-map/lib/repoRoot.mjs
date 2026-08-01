import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** Walk up until monorepo root (docs/product-map + flutter or .git). */
export function findRepoRoot(start = __dirname) {
  let dir = start;
  for (let i = 0; i < 12; i++) {
    const hasDocsMap = fs.existsSync(path.join(dir, "docs", "product-map"));
    const hasFlutter = fs.existsSync(path.join(dir, "flutter"));
    const hasGit = fs.existsSync(path.join(dir, ".git"));
    if (hasDocsMap && (hasFlutter || hasGit)) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  // Fallback: web/NextJS/scripts/<area>/lib → five levels up to monorepo
  return path.resolve(__dirname, "../../../../../");
}

export const REPO_ROOT = findRepoRoot();
