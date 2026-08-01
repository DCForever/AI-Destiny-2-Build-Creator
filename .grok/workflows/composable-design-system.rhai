let meta = #{
    name: "composable-design-system",
    description: "Audit Flutter Matte Flap Ledger for composable UI and a strong, flexible design system",
    when_to_use: "When checking Flutter ui_tokens, ThemeData mapping, host widget composition, or design-system gaps before UI work",
    phases: [
        #{ title: "Inventory", detail: "map tokens, theme, hosts, and surfaces" },
        #{ title: "Audit", detail: "parallel Flutter design-system dimensions" },
        #{ title: "Verify", detail: "adversarial check on top findings" },
        #{ title: "Synthesize", detail: "scored report and prioritized gaps" },
    ],
};

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------

let inventory_schema = #{
    "type": "object",
    "required": ["summary", "tokens", "theme", "primitives", "surfaces", "architecture", "gaps"],
    "properties": #{
        "summary": #{ "type": "string" },
        "tokens": #{
            "type": "object",
            "required": ["package_path", "exports", "named_rules", "token_notes"],
            "properties": #{
                "package_path": #{ "type": "string" },
                "exports": #{ "type": "array", "maxItems": 20, "items": #{ "type": "string" } },
                "named_rules": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
                "layout_contracts": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
                "token_notes": #{ "type": "string" },
            },
        },
        "theme": #{
            "type": "object",
            "required": ["windows_path", "mobile_path", "modes"],
            "properties": #{
                "windows_path": #{ "type": "string" },
                "mobile_path": #{ "type": "string" },
                "modes": #{ "type": "array", "items": #{ "type": "string" } },
                "maps_from_tokens": #{ "type": "boolean" },
                "notes": #{ "type": "string" },
            },
        },
        "primitives": #{
            "type": "array",
            "maxItems": 40,
            "items": #{
                "type": "object",
                "required": ["name", "path", "role", "composability", "shell"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "path": #{ "type": "string" },
                    "role": #{ "type": "string" },
                    "composability": #{ "type": "string" },
                    "shell": #{ "type": "string" },
                    "variants_or_slots": #{ "type": "string" },
                },
            },
        },
        "surfaces": #{
            "type": "array",
            "maxItems": 24,
            "items": #{
                "type": "object",
                "required": ["name", "path", "shell", "uses_tokens", "composition_score"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "path": #{ "type": "string" },
                    "shell": #{ "type": "string" },
                    "uses_tokens": #{ "type": "boolean" },
                    "composition_score": #{ "type": "string" },
                    "notes": #{ "type": "string" },
                },
            },
        },
        "architecture": #{
            "type": "object",
            "required": ["shared_layer", "not_shared", "implication"],
            "properties": #{
                "shared_layer": #{ "type": "string" },
                "not_shared": #{ "type": "string" },
                "implication": #{ "type": "string" },
            },
        },
        "gaps": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["gap", "severity", "evidence"],
                "properties": #{
                    "gap": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "evidence": #{ "type": "string" },
                },
            },
        },
    },
};

let findings_schema = #{
    "type": "object",
    "required": ["dimension", "score", "strengths", "findings", "recommendations"],
    "properties": #{
        "dimension": #{ "type": "string" },
        "score": #{ "type": "string" },
        "strengths": #{
            "type": "array",
            "maxItems": 6,
            "items": #{
                "type": "object",
                "required": ["claim", "evidence"],
                "properties": #{
                    "claim": #{ "type": "string" },
                    "evidence": #{ "type": "string" },
                },
            },
        },
        "findings": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["id", "severity", "title", "file", "issue", "fix_hint"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "title": #{ "type": "string" },
                    "file": #{ "type": "string" },
                    "issue": #{ "type": "string" },
                    "fix_hint": #{ "type": "string" },
                },
            },
        },
        "recommendations": #{
            "type": "array",
            "maxItems": 6,
            "items": #{ "type": "string" },
        },
    },
};

let verdict_schema = #{
    "type": "object",
    "required": ["real", "reason", "evidence"],
    "properties": #{
        "real": #{ "type": "boolean" },
        "reason": #{ "type": "string" },
        "evidence": #{ "type": "string" },
    },
};

