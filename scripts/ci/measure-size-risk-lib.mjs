/**
 * Size/risk measurement (production gate logic under scripts/ci/).
 * Self-tests: test/ci/measure-size-risk.self-test.mjs
 */
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

/** Gate / CI paths — always set ci-runner; pattern source allowlisted. */
export function isCiGatePath(path) {
  if (!path) return false;
  return path.startsWith("scripts/ci/") || path.startsWith(".github/");
}

/** Intentional detector fixtures — excluded from test-weakening content scan. */
export function isDetectorSelfTestPath(path) {
  return /^test\/ci\/.*\.self-test\.mjs$/.test(path || "");
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
  if (isCiGatePath(path)) return false;
  if (isDetectorSelfTestPath(path)) return false;
  if (/(^|\/)__tests__\//.test(path)) return true;
  if (/(^|\/)test(s)?\//.test(path)) return true;
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(path)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(path)) return true;
  return false;
}

/** Keep only +/- body lines; drop context and file headers. */
export function addedOrRemovedBodies(patch) {
  const out = [];
  for (const line of patch.split("\n")) {
    if (line.startsWith("+++") || line.startsWith("---")) continue;
    if (line.startsWith("+") || line.startsWith("-")) out.push(line.slice(1));
  }
  return out.join("\n");
}

/**
 * Drop unified-diff hunks for CI gate libs (ci-runner allowlist) and
 * detector self-tests that intentionally embed pattern fixtures.
 */
export function stripCiGateHunks(patch) {
  const lines = patch.split("\n");
  const keep = [];
  let skip = false;
  for (const line of lines) {
    const m = line.match(/^diff --git a\/(.+) b\/(.+)$/);
    if (m) {
      skip = isCiGatePath(m[2]) || isDetectorSelfTestPath(m[2]);
      if (!skip) keep.push(line);
      continue;
    }
    if (!skip) keep.push(line);
  }
  return keep.join("\n");
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
  if (allPaths.some((p) => isCiGatePath(p))) {
    flags.add("ci-runner");
  }
  // Content flags ignore scripts/ci detector source (still counted for size + ci-runner).
  const productScan = stripCiGateHunks(input.prodPatch || "");
  if (gone.length || /\b(dismantle|DeleteItem)\b/.test(productScan)) {
    flags.add("deletes");
  }
  if (/(migration|schemaVersion|ALTER TABLE)/i.test(productScan)) {
    flags.add("migrations");
  }
  if (
    /\b(EquipItems?|TransferItem|InsertSocketPlugFree)\b/.test(productScan) ||
    /[Dd]:\\| [Ee]:\\| [Zz]:\\|\/Volumes\//.test(productScan)
  ) {
    flags.add("dest-write");
  }
  if (
    /(CLIENT_SECRET|SESSION_SECRET|Bearer\s|refresh[_-]?token|access[_-]?token|token[_-]?store|api[_-]?key)/i.test(
      productScan,
    )
  ) {
    flags.add("auth-secrets");
  }
  if (/(0\.0\.0\.0|HttpServer\.bind|listen\(|HOST\s*=)/i.test(productScan)) {
    flags.add("network-bind");
  }

  const testScan = addedOrRemovedBodies(stripCiGateHunks(input.testPatch || ""));
  const SKIP_WEAK_RE =
    /\bskip\s*:\s*(?:true\b|'[^']*'|"[^"]*")|@Skip\b|\b(?:it|test|describe)\.skip\s*\(/;
  if (
    /findsOneWidget[\s\S]{0,120}findsWidgets/.test(testScan) ||
    /(?:==|equals\s*\(|toEqual\s*\()[\s\S]{0,80}(?:>=|greaterThanOrEqualTo|toBeGreaterThanOrEqual)/.test(
      testScan,
    ) ||
    SKIP_WEAK_RE.test(testScan)
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
