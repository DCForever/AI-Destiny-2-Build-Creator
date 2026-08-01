import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { resolveVerbSubType, SYNERGY_VERB_NAMES } from "@/data/synergyVerbs";
import {
  normalizeDesignationKey,
  singularizeKeywordLabel,
} from "@/lib/synergies/existingDesignations";

export type KeywordSourceHit = {
  store: string;
  hash?: number;
  name: string;
  /** Short quote from the object text around the keyword. */
  snippet: string;
};

export type DiscoveredKeyword = {
  /** Canonical display form for a verb/element designation. */
  keyword: string;
  /** How we treat it for library creation. */
  kind: "verb" | "element";
  /** Curated vocabulary vs extracted from object text. */
  origin: "curated" | "object_text";
  mentionCount: number;
  /** First N object references with snippets (default cap 10). */
  sampleObjects: KeywordSourceHit[];
};

/** Minimum references retained per keyword for the UI. */
export const KEYWORD_REFERENCE_LIMIT = 10;

/**
 * Extract a readable snippet around the first match of `keyword` in `text`.
 */
export function snippetAroundKeyword(
  text: string,
  keyword: string,
  radius = 70,
): string {
  const flat = text.replace(/\s+/g, " ").trim();
  if (!flat) return "";
  const lower = flat.toLowerCase();
  const elite = resolveEliteCombatant(keyword);
  const forms = [
    keyword.toLowerCase(),
    keyword.toLowerCase().replace(/s$/, ""),
    `${keyword.toLowerCase()}s`,
    // Alias forms for elite combatants (Miniboss → mini-bosses, etc.)
    ...(elite
      ? (ELITE_COMBATANT_TERMS.find((t) => t.canonical === elite)?.patterns ?? [])
      : []),
  ];
  let idx = -1;
  let matchLen = keyword.length;
  for (const form of forms) {
    if (!form) continue;
    const at = lower.indexOf(form);
    if (at >= 0) {
      idx = at;
      matchLen = form.length;
      break;
    }
  }
  if (idx < 0) {
    const cut = flat.slice(0, radius * 2);
    return cut.length < flat.length ? `${cut}…` : cut;
  }
  const start = Math.max(0, idx - radius);
  const end = Math.min(flat.length, idx + matchLen + radius);
  const body = flat.slice(start, end).trim();
  return `${start > 0 ? "…" : ""}${body}${end < flat.length ? "…" : ""}`;
}

function sampleKey(hit: KeywordSourceHit): string {
  return `${hit.store}:${hit.hash ?? ""}:${hit.name}`;
}

const STOPWORDS = new Set(
  [
    "the",
    "and",
    "for",
    "with",
    "from",
    "this",
    "that",
    "when",
    "while",
    "your",
    "you",
    "are",
    "was",
    "were",
    "been",
    "have",
    "has",
    "had",
    "into",
    "onto",
    "over",
    "under",
    "after",
    "before",
    "between",
    "against",
    "about",
    "which",
    "their",
    "them",
    "they",
    "than",
    "then",
    "also",
    "only",
    "more",
    "most",
    "each",
    "other",
    "some",
    "such",
    "including",
    "grants",
    "grant",
    "causes",
    "cause",
    "deals",
    "deal",
    "damage",
    "ability",
    "abilities",
    "weapon",
    "weapons",
    // note: "armor" is FRAGMENT only (bare Armor ignored; "Armor Charge" kept)
    "target",
    "targets",
    "enemy",
    "enemies",
    "allies",
    "ally",
    "player",
    "guardians",
    "guardian",
    "final",
    "blows",
    "blow",
    "kills",
    "kill",
    "seconds",
    "second",
    "stacks",
    "stack",
    "bonus",
    "increased",
    "increases",
    "decrease",
    "decreased",
    "additional",
    "while",
    "using",
    "equipped",
    "perk",
    "perks",
    "mod",
    "mods",
    "item",
    "items",
    "effect",
    "effects",
    "status",
    "combat",
    "power",
    "energy",
    "kinetic",
    "primary",
    "special",
    "heavy",
    "class",
    "type",
    "types",
    "based",
    "nearby",
    "around",
    "within",
    "maximum",
    "minimum",
    "total",
    "chance",
    "percent",
    "duration",
    "cooldown",
    "reload",
    "magazine",
    "range",
    "handling",
    "stability",
    "precision",
    "critical",
    "body",
    "shot",
    "shots",
    "fire",
    "rate",
    // sentence-leading / connective verbs that stick to Title-Case runs
    "gains",
    "grants",
    "gain",
    "grant",
    "collecting",
    "collect",
    "defeating",
    "defeat",
    "picking",
    "taking",
    "dealing",
    "causing",
    "while",
    "after",
    "before",
    "during",
    "using",
    "when",
    "your",
    "this",
    "that",
    "with",
  ].map((w) => w.toLowerCase()),
);