let report_schema = #{
    "type": "object",
    "required": [
        "executive_summary",
        "overall_score",
        "dimension_scores",
        "confirmed_gaps",
        "system_strengths",
        "priority_actions",
        "composable_ui_verdict",
        "design_system_verdict",
    ],
    "properties": #{
        "executive_summary": #{ "type": "string" },
        "overall_score": #{ "type": "string" },
        "dimension_scores": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["dimension", "score", "one_liner"],
                "properties": #{
                    "dimension": #{ "type": "string" },
                    "score": #{ "type": "string" },
                    "one_liner": #{ "type": "string" },
                },
            },
        },
        "confirmed_gaps": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["title", "severity", "file", "issue", "fix_hint"],
                "properties": #{
                    "title": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "file": #{ "type": "string" },
                    "issue": #{ "type": "string" },
                    "fix_hint": #{ "type": "string" },
                },
            },
        },
        "system_strengths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "priority_actions": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["action", "why", "effort_band"],
                "properties": #{
                    "action": #{ "type": "string" },
                    "why": #{ "type": "string" },
                    "effort_band": #{ "type": "string" },
                },
            },
        },
        "composable_ui_verdict": #{ "type": "string" },
        "design_system_verdict": #{ "type": "string" },
        "do_not_change": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
        "next_parity_notes": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
    },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn trimmed(s) {
    if type_of(s) == "string" {
        s.trim();
        s
    } else {
        ""
    }
}

fn as_str(v) {
    if v == () { "" } else if type_of(v) == "string" { trimmed(v) } else { "" }
}

fn as_arr(v) {
    if v == () { [] } else if type_of(v) == "array" { v } else { [] }
}

fn severity_rank(s) {
    let t = as_str(s);
    if t == "critical" { 4 }
    else if t == "high" { 3 }
    else if t == "medium" { 2 }
    else if t == "low" { 1 }
    else { 0 }
}

fn path_allowed(path, roots) {
    let p = as_str(path);
    if p == "" { false }
    else if p == "inventory" { true }
    else if p == "DESIGN.md" { true }
    else {
        let ok = false;
        for r in roots {
            let root = as_str(r);
            if root == "" { continue; }
            if p == root { ok = true; }
            else if p.len() > root.len() && p.sub_string(0, root.len()) == root { ok = true; }
        }
        ok
    }
}

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
// args.worktree     — monorepo root (default multiplatform dart path)
// args.scope        — path prefix under worktree (default: apps + packages/ui_tokens)
// args.host         — windows | mobile | both (default both)
// args.focus        — free-text emphasis
// args.max_verify   — 1..10 (default 8)
// args.include_next — if true, also compare token parity to Next DESIGN.md/globals.css

let worktree = "F:/Destiny2BuildCreator-multiplatform-dart";
let scope = "";
let host = "both";
let focus = "";
let max_verify = 8;
let include_next = true;

if args != () {
    if args.worktree != () { worktree = trimmed(args.worktree); }
    if args.scope != () { scope = trimmed(args.scope); }
    if args.host != () { host = trimmed(args.host); }
    if args.focus != () { focus = trimmed(args.focus); }
    if args.include_next != () && args.include_next == false { include_next = false; }
    if args.max_verify != () {
        if type_of(args.max_verify) == "i64" || type_of(args.max_verify) == "int" {
            max_verify = args.max_verify;
        }
    }
}
if max_verify < 1 { max_verify = 1; }
if max_verify > 10 { max_verify = 10; }
if host != "windows" && host != "mobile" && host != "both" { host = "both"; }
if worktree == "" { worktree = "F:/Destiny2BuildCreator-multiplatform-dart"; }

// Normalize trailing slash noise (keep simple)
let wt = worktree;

// Default scope covers Flutter design system surface area
if scope == "" {
    scope = "packages/ui_tokens + apps/windows_host/lib + apps/mobile_host/lib";
}

// Allowed path prefixes for scope filter (relative + absolute)
let allow_roots = [
    "packages/ui_tokens",
    "apps/windows_host",
    "apps/mobile_host",
    "apps/web_host",
    "DESIGN.md",
    "docs/multiplatform-dart-port-decisions.md",
    "docs/ui-polish-tracker.md",
    "src/app/globals.css",
    "src/components/ui",
    wt + "/packages/ui_tokens",
    wt + "/apps/windows_host",
    wt + "/apps/mobile_host",
    wt + "/apps/web_host",
    wt + "/DESIGN.md",
    wt + "/docs/",
    wt + "/src/app/globals.css",
    wt + "/src/components/ui",
];

log("composable-design-system (Flutter): worktree=" + wt + " host=" + host
    + " focus=" + (if focus == "" { "(broad)" } else { focus }));

