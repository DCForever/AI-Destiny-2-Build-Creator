import fs from "node:fs";
import path from "node:path";
import {
  DOMAIN_AC_PATH,
  DOMAIN_BR_PATH,
  FEATURE_BR_PATH,
  SPECS_DIR,
} from "./paths.mjs";

/**
 * @typedef {object} RuleRecord
 * @property {string} id
 * @property {string} layer - dac | dbr | br | slice
 * @property {string} title
 * @property {string} body - full editable text (for DAC/slice: GWT body; for tables: rule cell)
 * @property {string} sourcePath - repo-relative path
 * @property {string} [section]
 * @property {string} [refs]
 */

/**
 * @param {string} abs
 * @returns {string}
 */
function rel(abs) {
  return path.relative(process.cwd(), abs).replace(/\\/g, "/");
}

/**
 * Parse DAC-* blocks from domain-acceptance-criteria.md
 * @param {string} text
 * @param {string} sourcePath
 * @returns {RuleRecord[]}
 */
export function parseDac(text, sourcePath) {
  const rules = [];
  // IDs may include letter suffixes (e.g. DAC-P2-001a)
  const re =
    /^### (DAC-[A-Za-z0-9-]+)\s*[—–-]\s*(.+)\s*$/gm;
  const matches = [...text.matchAll(re)];
  for (let i = 0; i < matches.length; i++) {
    const m = matches[i];
    const id = m[1];
    const title = m[2].trim();
    const start = m.index + m[0].length;
    const end = i + 1 < matches.length ? matches[i + 1].index : text.length;
    let body = text.slice(start, end).trim();
    // Drop trailing --- separators
    body = body.replace(/\n---+\s*$/, "").trim();
    let refs = "";
    const refsMatch = body.match(/\*\*Refs\*\*:\s*(.+)$/m);
    if (refsMatch) {
      refs = refsMatch[1].trim();
      body = body.replace(/\n?\*\*Refs\*\*:\s*.+$/m, "").trim();
    }
    rules.push({
      id,
      layer: "dac",
      title,
      body,
      sourcePath,
      refs,
    });
  }
  return rules;
}

/**
 * Parse table rows | ID | Rule | ... | for DBR-* or BR-*
 * @param {string} text
 * @param {string} sourcePath
 * @param {"dbr"|"br"} layer
 * @param {RegExp} idPattern
 * @returns {RuleRecord[]}
 */
