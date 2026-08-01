import fs from "node:fs";
import path from "node:path";
import { REPO_ROOT } from "./paths.mjs";
import { loadAllRules } from "./parse-rules.mjs";

/**
 * Escape special regex chars.
 * @param {string} s
 */
function esc(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Write updated rule body back to its source markdown.
 * Does not commit. Returns { ok, id, sourcePath, message }.
 *
 * @param {string} id
 * @param {string} body
 * @param {{ title?: string }} [opts]
 */
export function writeRuleBack(id, body, opts = {}) {
  const trimmed = String(body ?? "").replace(/\r\n/g, "\n").trim();
  if (!trimmed) {
    return { ok: false, id, message: "Body must not be empty" };
  }

  const { byId } = loadAllRules();
  const rule = byId.get(id);
  if (!rule) {
    return { ok: false, id, message: `Unknown rule id: ${id}` };
  }

  const abs = path.isAbsolute(rule.sourcePath)
    ? rule.sourcePath
    : path.join(REPO_ROOT, rule.sourcePath);

  if (!fs.existsSync(abs)) {
    return { ok: false, id, message: `Source missing: ${rule.sourcePath}` };
  }

  let text = fs.readFileSync(abs, "utf8");
  const orig = text;

  if (rule.layer === "dac") {
    text = writeDac(text, id, trimmed, opts.title ?? rule.title, rule.refs);
  } else if (rule.layer === "dbr" || rule.layer === "br") {
    text = writeTableRow(text, id, trimmed);
  } else if (rule.layer === "slice") {
    text = writeSlice(text, id, trimmed, rule);
  } else {
    return { ok: false, id, message: `Unsupported layer: ${rule.layer}` };
  }

  if (text === orig) {
    return {
      ok: false,
      id,
      sourcePath: rule.sourcePath,
      message: "No change applied (pattern not found or content identical)",
    };
  }

  fs.writeFileSync(abs, text, "utf8");
  return {
    ok: true,
    id,
    sourcePath: rule.sourcePath,
    message: "Updated (not committed)",
  };
}

/**
 * @param {string} text
 * @param {string} id
 * @param {string} body
 * @param {string} title
 * @param {string} [refs]
 */
function writeDac(text, id, body, title, refs) {
  const headingRe = new RegExp(
    `^(### ${esc(id)}\\s*[—–-]\\s*).+$`,
    "m",
  );
  if (!headingRe.test(text)) {
    return text;
  }
  // Replace heading title if provided
  text = text.replace(headingRe, `$1${title}`);

  const blockRe = new RegExp(
    `(### ${esc(id)}\\s*[—–-]\\s*.+\\n)([\\s\\S]*?)(?=\\n### |\\n## |\\n---|$)`,
  );
  const m = text.match(blockRe);
  if (!m) return text;

  let newBlock = body.trim() + "\n";
  if (refs) {
    newBlock += `\n**Refs**: ${refs}\n`;
  } else {
    // preserve existing Refs line if body omitted it
    const oldRefs = m[2].match(/\*\*Refs\*\*:\s*(.+)/);
    if (oldRefs && !/\*\*Refs\*\*:/.test(body)) {
      newBlock += `\n**Refs**: ${oldRefs[1].trim()}\n`;
    }
  }

  return text.replace(blockRe, `$1\n${newBlock}\n`);
}

/**
 * @param {string} text
 * @param {string} id
 * @param {string} ruleText
 */
function writeTableRow(text, id, ruleText) {
  // Preserve other columns after rule cell
  const rowRe = new RegExp(
    `^(\\|\\s*${esc(id)}\\s*\\|\\s*)([^|]+)(\\|.*)$`,
    "m",
  );
  if (!rowRe.test(text)) {
    // 2-column table variant
    const row2 = new RegExp(
      `^(\\|\\s*${esc(id)}\\s*\\|\\s*)([^|]+)(\\s*\\|\\s*)$`,
      "m",
    );
    if (row2.test(text)) {
      return text.replace(row2, `$1${ruleText} $3`);
    }
    return text;
  }
  // Keep trailing spaces style: " rule | FR |"
  return text.replace(rowRe, `$1${ruleText} $3`);
}

/**
 * @param {string} text
 * @param {string} id - e.g. 001:SC-001 or 001:US1-AS1
 * @param {string} body
 * @param {import("./parse-rules.mjs").RuleRecord} rule
 */
function writeSlice(text, id, body, rule) {
  const local = id.includes(":") ? id.split(":").slice(1).join(":") : id;

  // SC-001
  const sc = local.match(/^(SC-\d+)$/);
  if (sc) {
    const oneLine = body.replace(/\s*\n\s*/g, " ").trim();
    const boldRe = new RegExp(
      `^(-\\s*\\*\\*${esc(sc[1])}\\*\\*:\\s*).+$`,
      "m",
    );
    if (boldRe.test(text)) {
      return text.replace(boldRe, `$1${oneLine}`);
    }
    const plainRe = new RegExp(`^(${esc(sc[1])})\\s+.+$`, "m");
    if (plainRe.test(text)) {
      return text.replace(plainRe, `$1 ${oneLine}`);
    }
    return text;
  }

  // US1-AS2
  const usAs = local.match(/^US(\d+)-AS(\d+)$/);
  if (usAs) {
    const storyNum = usAs[1];
    const asNum = usAs[2];
    const storyRe = new RegExp(
      `(###\\s+User Story\\s+${storyNum}[^\\n]*\\n)([\\s\\S]*?)(?=\\n###\\s+User Story|\\n##\\s|$)`,
      "i",
    );
    const sm = text.match(storyRe);
    if (!sm) return text;
    const storyBody = sm[2];
    const asRe = new RegExp(
      `(^${asNum}\\.\\s+)([\\s\\S]*?)(?=^\\d+\\.\\s+\\*\\*Given\\*\\*|\\*\\*Independent|\\*\\*Why|^###\\s|^##\\s|$)`,
      "m",
    );
    if (!asRe.test(storyBody)) return text;
    const newStoryBody = storyBody.replace(asRe, `$1${body.trim()}\n\n`);
    return text.replace(storyRe, `$1${newStoryBody}`);
  }

  // Generic AC heading
  const ac = local.match(/^((?:AC|SC)-[A-Z0-9-]+)$/);
  if (ac) {
    const blockRe = new RegExp(
      `(#{2,4}\\s+${esc(ac[1])}[^\\n]*\\n)([\\s\\S]*?)(?=\\n#{2,4}\\s|$)`,
    );
    if (!blockRe.test(text)) return text;
    return text.replace(blockRe, `$1\n${body.trim()}\n\n`);
  }

  return text;
}