// =============================================================================
// Phase 1: Inventory Flutter design system
// =============================================================================
phase("Inventory");

let inv_prompt = "";
inv_prompt += "You are inventorying the Flutter multiplatform design system for Destiny 2 Build Creator. ";
inv_prompt += "Creative north star: Matte Flap Ledger (void-black split-flap boards, square matte, no steel). ";
inv_prompt += "Monorepo root: " + wt + ". Work ONLY under this root unless comparing Next token sources. ";
inv_prompt += "Use read-only tools (read_file, list_dir, grep). Do NOT answer from memory. ";
inv_prompt += "Architecture rule (docs/multiplatform-dart-port-decisions.md): shells do NOT share one widget tree; ";
inv_prompt += "they share pure-Dart tokens + layout contracts (packages/ui_tokens). Flutter widgets may live in hosts. ";
inv_prompt += "MUST open: DESIGN.md; packages/ui_tokens/README.md; packages/ui_tokens/lib/destiny2_ui_tokens.dart; ";
inv_prompt += "packages/ui_tokens/lib/src/*.dart; apps/windows_host/lib/theme/flap_theme.dart; ";
inv_prompt += "apps/mobile_host/lib/theme/flap_theme.dart (if present); apps/windows_host/lib/app.dart; apps/mobile_host/lib/app.dart. ";
inv_prompt += "Sample surfaces: windows sets/synergies/builds/catalog/settings/equip/dim_export/optimizer; mobile builds/settings. ";
inv_prompt += "Host filter for this run: " + host + ". ";
if host == "windows" {
    inv_prompt += "Prioritize apps/windows_host; still note mobile theme path if exists. ";
} else if host == "mobile" {
    inv_prompt += "Prioritize apps/mobile_host; still note windows theme + tokens. ";
} else {
    inv_prompt += "Cover both windows_host and mobile_host. ";
}
inv_prompt += "For primitives: list reusable widgets/components found in hosts (and any shared UI packages). ";
inv_prompt += "composability: atomic | layout | pattern | screen | one-off. shell: windows|mobile|shared. ";
inv_prompt += "If there is NO shared FlapRow/FlapBoard widget library yet, say so explicitly in gaps (not a false strength). ";
inv_prompt += "surfaces.uses_tokens: true only if file imports destiny2_ui_tokens or uses kFlap*/FlapColorTokens. ";
inv_prompt += "composition_score: strong|mixed|weak based on token/theme reuse vs hardcoded Color(0x..) / Material defaults. ";
inv_prompt += "architecture.shared_layer must reflect pure tokens package; not_shared = per-shell widgets. ";
if include_next {
    inv_prompt += "Optionally skim src/app/globals.css or src/components/ui for token parity notes only — Flutter is primary. ";
}
if focus != "" {
    inv_prompt += "User focus: " + focus + ". Emphasize inventory detail relevant to that focus. ";
}
inv_prompt += "Return structured JSON only. Every path must be real under the monorepo.";

let inv_r = agent(inv_prompt, #{
    label: "inventory-flutter-ds",
    capability_mode: "read-only",
    output_schema: inventory_schema,
});

if inv_r == () || !inv_r.success || inv_r.output == () {
    complete(#{
        summary: "Inventory phase failed — cannot audit Flutter design system without a grounded map.",
        error: "inventory_failed",
        worktree: wt,
    });
}

let inventory = inv_r.output;
let inv_primitives = as_arr(inventory.primitives);
let inv_surfaces = as_arr(inventory.surfaces);
let inv_gaps = as_arr(inventory.gaps);
log("Inventory: " + inv_primitives.len().to_string() + " primitives, "
    + inv_surfaces.len().to_string() + " surfaces, "
    + inv_gaps.len().to_string() + " inventory gaps");

let inventory_json = json_encode(inventory);

// =============================================================================
// Phase 2: Parallel dimension audits (Flutter-specific)
// =============================================================================
phase("Audit");