/**
 * Incomplete / generic words that only matter as part of a multi-word keyword.
 * e.g. "Charge" alone is noise; "Bolt Charge" and "Armor Charge" are real.
 */
export const FRAGMENT_KEYWORDS = new Set(
  [
    "charge",
    "charges",
    "stack",
    "stacks",
    "buff",
    "buffs",
    "debuff",
    "debuffs",
    "round",
    "rounds",
    "surge",
    "surges",
    "orb",
    "orbs",
    "pickup",
    "pickups",
    "trace",
    "traces",
    "shard",
    "shards",
    "crystal",
    "crystals",
    "breach",
    "breaches",
    "overshield",
    "armor", // alone; "Armor Charge" is multi-word
    "bolt", // alone; "Bolt Charge" is multi-word
    "void", // alone often just element context in trait text; element scan covers curated
    "solar",
    "arc",
    "stasis",
    "strand",
    "kinetic",
  ].map((w) => w.toLowerCase()),
);

/**
 * Standalone noise terms that should never become novel keywords.
 * (Empty magazine wording, Stagger from knockdown text, etc.)
 */
export const NOISE_KEYWORDS = new Set(
  [
    "empty",
    "stagger",
    "staggers",
    "staggered",
    "staggering",
  ].map((w) => w.toLowerCase()),
);

/**
 * Multi-word / alias expansions from description text.
 * Longer patterns first so "being in combat" wins over bare "being".
 */
export const KEYWORD_PHRASE_ALIASES: ReadonlyArray<{
  canonical: string;
  patterns: readonly string[];
}> = [
  {
    canonical: "Being in Combat",
    patterns: ["being in combat", "being"],
  },
];

const PHRASE_ALIAS_PATTERN_ORDER: ReadonlyArray<{
  pattern: string;
  canonical: string;
}> = KEYWORD_PHRASE_ALIASES.flatMap((t) =>
  t.patterns.map((pattern) => ({ pattern, canonical: t.canonical })),
).sort((a, b) => b.pattern.length - a.pattern.length);

/**
 * Resolve free-text to a phrase alias (Being → Being in Combat).
 */
export function resolvePhraseAlias(token: string): string | null {
  const n = token.trim().toLowerCase().replace(/\s+/g, " ");
  if (!n) return null;
  for (const { pattern, canonical } of PHRASE_ALIAS_PATTERN_ORDER) {
    if (n === pattern || n === canonical.toLowerCase()) return canonical;
  }
  return null;
}

/**
 * Find phrase-alias mentions in description text (case-insensitive).
 * Only the full combat phrase is scanned as free text; bare "being" is handled
 * when Title-Case "Being" is extracted (via resolvePhraseAlias).
 */
export function findPhraseAliasesInText(text: string): string[] {
  if (!text.trim()) return [];
  const found = new Set<string>();
  // Prefer full phrase; do not match bare English "being" in prose
  if (textIncludesPhrase(text, "being in combat")) {
    found.add("Being in Combat");
  }
  return [...found];
}

/**
 * Elite PvE combatant categories that perk text lists interchangeably
 * ("damage vs mini-bosses, Tormentors, or Champions" → each target is a keyword).
 * Canonical labels are singular Title Case; aliases cover plurals / hyphenation.
 */
export const ELITE_COMBATANT_TERMS: ReadonlyArray<{
  canonical: string;
  /** Match forms, longest first within each term. */
  patterns: readonly string[];
}> = [
  {
    canonical: "Miniboss",
    patterns: [
      "mini-bosses",
      "mini-boss",
      "mini bosses",
      "mini boss",
      "minibosses",
      "miniboss",
    ],
  },
  {
    canonical: "Champion",
    patterns: ["champions", "champion"],
  },
  {
    canonical: "Tormentor",
    patterns: ["tormentors", "tormentor"],
  },
  {
    canonical: "Vehicle",
    patterns: ["vehicles", "vehicle"],
  },
  {
    canonical: "Boss",
    // After Miniboss so "mini-boss" is claimed first (hyphen creates \b before boss).
    patterns: ["bosses", "boss"],
  },
];

