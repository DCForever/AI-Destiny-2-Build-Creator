/** Shared size/risk measurement (imported by scripts/ci + self-tests). */
import { execSync } from "node:child_process";
import { basename } from "node:path";

export const SMALL = 300;

export function resolveBase(preferred) {
  const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
  try {
    sh(`git rev-parse --verify ${preferred}`);
    return preferred;
  } catch {
    throw new Error(
      `Base ref missing or unresolvable: ${preferred} (fail closed; no HEAD~1 fallback)`,
    );
  }
}

/** Top-level docs/test + named tests only — nested docs/fixtures/*.md do not hide prod. */
export function isExcludedFromProduction(path) {
  if (!path) return true;
  if (/^docs(\/|$)/.test(path)) return true;
  if (/^docs-site(\/|$)/.test(path)) return true;
  if (/^test(\/|$)/.test(path)) return true;
  if (/^tests(\/|$)/.test(path)) return true;
  if (/(^|\/)__tests__\//.test(path)) return true;
  const name = basename(path);
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(name)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(name)) return true;
  return false;
}

export function isTestPath(path) {
  if (!path) return false;
  if (/(^|\/)__tests__\//.test(path)) return true;
  if (/(^|\/)test(s)?\//.test(path)) return true;
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(path)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(path)) return true;
  return false;
}

export function measureSizeRisk(input) {
  let added = 0;
  let deleted = 0;
  const prod = [];
  const gone = [];
  for (const line of input.numstat.split("\n")) {
    if (!line.trim()) continue;
    const [a, d, path] = line.split("\t");
    if (isExcludedFromProduction(path)) continue;
    prod.push(path);
    if (a !== "-") added += Number.parseInt(a, 10) || 0;
    if (d !== "-") deleted += Number.parseInt(d, 10) || 0;
  }
  for (const line of input.nameStatus.split("\n")) {
    if (!line.trim()) continue;
    const [status, ...rest] = line.split("\t");
    const path = rest[rest.length - 1];
    if (!isExcludedFromProduction(path) && status.startsWith("D")) gone.push(path);
  }

  const flags = new Set();
  const allPaths = input.allPaths || prod;
  if (
    allPaths.some((p) => p.startsWith(".github/") || p.startsWith("scripts/ci/"))
  ) {
    flags.add("ci-runner");
  }
  if (gone.length || /\b(dismantle|DeleteItem)\b/.test(input.prodPatch)) {
    flags.add("deletes");
  }
  if (/(migration|schemaVersion|ALTER TABLE)/i.test(input.prodPatch)) {
    flags.add("migrations");
  }
  if (
    /\b(EquipItems?|TransferItem|InsertSocketPlugFree)\b/.test(input.prodPatch) ||
    /[Dd]:\\| [Ee]:\\| [Zz]:\\|\/Volumes\//.test(input.prodPatch)
  ) {
    flags.add("dest-write");
  }
  if (
    /(CLIENT_SECRET|SESSION_SECRET|Bearer\s|refresh[_-]?token|access[_-]?token|token[_-]?store|api[_-]?key)/i.test(
      input.prodPatch,
    )
  ) {
    flags.add("auth-secrets");
  }
  if (
    /(0\.0\.0\.0|HttpServer\.bind|listen\(|HOST\s*=)/i.test(input.prodPatch)
  ) {
    flags.add("network-bind");
  }
  // Patterns built in pieces so this lib file is not itself flagged.
  const skipTrue = new RegExp("\\b" + "skip\\s*:\\s*" + "true\\b");
  const oneToMany = new RegExp(
    "finds" + "OneWidget[\\s\\S]{0,120}finds" + "Widgets",
  );
  const eqToGte = new RegExp(
    "(?:" + "==|equals\\s*\\(" + ")[\\s\\S]{0,80}(?:" + ">=|greaterThanOrEqualTo)",
  );
  if (
    oneToMany.test(input.testPatch) ||
    eqToGte.test(input.testPatch) ||
    skipTrue.test(input.testPatch)
  ) {
    flags.add("test-weakening");
  }

  return {
    added,
    deleted,
    prod,
    flags: [...flags].sort(),
    size: added <= SMALL ? "Small" : "Large",
  };
}