let dimensions = [
    #{
        id: "token-fidelity",
        title: "Token fidelity (ui_tokens ↔ DESIGN.md)",
        brief: "Compare packages/ui_tokens (colors, spacing, radii, typography, flap_board_layout) to DESIGN.md and package tests. Flag hex drift, missing element ink, wrong radius/gap contracts, and untested tokens. Judge whether pure-Dart tokens are a strong single source for Flutter + future Jaspr.",
    },
    #{
        id: "theme-flexibility",
        title: "ThemeData mapping & flexibility",
        brief: "Audit apps/*/lib/theme/flap_theme.dart: maps tokens into ThemeData without ColorScheme.fromSeed blue; cardTheme square elevation-0; dark/light readiness; ThemeToggle gaps. Flag ThemeData fields still Material-default that fight Matte Flap Ledger, and whether brightness switches cleanly from tokens.",
    },
    #{
        id: "host-composition",
        title: "Host composable UI vs one-offs",
        brief: "Audit Flutter host screens under apps/windows_host/lib and/or apps/mobile_host/lib. Do pages compose reusable widgets + tokens, or copy-paste Card/ListTile/hardcoded colors? Look for Board-Not-Cards violations (elevated cards per library row), missing use of kFlapLibraryRailWidth / column contracts, and screen widgets that cannot be rearranged without restyling. Prefer grep for Color(0x, BoxDecoration, Card(, ListTile(.",
    },
    #{
        id: "shared-kit-gaps",
        title: "Shared composition kit gaps",
        brief: "Given architecture (share tokens, not one widget tree), assess whether hosts still need a small host-local OR carefully scoped shared Flutter kit (FlapBoard, FlapRow, Badge, Chip, Panel, EmptyState). Identify duplicated patterns across windows and mobile that should become composable widgets WITHOUT forcing Jaspr to depend on Flutter. Recommend smallest composable set that unlocks flexible UI.",
    },
    #{
        id: "cross-shell-consistency",
        title: "Windows / mobile / named-rule consistency",
        brief: "Compare windows_host vs mobile_host for token/theme use, density adaptation, amber One Lamp rule, Element Ink only on identity, accessibility (Semantics, contrast, tappable targets). Flag divergences that look accidental vs intentional mobile density. Include a11y contracts on interactive controls.",
    },
];

let jobs = [];
for d in dimensions {
    let p = "";
    p += "You are auditing Flutter design-system dimension: " + d.title + " for Destiny 2 Build Creator. ";
    p += d.brief + " ";
    p += "Monorepo: " + wt + ". Host filter: " + host + ". Scope: " + scope + ". ";
    p += "Use read-only tools (read_file, grep, list_dir). Open real Dart files under packages/ui_tokens and apps/*_host. ";
    p += "Do not invent packages or widgets that do not exist. Missing FlapBoard widgets is a valid finding, not a pass. ";
    p += "Prior inventory (verify critical claims; do not trust blindly): ";
    p += inventory_json;
    p += " ";
    if include_next {
        p += "You may compare DESIGN.md / Next globals.css for token parity only; do not audit Next components as the primary product here. ";
    }
    if focus != "" {
        p += "User focus: " + focus + ". ";
    }
    p += "score: excellent|good|mixed|weak|critical for this dimension only. ";
    p += "severity per finding: low|medium|high|critical. ";
    p += "finding id: short slug like token-accent-drift. ";
    p += "At most 8 findings; prefer high-signal hits against composability or design-system flexibility. ";
    p += "file paths should be monorepo-relative when possible (packages/..., apps/...). ";
    p += "Empty findings only after real inspection proves the dimension is solid — still list strengths with evidence. ";
    p += "fix_hint must be actionable for Flutter multiplatform (token, theme, or host widget).";
    jobs.push(#{
        prompt: p,
        label: "audit:" + d.id,
        capability_mode: "read-only",
        output_schema: findings_schema,
    });
}

let audit_results = parallel(jobs);

let audits = [];
let all_findings = [];
let ai = 0;
for r in audit_results {
    let dim = dimensions[ai];
    if r != () && r.success && r.output != () {
        audits.push(r.output);
        let flist = as_arr(r.output.findings);
        for f in flist {
            let fpath = as_str(f.file);
            if path_allowed(fpath, allow_roots) {
                all_findings.push(#{
                    dimension: dim.id,
                    id: as_str(f.id),
                    severity: as_str(f.severity),
                    title: as_str(f.title),
                    file: fpath,
                    issue: as_str(f.issue),
                    fix_hint: as_str(f.fix_hint),
                });
            } else {
                log("Dropped out-of-scope finding path: " + fpath);
            }
        }
    } else {
        log("Audit dimension failed or empty: " + dim.id);
    }
    ai += 1;
}

for g in inv_gaps {
    all_findings.push(#{
        dimension: "inventory",
        id: "inv-gap",
        severity: as_str(g.severity),
        title: as_str(g.gap),
        file: "inventory",
        issue: as_str(g.evidence),
        fix_hint: "Address inventory gap from Flutter design-system map.",
    });
}

