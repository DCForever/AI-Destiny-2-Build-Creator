#!/usr/bin/env node
/**
 * Label production-diff size (exclude top-level docs/test + named tests)
 * and risk flags. Fail closed on a missing base ref.
 * Self-tests live in test/ci/ (excluded from size).
 */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import { basename } from "node:path";
import { fileURLToPath } from "node:url";

const SMALL = 300;

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

/**
 * Exclude only top-level docs/test trees + named test files.
 * Nested docs/, fixtures/, test/, tests/, or bare *.md must NOT hide production.
 */
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

/**
 * @param {{
 *   numstat: string,
 *   nameStatus: string,
 *   prodPatch: string,
 *   testPatch: string,
 *   allPaths: string[],
 * }} input
 */
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
  if (
    /findsOneWidget[\s\S]{0,120}findsWidgets/.test(input.testPatch) ||
    /(?:==|equals\s*\()[\s\S]{0,80}(?:>=|greaterThanOrEqualTo)/.test(
      input.testPatch,
    ) ||
    /\bskip\s*:\s*true\b/.test(input.testPatch)
  ) {
    flags.add("test-weakening");
  }

  const size = added <= SMALL ? "Small" : "Large";
  return { added, deleted, prod, flags: [...flags].sort(), size };
}

function main() {
  const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
  const base = resolveBase(preferred);
  const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
  const numstat = sh(`git diff --numstat ${base}...HEAD`);
  const nameStatus = sh(`git diff --name-status ${base}...HEAD`);
  const allPaths = [];
  for (const line of nameStatus.split("\n")) {
    if (!line.trim()) continue;
    const parts = line.split("\t");
    allPaths.push(parts[parts.length - 1]);
  }
  const prodPaths = allPaths.filter((p) => !isExcludedFromProduction(p));
  const testPaths = allPaths.filter((p) => isTestPath(p));
  const prodPatch = prodPaths.length
    ? sh(`git diff ${base}...HEAD -- ${prodPaths.map((p) => JSON.stringify(p)).join(" ")}`)
    : "";
  const testPatch = testPaths.length
    ? sh(`git diff ${base}...HEAD -- ${testPaths.map((p) => JSON.stringify(p)).join(" ")}`)
    : "";
  const { added, deleted, prod, flags, size } = measureSizeRisk({
    numstat,
    nameStatus,
    prodPatch,
    testPatch,
    allPaths,
  });
  const labels = [`size/${size.toLowerCase()}`, ...flags.map((f) => `risk/${f}`)];
  const summary = [
    "## Size / risk labels",
    "",
    `Base: \`${base}\``,
    "",
    `- Production added lines (exclude tests + docs): **${added}**`,
    `- Production deleted lines: **${deleted}**`,
    `- Size: **${size}** (Small ≤ ${SMALL})`,
    `- Flags: ${flags.length ? flags.map((f) => `\`${f}\``).join(", ") : "_none_"}`,
    `- Label hints: ${labels.map((l) => `\`${l}\``).join(", ")}`,
    "",
    prod.length
      ? `Production files (${prod.length}):\n${prod.map((f) => `- \`${f}\``).join("\n")}`
      : "No production files in diff.",
    "",
  ].join("\n");
  if (process.env.GITHUB_STEP_SUMMARY) {
    writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
  }
  console.log(summary);
  console.log(`SIZE=${size}`);
  console.log(`ADDED=${added}`);
  console.log(`FLAGS=${flags.join(",")}`);
  console.log(`LABELS=${labels.join(",")}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
