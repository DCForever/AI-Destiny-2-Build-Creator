/**
 * Weakened-test analysis (production gate logic under scripts/ci/).
 * Self-tests: test/ci/check-weakened-tests.self-test.mjs
 */
import { execSync } from "node:child_process";

export function stripComments(src) {
  let out = "";
  let i = 0;
  while (i < src.length) {
    if (src[i] === "/" && src[i + 1] === "/") {
      i += 2;
      while (i < src.length && src[i] !== "\n") i += 1;
      continue;
    }
    if (src[i] === "/" && src[i + 1] === "*") {
      i += 2;
      while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i += 1;
      i += 2;
      continue;
    }
    out += src[i++];
  }
  return out;
}

const ASSERT_RE = /\b(expectLater|expect|verify|assert\w*)\s*\(/;
/** skip: true | skip: 'reason' | @Skip | it.skip / test.skip / describe.skip */
const SKIP_WEAK_RE =
  /\bskip\s*:\s*(?:true\b|'[^']*'|"[^"]*")|@Skip\b|\b(?:it|test|describe)\.skip\s*\(/;
const NEGATIVE_ASSERT_RE =
  /\b(expectLater|expect|verify|assert\w*)\s*\([\s\S]{0,200}?\b(isFalse|isEmpty|throwsA|throws|refuse|ReadFailed|instanceNotOwned|doesNotFit|EnergyCostUnknown|notUnlocked|failClosed|isNull)\b/i;
const ROOT_EXISTS_PAD_RE =
  /\bexpect\s*\(\s*[A-Za-z_][\w.]*\.existsSync\s*\(\s*\)\s*,\s*(?:isTrue|true|equals\s*\(\s*true\s*\))\b/;
const PAD_REASON_RE = /\breason\s*:\s*['"]pad[^'"]*['"]/i;
/** Trivial never-fail pads: expect(1, 1) / expect(x, isNotNull). */
const TRIVIAL_PAD_RE =
  /\bexpect\s*\(\s*1\s*,\s*1\s*\)|\bexpect\s*\(\s*[A-Za-z_][\w.]*\s*,\s*isNotNull\b/;
/** Real import/export statements (after comment strip). Allows same-line exports. */
const REAL_IMPORT_RE =
  /(?:^|[;\n])\s*(?:import|export)\s+['"]([^'"]+)['"]/gm;

/**
 * Gate / CI paths — pattern sources here must set ci-runner, not fail tests.
 * Includes test/ci/ so gutting detector self-tests still flags review.
 */
export function isCiGatePath(path) {
  if (!path) return false;
  return (
    path.startsWith("scripts/ci/") ||
    path.startsWith(".github/") ||
    path.startsWith("test/ci/")
  );
}

/** @deprecated use isCiGatePath — test/ci/ is now a gate path. */
export function isDetectorSelfTestPath(path) {
  return isCiGatePath(path) && path.startsWith("test/ci/");
}

export function isTestPath(path) {
  if (!path) return false;
  if (isCiGatePath(path)) return false;
  if (/(^|\/)__tests__\//.test(path)) return true;
  if (/(^|\/)test(s)?\//.test(path)) return true;
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(path)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(path)) return true;
  return false;
}

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

const PACKAGE_LIB_ROOTS = {
  destiny2_windows_host: "flutter/apps/windows_host/lib",
  destiny2_web_host: "flutter/apps/web_host/lib",
  destiny2_mobile_host: "flutter/apps/mobile_host/lib",
  destiny2_app: "flutter/packages/app/lib",
  destiny2_domain: "flutter/packages/domain/lib",
  destiny2_bungie: "flutter/packages/bungie/lib",
  destiny2_db: "flutter/packages/db/lib",
  destiny2_storage: "flutter/packages/storage/lib",
  destiny2_manifest: "flutter/packages/manifest/lib",
  destiny2_ui_flutter: "flutter/packages/ui_flutter/lib",
  destiny2_ui_tokens: "flutter/packages/ui_tokens/lib",
  destiny2_sandbox_data: "flutter/packages/sandbox_data/lib",
};

/** Resolve Dart import URI → repo path, or null. */
export function resolveDartImportToRepoPath(importUri, fromPath = "") {
  if (!importUri) return null;
  const pkg = importUri.match(/^package:([^/]+)\/(.+)$/);
  if (pkg) {
    const root = PACKAGE_LIB_ROOTS[pkg[1]];
    return root ? `${root}/${pkg[2]}`.replace(/\\/g, "/") : null;
  }
  if (
    !(importUri.startsWith("./") || importUri.startsWith("../")) ||
    !fromPath
  ) {
    return null;
  }
  const parts = fromPath.replace(/\\/g, "/").split("/");
  parts.pop();
  for (const seg of importUri.split("/")) {
    if (seg === "." || seg === "") continue;
    if (seg === "..") parts.pop();
    else parts.push(seg);
  }
  return parts.join("/");
}

export function normalizeAssertForPadCompare(line) {
  return stripComments(line)
    .replace(/\breason\s*:\s*['"][^'"]*['"]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function countAsserts(line) {
  const clean = stripComments(line);
  const re = new RegExp(ASSERT_RE.source, "g");
  let n = 0;
  while (re.exec(clean)) n += 1;
  return n;
}

function detectLoosening(removed, added) {
  const tips = [];
  const rm = stripComments(removed);
  const ad = stripComments(added);
  if (
    /(?:==|equals\s*\(|toEqual\s*\()/.test(rm) &&
    !/(?:>=|greaterThanOrEqualTo|toBeGreaterThanOrEqual)/.test(rm) &&
    /(?:>=|greaterThanOrEqualTo|toBeGreaterThanOrEqual)/.test(ad)
  ) {
    tips.push("eq-to-gte");
  }
  if (/\bfindsOneWidget\b/.test(rm) && /\bfindsWidgets\b/.test(ad)) {
    tips.push("one-to-widgets");
  }
  if (/\bfindsNothing\b/.test(rm) && /\bfindsWidgets\b/.test(ad)) {
    tips.push("nothing-to-widgets");
  }
  return tips;
}

function flushHunkLoosening(removed, added, st) {
  for (const rm of removed) {
    for (const ad of added) {
      for (const tip of detectLoosening(rm, ad)) {
        st.loose.push(tip);
      }
    }
  }
}

/** Production paths deleted in this PR (non-test). */
export function deletedProductionPaths(nameStatusLines = []) {
  const out = [];
  for (const line of nameStatusLines) {
    if (!line.trim()) continue;
    const [status, ...rest] = line.split("\t");
    if (!status.startsWith("D")) continue;
    const path = rest[rest.length - 1];
    if (!path || isTestPath(path) || isCiGatePath(path)) continue;
    out.push(path.replace(/\\/g, "/"));
  }
  return out;
}

/** Top-level public names in a Dart library (as-of-base). */
export function extractDartPublicTopLevelNames(src) {
  const clean = stripComments(src || "");
  const names = new Set();
  const pats = [
    /^(?:(?:abstract|sealed|base|final|interface)\s+)*(?:class|enum|mixin|typedef|extension)\s+([A-Za-z_][\w]*)/gm,
    /^(?:(?:String|bool|int|double|num|void|dynamic|Object|Future|List|Map|Set|Iterable|Stream)\b[\w<>,\s?]*)\s+([a-zA-Z_][\w]*)\s*\(/gm,
    /^const\s+(?:[A-Za-z_][\w.<>?\s]*\s+)?([a-zA-Z_][\w]*)\s*=/gm,
  ];
  for (const re of pats) {
    let m;
    while ((m = re.exec(clean))) names.add(m[1]);
  }
  return names;
}

/** Direct deleted import, or barrel + use of a deleted file's public name. */
export function testImportsDeletedProduction(
  testPath,
  baseTestSource,
  deletedProd,
  readBaseFile,
) {
  const deleted = deletedProd instanceof Set ? deletedProd : new Set(deletedProd);
  if (!deleted.size || !baseTestSource) return false;
  const cleanSrc = stripComments(baseTestSource);
  const seen = new Set();
  const queue = [];
  const barrelDeleted = new Set();
  REAL_IMPORT_RE.lastIndex = 0;
  let m;
  while ((m = REAL_IMPORT_RE.exec(cleanSrc))) queue.push(m[1]);
  while (queue.length) {
    const uri = queue.shift();
    if (!uri || seen.has(uri)) continue;
    seen.add(uri);
    const resolved = resolveDartImportToRepoPath(uri, testPath);
    if (!resolved) continue;
    if (deleted.has(resolved)) return true;
    if (!readBaseFile || !/\.dart$/i.test(resolved)) continue;
    let barrel;
    try {
      barrel = readBaseFile(resolved);
    } catch {
      barrel = null;
    }
    if (!barrel) continue;
    const barrelClean = stripComments(barrel);
    REAL_IMPORT_RE.lastIndex = 0;
    let em;
    while ((em = REAL_IMPORT_RE.exec(barrelClean))) {
      if (!/\bexport\s+['"]/.test(em[0])) continue;
      const expUri = em[1];
      if (expUri.startsWith("package:")) {
        queue.push(expUri);
        continue;
      }
      const rel = resolveDartImportToRepoPath(
        expUri.startsWith(".") ? expUri : `./${expUri}`,
        resolved,
      );
      if (rel && deleted.has(rel)) barrelDeleted.add(rel);
      if (rel) seen.add(`path:${rel}`);
    }
  }
  if (!barrelDeleted.size || !readBaseFile) return false;
  for (const delPath of barrelDeleted) {
    let delSrc;
    try {
      delSrc = readBaseFile(delPath);
    } catch {
      delSrc = null;
    }
    if (!delSrc) continue;
    for (const name of extractDartPublicTopLevelNames(delSrc)) {
      if (name.length < 2) continue;
      const esc = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      if (new RegExp(`\\b${esc}\\b`).test(cleanSrc)) return true;
    }
  }
  return false;
}

/**
 * @param {string} diff
 * @param {string[]} [nameStatusLines]
 * @param {{ deletedProductionPaths?: string[], readBaseFile?: Function }} [options]
 */
export function analyzeWeakenedDiff(diff, nameStatusLines = [], options = {}) {
  const safety =
    /(skeptic_|fail_closed|ownership|guard|undo|apply_socket|cache_write|path_guard|no_dismantle)/i;
  const deletedProd = new Set(
    (options.deletedProductionPaths || deletedProductionPaths(nameStatusLines)).map(
      (p) => p.replace(/\\/g, "/"),
    ),
  );
  const readBaseFile = options.readBaseFile;
  const files = new Map();
  const state = (p) => {
    if (!files.has(p)) {
      files.set(p, {
        rm: 0,
        add: 0,
        loose: [],
        neg: false,
        skipWeak: false,
        hit: false,
        deletedFile: false,
        addedAssertLines: [],
      });
    }
    return files.get(p);
  };

  for (const line of nameStatusLines) {
    if (!line.trim()) continue;
    const [status, ...rest] = line.split("\t");
    if (status.startsWith("R") && rest.length >= 2) {
      const [from, to] = rest;
      if (isTestPath(from) && !isTestPath(to)) {
        const st = state(from);
        st.hit = true;
        st.rm += 1;
        st.loose.push("test-path-renamed-away");
      }
    }
    if (status.startsWith("D")) {
      const path = rest[rest.length - 1];
      if (isTestPath(path)) {
        const st = state(path);
        st.hit = true;
        st.rm += 1;
        st.deletedFile = true;
        st.loose.push("test-file-deleted");
      }
    }
  }

  let cur = null;
  let hunkRemoved = [];
  let hunkAdded = [];
  const endHunk = () => {
    if (cur && isTestPath(cur) && (hunkRemoved.length || hunkAdded.length)) {
      flushHunkLoosening(hunkRemoved, hunkAdded, state(cur));
    }
    hunkRemoved = [];
    hunkAdded = [];
  };

  for (const line of diff.split("\n")) {
    const m = line.match(/^diff --git a\/(.+) b\/(.+)$/);
    if (m) {
      endHunk();
      cur = m[2];
      continue;
    }
    if (line.startsWith("@@")) {
      endHunk();
      continue;
    }
    if (!cur || isCiGatePath(cur) || !isTestPath(cur)) continue;
    const st = state(cur);
    st.hit = true;
    if (line.startsWith("-") && !line.startsWith("---")) {
      const body = line.slice(1);
      st.rm += countAsserts(body);
      hunkRemoved.push(body);
    } else if (line.startsWith("+") && !line.startsWith("+++")) {
      const body = line.slice(1);
      const n = countAsserts(body);
      st.add += n;
      hunkAdded.push(body);
      if (n > 0) st.addedAssertLines.push(body);
      if (SKIP_WEAK_RE.test(stripComments(body))) st.skipWeak = true;
      if (NEGATIVE_ASSERT_RE.test(stripComments(body))) st.neg = true;
    }
  }
  endHunk();

  const findings = [];
  for (const [path, st] of files) {
    if (!st.hit || isCiGatePath(path)) continue;

    const padNorms = new Map();
    for (const al of st.addedAssertLines) {
      const clean = stripComments(al);
      if (!ASSERT_RE.test(clean)) continue;
      if (
        PAD_REASON_RE.test(clean) ||
        ROOT_EXISTS_PAD_RE.test(clean) ||
        TRIVIAL_PAD_RE.test(clean)
      ) {
        findings.push({
          path,
          kind: "padding-assert",
          detail: clean.trim().slice(0, 120),
        });
        continue;
      }
      const norm = normalizeAssertForPadCompare(al);
      if (!norm || !ASSERT_RE.test(norm)) continue;
      if (/^(expectLater|expect|verify|assert\w*)\s*\(\s*$/i.test(norm)) continue;
      if (norm.length < 24) continue;
      padNorms.set(norm, (padNorms.get(norm) || 0) + 1);
    }
    for (const [norm, count] of padNorms) {
      if (count >= 2) {
        findings.push({
          path,
          kind: "padding-assert",
          detail: `identical-assert-x${count}: ${norm.slice(0, 100)}`,
        });
      }
    }

    const dropped = st.rm > 0 && st.add - st.rm < 0;
    const fileDeleted = st.deletedFile || st.loose.includes("test-file-deleted");
    let retired = false;
    if ((dropped || fileDeleted) && deletedProd.size && readBaseFile) {
      let baseSrc = null;
      try {
        baseSrc = readBaseFile(path);
      } catch {
        baseSrc = null;
      }
      if (
        baseSrc &&
        testImportsDeletedProduction(path, baseSrc, deletedProd, readBaseFile)
      ) {
        retired = true;
        findings.push({
          path,
          kind: "retired-test",
          detail: fileDeleted
            ? "test-file-deleted; imported production file deleted in this PR"
            : `assert-drop rm ${st.rm} add ${st.add}; imported production file deleted in this PR`,
        });
      }
    }

    if (!retired && dropped) {
      findings.push({
        path,
        kind: "dropped-asserts",
        detail: `rm ${st.rm} add ${st.add}`,
      });
    }
    for (const tip of st.loose) {
      if (retired && tip === "test-file-deleted") continue;
      findings.push({ path, kind: "loosened-matcher", detail: tip });
    }
    if (st.skipWeak) {
      findings.push({
        path,
        kind: "test-weakening",
        detail: "added skip / @Skip / *.skip",
      });
    }
    if (safety.test(path) && st.hit && st.rm > 0 && !st.neg) {
      findings.push({
        path,
        kind: "safety-test-no-negative",
        detail: "changed safety test without a negative-case assert",
      });
    }
  }
  return findings;
}

/** retired-test is review-noted but non-blocking. */
export function failingWeakenedFindings(findings) {
  return findings.filter((f) => f.kind !== "retired-test");
}