/** Flat pattern list: longer patterns first so mini-boss wins over boss. */
const ELITE_COMBATANT_PATTERN_ORDER: ReadonlyArray<{
  pattern: string;
  canonical: string;
}> = ELITE_COMBATANT_TERMS.flatMap((t) =>
  t.patterns.map((pattern) => ({ pattern, canonical: t.canonical })),
).sort((a, b) => b.pattern.length - a.pattern.length);

/**
 * Resolve free-text (Champion, mini-bosses, bosses, …) to a canonical elite label.
 */
export function resolveEliteCombatant(token: string): string | null {
  const n = token
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
  if (!n) return null;
  for (const { pattern, canonical } of ELITE_COMBATANT_PATTERN_ORDER) {
    if (n === pattern || n === canonical.toLowerCase()) return canonical;
  }
  return null;
}

/**
 * Find elite combatant mentions in text (case-insensitive, non-overlapping).
 * List phrases yield each target separately — not one multi-target keyword.
 */
export function findEliteCombatantsInText(text: string): string[] {
  if (!text.trim()) return [];
  const lower = text.toLowerCase();
  const occupied: Array<{ start: number; end: number }> = [];
  const found = new Set<string>();

  for (const { pattern, canonical } of ELITE_COMBATANT_PATTERN_ORDER) {
    const re = new RegExp(`\\b${escapeRegExp(pattern)}\\b`, "gi");
    let m: RegExpExecArray | null;
    while ((m = re.exec(lower)) !== null) {
      const start = m.index;
      const end = start + m[0]!.length;
      const overlaps = occupied.some((s) => start < s.end && end > s.start);
      if (overlaps) continue;
      occupied.push({ start, end });
      found.add(canonical);
    }
  }
  return [...found];
}