export function parseTableRules(text, sourcePath, layer, idPattern) {
  const rules = [];
  let section = "";
  const lines = text.split(/\r?\n/);
  for (const line of lines) {
    const h = line.match(/^##\s+(.+)/);
    if (h) {
      section = h[1].trim();
      continue;
    }
    // | DBR-XXX | rule text | optional FR col |
    if (!line.startsWith("|")) continue;
    const cells = splitTableRow(line);
    if (cells.length < 2) continue;
    const id = cells[0].trim();
    if (!idPattern.test(id)) continue;
    if (id === "ID" || id.startsWith("---") || id.startsWith("**")) continue;
    const ruleText = cells[1].trim();
    if (!ruleText || ruleText === "Rule") continue;
    rules.push({
      id,
      layer,
      title: id,
      body: ruleText,
      sourcePath,
      section,
    });
  }
  return rules;
}

/**
 * @param {string} line
 * @returns {string[]}
 */
function splitTableRow(line) {
  // strip leading/trailing |
  let s = line.trim();
  if (s.startsWith("|")) s = s.slice(1);
  if (s.endsWith("|")) s = s.slice(0, -1);
  return s.split("|").map((c) => c.trim());
}

/**
 * Parse slice specs for SC-* and numbered acceptance scenarios.
 * @param {string} text
 * @param {string} sourcePath
 * @param {string} sliceId - e.g. 001-build-sets-synergies
 * @returns {RuleRecord[]}
 */
export function parseSliceSpec(text, sourcePath, sliceId) {
  const rules = [];
  const short = sliceId.replace(/^(\d+).*/, "$1");

  // Success criteria variants:
  // - **SC-001**: text
  // SC-001 text (plain checklist style)
  const scRe = /^-\s*\*\*(SC-\d+)\*\*:\s*(.+)$/gm;
  for (const m of text.matchAll(scRe)) {
    const scId = m[1];
    const id = `${short}:${scId}`;
    rules.push({
      id,
      layer: "slice",
      title: `${sliceId} ${scId}`,
      body: m[2].trim(),
      sourcePath,
      section: "Success Criteria",
    });
  }
  const scPlain = /^(SC-\d+)\s+(.+)$/gm;
  for (const m of text.matchAll(scPlain)) {
    const scId = m[1];
    const id = `${short}:${scId}`;
    if (rules.some((r) => r.id === id)) continue;
    rules.push({
      id,
      layer: "slice",
      title: `${sliceId} ${scId}`,
      body: m[2].trim(),
      sourcePath,
      section: "Success Criteria",
    });
  }

  // Acceptance scenarios under user stories
  // **Acceptance Scenarios**: then numbered 1. **Given** ...
  const storyRe =
    /^###\s+(User Story\s+(\d+)[^\n]*)\s*$/gim;
  const stories = [...text.matchAll(storyRe)];
  for (let si = 0; si < stories.length; si++) {
    const storyTitle = stories[si][1].trim();
    const storyNum = stories[si][2];
    const start = stories[si].index + stories[si][0].length;
    const end =
      si + 1 < stories.length ? stories[si + 1].index : text.length;
    const block = text.slice(start, end);
    const accIdx = block.search(/\*\*Acceptance Scenarios\*\*/i);
    if (accIdx < 0) continue;
    const after = block.slice(accIdx);
    // Numbered scenarios: 1. **Given** ... until blank line + non-continuation or next number
    const scenRe =
      /^(\d+)\.\s+(\*\*Given\*\*[\s\S]*?)(?=^\d+\.\s+\*\*Given\*\*|^###\s|^##\s|^---|\*\*Independent|\*\*Why|\Z)/gim;
    // Simpler: split by numbered Given lines
    const givenStarts = [...after.matchAll(/^(\d+)\.\s+(\*\*Given\*\*.+)$/gim)];
    for (let gi = 0; gi < givenStarts.length; gi++) {
      const num = givenStarts[gi][1];
      const lineStart = givenStarts[gi].index;
      const lineEnd =
        gi + 1 < givenStarts.length
          ? givenStarts[gi + 1].index
          : after.length;
      let body = after.slice(lineStart, lineEnd).trim();
      // Remove leading "N. "
      body = body.replace(/^\d+\.\s+/, "").trim();
      // Stop at Independent Test / Why this priority
      body = body
        .replace(/\n\*\*(Independent Test|Why this priority)[\s\S]*$/i, "")
        .trim();
      const id = `${short}:US${storyNum}-AS${num}`;
      rules.push({
        id,
        layer: "slice",
        title: `${storyTitle} — AS ${num}`,
        body,
        sourcePath,
        section: storyTitle,
      });
    }
  }

  // Standalone ### AC- or #### Acceptance
  const acHeading =
    /^#{2,4}\s+((?:AC|SC)-[A-Z0-9-]+)\s*[—–-]?\s*(.*)$/gm;
  for (const m of text.matchAll(acHeading)) {
    const rawId = m[1];
    const title = (m[2] || rawId).trim();
    const id = `${short}:${rawId}`;
    if (rules.some((r) => r.id === id)) continue;
    const start = m.index + m[0].length;
    const next = text.slice(start).search(/^#{2,4}\s+/m);
    const body = text
      .slice(start, next >= 0 ? start + next : text.length)
      .trim()
      .replace(/\n---+\s*$/, "")
      .trim();
    rules.push({
      id,
      layer: "slice",
      title,
      body,
      sourcePath,
      section: "Acceptance",
    });
  }

  return rules;
}

/**
 * Load and parse all rule sources.
 * @returns {{ rules: RuleRecord[], byId: Map<string, RuleRecord> }}
 */
export function loadAllRules() {
  /** @type {RuleRecord[]} */
  const rules = [];

  if (fs.existsSync(DOMAIN_AC_PATH)) {
    const text = fs.readFileSync(DOMAIN_AC_PATH, "utf8");
    rules.push(...parseDac(text, rel(DOMAIN_AC_PATH)));
  }
  if (fs.existsSync(DOMAIN_BR_PATH)) {
    const text = fs.readFileSync(DOMAIN_BR_PATH, "utf8");
    rules.push(
      ...parseTableRules(text, rel(DOMAIN_BR_PATH), "dbr", /^DBR-[A-Z0-9-]+$/),
    );
  }
  if (fs.existsSync(FEATURE_BR_PATH)) {
    const text = fs.readFileSync(FEATURE_BR_PATH, "utf8");
    rules.push(
      ...parseTableRules(text, rel(FEATURE_BR_PATH), "br", /^BR-[A-Z0-9-]+$/),
    );
  }

  if (fs.existsSync(SPECS_DIR)) {
    for (const ent of fs.readdirSync(SPECS_DIR, { withFileTypes: true })) {
      if (!ent.isDirectory()) continue;
      const sliceId = ent.name;
      // only numbered feature slices
      if (!/^\d{3}-/.test(sliceId) && !/^\d{3}$/.test(sliceId)) continue;
      const specPath = path.join(SPECS_DIR, sliceId, "spec.md");
      if (!fs.existsSync(specPath)) continue;
      const text = fs.readFileSync(specPath, "utf8");
      rules.push(...parseSliceSpec(text, rel(specPath), sliceId));
    }
  }

  const byId = new Map();
  for (const r of rules) {
    if (byId.has(r.id)) {
      // Prefer non-slice or first; keep first
      continue;
    }
    byId.set(r.id, r);
  }

  return { rules: [...byId.values()], byId };
}

/**
 * Expand inventory rule refs like "DBR-EQP-001–008" into individual IDs when possible.
 * Also accepts plain IDs and slice IDs.
 * @param {string[]} refs
 * @param {Map<string, RuleRecord>} byId
 * @returns {string[]}
 */
export function expandRuleRefs(refs, byId) {
  const out = new Set();
  for (const raw of refs ?? []) {
    const ref = String(raw).trim();
    if (!ref) continue;
    if (byId.has(ref)) {
      out.add(ref);
      continue;
    }
    // Range: DBR-EQP-001–008 or DBR-EQP-001-008
    const range = ref.match(
      /^(DBR|BR|DAC)-([A-Z]+)-(\d+)[–—-](\d+)$/,
    );
    if (range) {
      const [, kind, mid, a, b] = range;
      const start = Number(a);
      const end = Number(b);
      const pad = a.length;
      for (let n = start; n <= end; n++) {
        const id = `${kind}-${mid}-${String(n).padStart(pad, "0")}`;
        if (byId.has(id)) out.add(id);
        else out.add(id); // keep even if missing for visibility
      }
      continue;
    }
    // Prefix pack: DBR-SYN-* — expand known
    if (ref.endsWith("-*") || ref.endsWith("-*")) {
      const prefix = ref.replace(/\*$/, "");
      for (const id of byId.keys()) {
        if (id.startsWith(prefix)) out.add(id);
      }
      continue;
    }
    out.add(ref);
  }
  return [...out];
}