log("Audit collected " + all_findings.len().to_string() + " raw findings across "
    + audits.len().to_string() + " dimensions");

// Severity sort (selection) then take top max_verify
let n = all_findings.len();
if n > 1 {
    let i = 0;
    while i < n {
        let best = i;
        let j = i + 1;
        while j < n {
            if severity_rank(all_findings[j].severity) > severity_rank(all_findings[best].severity) {
                best = j;
            }
            j += 1;
        }
        if best != i {
            let tmp = all_findings[i];
            all_findings[i] = all_findings[best];
            all_findings[best] = tmp;
        }
        i += 1;
    }
}

let to_verify = [];
let vi = 0;
while vi < all_findings.len() && vi < max_verify {
    to_verify.push(all_findings[vi]);
    vi += 1;
}
if all_findings.len() > max_verify {
    log("Truncated verification to top " + max_verify.to_string() + " of "
        + all_findings.len().to_string() + " findings by severity");
}

// =============================================================================
// Phase 3: Adversarial verification (fail closed)
// =============================================================================
phase("Verify");

let confirmed = [];
if to_verify.len() == 0 {
    log("No findings to verify — synthesizer will still score strengths.");
} else {
    let vjobs = [];
    for f in to_verify {
        let vp = "";
        vp += "Adversarially verify this Flutter design-system / composable-UI finding. ";
        vp += "Default real=false unless you independently open the file under monorepo " + wt + " and confirm. ";
        vp += "Finding title: " + as_str(f.title) + ". ";
        vp += "Claimed file: " + as_str(f.file) + ". ";
        vp += "Issue: " + as_str(f.issue) + ". ";
        vp += "Suggested fix: " + as_str(f.fix_hint) + ". ";
        vp += "Dimension: " + as_str(f.dimension) + ". ";
        vp += "Use read_file/grep on the claimed path (prefix with monorepo root if relative). ";
        vp += "Also check packages/ui_tokens and DESIGN.md if the claim is about tokens/rules. ";
        vp += "Set real=true only with concrete evidence (import lines, Color(0x..), Card elevation, missing kFlap*, etc.). ";
        vp += "If architecture intentionally defers widgets to later slices, note that — real=true only if it is still a current gap, not a misread of non-goals. ";
        vp += "evidence must cite path + what you saw.";
        vjobs.push(#{
            prompt: vp,
            label: "verify:" + as_str(f.id),
            capability_mode: "read-only",
            output_schema: verdict_schema,
        });
    }
    let verdicts = parallel(vjobs);
    let k = 0;
    for v in verdicts {
        if v != () && v.success && v.output != ()
            && v.output.real == true
            && as_str(v.output.evidence) != "" {
            let item = to_verify[k];
            item.evidence = as_str(v.output.evidence);
            item.reason = as_str(v.output.reason);
            confirmed.push(item);
        }
        k += 1;
    }
    log(confirmed.len().to_string() + "/" + to_verify.len().to_string()
        + " findings survived verification");
}

// =============================================================================
// Phase 4: Synthesize scored report
// =============================================================================
phase("Synthesize");

let audits_json = json_encode(audits);
let confirmed_json = json_encode(confirmed);

let syn = "";
syn += "You are synthesizing a Flutter design-system health report for Destiny 2 Build Creator (Matte Flap Ledger). ";
syn += "Monorepo: " + wt + ". Host filter: " + host + ". ";
syn += "Goal: ensure composable UI and a strong, flexible design system on Flutter (Windows + mobile), ";
syn += "with pure-Dart tokens as the shared flexible layer (not one shared widget tree). ";
syn += "Use inventory + dimension audits + ONLY adversarially confirmed gaps. ";
syn += "Do not invent new high-severity gaps that were not confirmed. Strengths from audits are OK. ";
syn += "If few confirmed gaps, say so — early token slices can still be healthy. ";
syn += "\n\nINVENTORY:\n";
syn += inventory_json;
syn += "\n\nDIMENSION AUDITS:\n";
syn += audits_json;
syn += "\n\nCONFIRMED GAPS (verified):\n";
syn += confirmed_json;
syn += "\n\n";
if focus != "" {
    syn += "User focus: " + focus + ". ";
}
syn += "overall_score and dimension scores: excellent|good|mixed|weak|critical. ";
syn += "effort_band: S (hours), M (1-3 days), L (1+ weeks). ";
syn += "composable_ui_verdict: 2-4 sentences on host composition quality. ";
syn += "design_system_verdict: 2-4 sentences on ui_tokens + ThemeData flexibility. ";
syn += "priority_actions: ordered list that most improves Flutter composability and system flexibility. ";
syn += "do_not_change: preserve pure token package, board contracts, named anti-rules. ";
syn += "next_parity_notes: optional token/hex alignment notes vs Next DESIGN.md if relevant. ";
syn += "Return JSON only per schema.";