/** Multi-word curated phrases first (longer match wins). */
function curatedPhraseList(): Array<{ phrase: string; kind: "verb" | "element" }> {
  const verbs = SYNERGY_VERB_NAMES.map((name) => ({
    phrase: name,
    kind: "verb" as const,
  }));
  const elements = SYNERGY_ELEMENTS.map((name) => ({
    phrase: name,
    kind: "element" as const,
  }));
  return [...verbs, ...elements].sort(
    (a, b) => b.phrase.length - a.phrase.length,
  );
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Case-insensitive whole-phrase match (word boundaries). */
export function textIncludesPhrase(text: string, phrase: string): boolean {
  const re = new RegExp(`\\b${escapeRegExp(phrase.trim())}\\b`, "i");
  return re.test(text);
}

type WordTok = { word: string; title: boolean; breakBefore: boolean };

/**
 * Tokenize into words with capitalization + sentence/punctuation breaks.
 * Punctuation breaks prevent "Armor Charge. Charge" from becoming one run.
 * Commas/list separators keep "Tormentors, Champions" as separate terms.
 */
function titleCaseWords(text: string): WordTok[] {
  const out: WordTok[] = [];
  // Capture word or a break (punctuation / newline / list separators)
  const re = /([A-Za-z][A-Za-z0-9'/-]*)|([.!?…;:,\n]+)/g;
  let m: RegExpExecArray | null;
  let pendingBreak = false;
  while ((m = re.exec(text)) !== null) {
    if (m[2]) {
      pendingBreak = true;
      continue;
    }
    const word = m[1]!;
    // Hyphenated mini-bosses etc. count as title-ish when any segment is Title Case
    const title =
      /^[A-Z][a-z]+$/.test(word) ||
      /^[A-Z][a-z]+(?:-[A-Za-z]+)+$/.test(word);
    out.push({ word, title, breakBefore: pendingBreak });
    pendingBreak = false;
  }
  return out;
}

/**
 * Extract Title-Case / keyword-like tokens from Destiny description text.
 * Prefers multi-word phrases ("Bolt Charge", "Armor Charge") over bare fragments
 * like "Charge" alone. Uses local context so components of a multi-word phrase
 * are not also emitted alone.
 */
export function extractKeywordTokens(text: string): string[] {
  if (!text.trim()) return [];

  const words = titleCaseWords(text);
  const multiPhrases = new Set<string>();
  const singleCandidates = new Set<string>();

  // Walk consecutive Title-Case runs (broken by lowercase words or punctuation)
  let i = 0;
  while (i < words.length) {
    if (!words[i]!.title) {
      i += 1;
      continue;
    }
    let j = i + 1;
    while (
      j < words.length &&
      words[j]!.title &&
      !words[j]!.breakBefore
    ) {
      j += 1;
    }
    const run = words.slice(i, j).map((w) => w.word);

    // Strip leading stopwords inside the run
    let start = 0;
    while (start < run.length && STOPWORDS.has(run[start]!.toLowerCase())) {
      start += 1;
    }
    const core = run.slice(start);
    if (core.length === 1) {
      singleCandidates.add(core[0]!);
    } else if (core.length >= 2) {
      for (let a = 0; a < core.length; a++) {
        for (let b = a + 2; b <= core.length; b++) {
          multiPhrases.add(core.slice(a, b).join(" "));
        }
      }
    }
    i = j;
  }

  // Words covered by a multi-word phrase should not also be emitted alone
  const coveredByMulti = new Set<string>();
  for (const phrase of multiPhrases) {
    for (const w of phrase.split(/\s+/)) {
      coveredByMulti.add(w.toLowerCase());
    }
  }

  const found = new Set<string>(multiPhrases);

  // Single Title-Case words — not fragments/noise, not part of a multi-word phrase
  for (const m of singleCandidates) {
    const lower = m.toLowerCase();
    if (STOPWORDS.has(lower)) continue;
    if (FRAGMENT_KEYWORDS.has(lower)) continue;
    if (NOISE_KEYWORDS.has(lower)) continue;
    if (coveredByMulti.has(lower)) continue;
    // Bare "Being" expands to the combat-state phrase
    if (lower === "being") {
      found.add("Being in Combat");
      continue;
    }
    found.add(m);
  }
  for (const { word, title } of words) {
    if (!title) continue;
    const lower = word.toLowerCase();
    if (STOPWORDS.has(lower)) continue;
    if (FRAGMENT_KEYWORDS.has(lower)) continue;
    if (NOISE_KEYWORDS.has(lower)) continue;
    if (coveredByMulti.has(lower)) continue;
    if (lower === "being") {
      found.add("Being in Combat");
      continue;
    }
    found.add(word);
  }

  return [...found];
}

export type ObjectTextRecord = {
  store: string;
  hash?: number;
  name: string;
  description?: string;
};

type Agg = {
  keyword: string;
  kind: "verb" | "element";
  origin: "curated" | "object_text";
  mentionCount: number;
  samples: KeywordSourceHit[];
};

/**
 * Canonical display label for aggregation: curated verb if known, phrase aliases
 * (Being → Being in Combat), elite combatants (mini-bosses → Miniboss), else singular.
 */
export function canonicalizeDiscoveredKeyword(keyword: string): string {
  const trimmed = keyword.trim();
  if (!trimmed) return trimmed;
  const asVerb = resolveVerbSubType(trimmed);
  if (asVerb) return asVerb;
  const asElement = (SYNERGY_ELEMENTS as readonly string[]).find(
    (e) => normalizeDesignationKey(e) === normalizeDesignationKey(trimmed),
  );
  if (asElement) return asElement;
  const asPhrase = resolvePhraseAlias(trimmed);
  if (asPhrase) return asPhrase;
  const asElite = resolveEliteCombatant(trimmed);
  if (asElite) return asElite;
  // After simple singularize, re-check elite (Champions → Champion already handled above)
  const singular = singularizeKeywordLabel(trimmed);
  const asPhraseSingular = resolvePhraseAlias(singular);
  if (asPhraseSingular) return asPhraseSingular;
  const asEliteSingular = resolveEliteCombatant(singular);
  if (asEliteSingular) return asEliteSingular;
  return singular;
}

function addHit(
  map: Map<string, Agg>,
  keyword: string,
  kind: "verb" | "element",
  origin: "curated" | "object_text",
  hit: KeywordSourceHit,
  referenceLimit = KEYWORD_REFERENCE_LIMIT,
): void {
  const display = canonicalizeDiscoveredKeyword(keyword);
  const key = normalizeDesignationKey(display);
  const existing = map.get(key);
  if (!existing) {
    map.set(key, {
      keyword: display,
      kind,
      origin,
      mentionCount: 1,
      samples: [hit],
    });
    return;
  }
  existing.mentionCount += 1;
  // Prefer curated origin if we also saw it as object_text
  if (origin === "curated") {
    existing.origin = "curated";
    existing.kind = kind;
    existing.keyword = display;
  } else if (existing.origin !== "curated") {
    // Prefer singular / shorter canonical label for novels
    existing.keyword = display;
  }
  const seen = new Set(existing.samples.map(sampleKey));
  if (!seen.has(sampleKey(hit)) && existing.samples.length < referenceLimit) {
    existing.samples.push(hit);
  }
}

/**
 * Scan object **descriptions only** (not item/perk names) for potential synergy
 * keywords. Includes curated verb/element mentions and novel Title-Case terms.
 * Skips tokens that already exist as other synergy subtypes (e.g. Glaive → archetype).
 */
export function discoverKeywordsFromObjects(
  objects: ObjectTextRecord[],
  opts?: {
    /** Min mentions for novel (non-curated) keywords. */
    minNovelMentions?: number;
    /** Min mentions for curated keywords to count as object-backed. */
    minCuratedMentions?: number;
    /**
     * Normalized keys of existing type/subtype labels (from buildExistingDesignationIndex).
     * Novel tokens that match are not proposed as new verb keywords.
     */
    existingDesignationKeys?: ReadonlySet<string>;
    /** Optional resolver: token → already-known designation (verb/element/archetype/…). */
    resolveExisting?: (
      token: string,
    ) => { type: string; subType: string | null; label: string } | null;
  },
): DiscoveredKeyword[] {
  const minNovel = opts?.minNovelMentions ?? 2;
  const minCurated = opts?.minCuratedMentions ?? 1;
  const phrases = curatedPhraseList();
  const map = new Map<string, Agg>();

  const refLimit = KEYWORD_REFERENCE_LIMIT;

  for (const obj of objects) {
    // Names identify the object in the UI; only description text is scanned.
    const blob = (obj.description ?? "").trim();
    if (!blob) continue;

    const makeHit = (keyword: string): KeywordSourceHit => ({
      store: obj.store,
      hash: obj.hash,
      name: obj.name,
      snippet: snippetAroundKeyword(blob, keyword),
    });

    // Curated phrase mentions — longest phrases first so "Bolt Charge" wins over noise
    for (const { phrase, kind } of phrases) {
      if (textIncludesPhrase(blob, phrase)) {
        const canonical =
          kind === "verb" ? resolveVerbSubType(phrase) ?? phrase : phrase;
        addHit(map, canonical, kind, "curated", makeHit(canonical), refLimit);
      }
    }
    // Alias phrases (e.g. "Stasis Shards") → canonical curated verb
    if (
      textIncludesPhrase(blob, "Stasis Shards") ||
      textIncludesPhrase(blob, "Stasis Shard")
    ) {
      const canonical = resolveVerbSubType("Stasis Shards") ?? "Stasis Shard";
      addHit(map, canonical, "verb", "curated", makeHit(canonical), refLimit);
    }

    // Phrase expansions from free text ("being in combat" → Being in Combat)
    const phraseHits = new Set(findPhraseAliasesInText(blob));
    for (const alias of phraseHits) {
      addHit(map, alias, "verb", "object_text", makeHit(alias), refLimit);
    }

    // Elite combatant list targets (boss / Champion / miniboss / Tormentor / vehicle)
    // — each target is its own keyword; lowercase + hyphen forms included.
    for (const elite of findEliteCombatantsInText(blob)) {
      addHit(map, elite, "verb", "object_text", makeHit(elite), refLimit);
    }

    // Novel Title-Case tokens from this object
    for (const token of extractKeywordTokens(blob)) {
      // Elite combatants already counted above (case-insensitive + aliases).
      if (resolveEliteCombatant(token)) continue;
      // Phrase aliases: Title-Case "Being" → Being in Combat; skip if full phrase already hit
      const asPhrase = resolvePhraseAlias(token);
      if (asPhrase) {
        if (!phraseHits.has(asPhrase)) {
          addHit(map, asPhrase, "verb", "object_text", makeHit(asPhrase), refLimit);
        }
        continue;
      }

      const asVerb = resolveVerbSubType(token);
      if (asVerb) {
        addHit(map, asVerb, "verb", "curated", makeHit(asVerb), refLimit);
        continue;
      }
      if (
        (SYNERGY_ELEMENTS as readonly string[]).some(
          (e) => e.toLowerCase() === token.toLowerCase(),
        )
      ) {
        const el =
          SYNERGY_ELEMENTS.find((e) => e.toLowerCase() === token.toLowerCase()) ??
          token;
        addHit(map, el, "element", "curated", makeHit(el), refLimit);
        continue;
      }

      // Already a known subtype/type under another category (Glaive, Adaptive Frame, …)
      const existing = opts?.resolveExisting?.(token);
      if (existing) {
        // Only surface as verb/element discovery; other categories are not
        // re-proposed as novel keywords here.
        if (existing.type === "verb" && existing.subType) {
          addHit(
            map,
            existing.subType,
            "verb",
            "curated",
            makeHit(existing.subType),
            refLimit,
          );
        } else if (existing.type === "element" && existing.subType) {
          addHit(
            map,
            existing.subType,
            "element",
            "curated",
            makeHit(existing.subType),
            refLimit,
          );
        }
        continue;
      }

      // Skip if all parts are stopwords/fragments/noise (e.g. bare "Charge", "Empty")
      const parts = token.split(/\s+/);
      if (
        parts.every(
          (p) =>
            STOPWORDS.has(p.toLowerCase()) ||
            FRAGMENT_KEYWORDS.has(p.toLowerCase()) ||
            NOISE_KEYWORDS.has(p.toLowerCase()),
        )
      ) {
        continue;
      }
      // Single-word novel tokens that are fragments/noise are never keywords alone
      if (
        parts.length === 1 &&
        (FRAGMENT_KEYWORDS.has(parts[0]!.toLowerCase()) ||
          NOISE_KEYWORDS.has(parts[0]!.toLowerCase()))
      ) {
        continue;
      }
      addHit(map, token, "verb", "object_text", makeHit(token), refLimit);
    }
  }

  const eliteCanonical = new Set(
    ELITE_COMBATANT_TERMS.map((t) => normalizeDesignationKey(t.canonical)),
  );
  const phraseCanonical = new Set(
    KEYWORD_PHRASE_ALIASES.map((t) => normalizeDesignationKey(t.canonical)),
  );

  const out: DiscoveredKeyword[] = [];
  for (const agg of map.values()) {
    if (agg.origin === "curated" && agg.mentionCount < minCurated) continue;
    if (agg.origin === "object_text") {
      // Known elite combatant categories (Boss, Champion, …) and phrase aliases
      // (Being in Combat) surface like curated so a single clear mention still proposes.
      const key = normalizeDesignationKey(agg.keyword);
      const isSpecial = eliteCanonical.has(key) || phraseCanonical.has(key);
      const need = isSpecial ? minCurated : minNovel;
      if (agg.mentionCount < need) continue;
    }
    out.push({
      keyword: agg.keyword,
      kind: agg.kind,
      origin: agg.origin,
      mentionCount: agg.mentionCount,
      sampleObjects: agg.samples,
    });
  }

  return out.sort(
    (a, b) =>
      b.mentionCount - a.mentionCount ||
      a.keyword.localeCompare(b.keyword, undefined, { sensitivity: "base" }),
  );
}

/** Destiny-like keyword form for open verb subtypes discovered from objects. */
export function isKeywordLikeSubType(name: string): boolean {
  const t = name.trim();
  if (t.length < 3 || t.length > 48) return false;
  if (resolveVerbSubType(t)) return true;
  if (resolvePhraseAlias(t)) return true;
  if (resolveEliteCombatant(t)) return true;
  // Title Case words, optional short connectors: Sliding, Bolt Charge, Being in Combat
  return /^[A-Z][A-Za-z0-9'/-]*(?:\s+(?:in|of|the|a|and|or|to|vs|[A-Z][A-Za-z0-9'/-]*)){0,4}$/.test(
    t,
  );
}