let syn_r = agent(syn, #{
    label: "synthesize-flutter-report",
    capability_mode: "read-only",
    output_schema: report_schema,
});

if syn_r == () || !syn_r.success || syn_r.output == () {
    let fallback = "";
    fallback += "# Flutter Composable Design System Audit (partial)\n\n";
    fallback += "Synthesis agent failed. Confirmed gaps only.\n\n";
    fallback += "Worktree: `" + wt + "` · host: `" + host + "`\n\n";
    for c in confirmed {
        fallback += "- **" + as_str(c.severity) + "**: " + as_str(c.title)
            + " (`" + as_str(c.file) + "`) — " + as_str(c.issue) + "\n";
    }
    let path = write_scratch_file("flutter-design-system-audit.md", fallback);
    complete(#{
        summary: "Partial Flutter audit: synthesis failed; " + confirmed.len().to_string() + " confirmed gaps.",
        path: path,
        confirmed: confirmed,
        worktree: wt,
        error: "synthesize_failed",
    });
}

let report = syn_r.output;

let md = "";
md += "# Flutter Composable Design System Audit\n\n";
md += "**Overall:** " + as_str(report.overall_score) + "\n\n";
md += "**Worktree:** `" + wt + "` · **Host:** `" + host + "`\n\n";
md += as_str(report.executive_summary) + "\n\n";
md += "## Verdicts\n\n";
md += "- **Composable UI:** " + as_str(report.composable_ui_verdict) + "\n";
md += "- **Design system:** " + as_str(report.design_system_verdict) + "\n\n";
md += "## Dimension scores\n\n";
for ds in as_arr(report.dimension_scores) {
    md += "- **" + as_str(ds.dimension) + "** (" + as_str(ds.score) + "): " + as_str(ds.one_liner) + "\n";
}
md += "\n## System strengths\n\n";
for s in as_arr(report.system_strengths) {
    md += "- " + as_str(s) + "\n";
}
md += "\n## Confirmed gaps\n\n";
let gaps_out = as_arr(report.confirmed_gaps);
if gaps_out.len() == 0 {
    md += "_No verified gaps at the verification cap — re-run with higher max_verify or narrower focus if needed._\n";
} else {
    for g in gaps_out {
        md += "### " + as_str(g.title) + " (" + as_str(g.severity) + ")\n\n";
        md += "- **File:** `" + as_str(g.file) + "`\n";
        md += "- **Issue:** " + as_str(g.issue) + "\n";
        md += "- **Fix:** " + as_str(g.fix_hint) + "\n\n";
    }
}
md += "## Priority actions\n\n";
for a in as_arr(report.priority_actions) {
    md += "1. **" + as_str(a.action) + "** (" + as_str(a.effort_band) + ") — " + as_str(a.why) + "\n";
}
md += "\n## Do not change\n\n";
for dnc in as_arr(report.do_not_change) {
    md += "- " + as_str(dnc) + "\n";
}
let parity = as_arr(report.next_parity_notes);
if parity.len() > 0 {
    md += "\n## Next.js token parity notes\n\n";
    for n2 in parity {
        md += "- " + as_str(n2) + "\n";
    }
}
md += "\n---\n_Flutter Matte Flap Ledger · verified " + confirmed.len().to_string()
    + "/" + to_verify.len().to_string() + " · focus: "
    + (if focus == "" { "broad" } else { focus }) + "_\n";

let report_path = write_scratch_file("flutter-design-system-audit.md", md);

complete(#{
    summary: "Flutter design system audit: overall " + as_str(report.overall_score)
        + "; " + confirmed.len().to_string() + " confirmed gaps.",
    path: report_path,
    worktree: wt,
    host: host,
    overall_score: as_str(report.overall_score),
    confirmed_count: confirmed.len(),
    verified_of: to_verify.len(),
    composable_ui_verdict: as_str(report.composable_ui_verdict),
    design_system_verdict: as_str(report.design_system_verdict),
    report: report,
});
