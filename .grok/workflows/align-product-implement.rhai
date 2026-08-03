let meta = #{
    name: "align-product-implement",
    description: "Align multiplatform Dart with product requirements + domain specs (SSoT); prioritize packages; optionally implement and verify. NextJS is not SSoT.",
    when_to_use: "When closing product/code gaps on multiplatform Dart hosts, running a domain or feature-gap pass, or implementing the next DBR/DAC/DART package from specs and product requirements",
    phases: [
        #{ title: "Context", detail: "load product reqs + specs SSoT, Dart feature gaps, PRODUCT" },
        #{ title: "Probe", detail: "parallel code-vs-rules probes by theme" },
        #{ title: "Packages", detail: "synthesize ranked work packages" },
        #{ title: "Select", detail: "user gate or args.package_id" },
        #{ title: "Plan", detail: "implementation plan for selected package" },
        #{ title: "Implement", detail: "Dart packages/apps + domain docs" },
        #{ title: "Verify", detail: "dart test / gates and rule capture" },
        #{ title: "Report", detail: "scratch report and summary" },
    ],
};

// --- schemas ---

let context_schema = #{
    "type": "object",
    "required": ["summary", "open_gaps", "solid_areas", "product_map_notes", "sources_read"],
    "properties": #{
        "summary": #{ "type": "string" },
        "open_gaps": #{
            "type": "array",
            "maxItems": 24,
            "items": #{
                "type": "object",
                "required": ["id", "theme", "priority", "status", "rule_ids", "evidence", "gap_action"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "theme": #{ "type": "string" },
                    "priority": #{ "type": "string" },
                    "status": #{ "type": "string" },
                    "rule_ids": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
                    "evidence": #{ "type": "string" },
                    "gap_action": #{ "type": "string" },
                },
            },
        },
        "solid_areas": #{ "type": "array", "maxItems": 20, "items": #{ "type": "string" } },
        "product_map_notes": #{ "type": "string" },
        "sources_read": #{ "type": "array", "maxItems": 20, "items": #{ "type": "string" } },
    },
};

let probe_schema = #{
    "type": "object",
    "required": ["theme", "findings", "notes"],
    "properties": #{
        "theme": #{ "type": "string" },
        "findings": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["rule_id", "status", "evidence_path", "summary", "suggested_fix"],
                "properties": #{
                    "rule_id": #{ "type": "string" },
                    "status": #{ "type": "string", "description": "OK | Partial | Gap | N/A | Done" },
                    "evidence_path": #{ "type": "string" },
                    "summary": #{ "type": "string" },
                    "suggested_fix": #{ "type": "string" },
                },
            },
        },
        "notes": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
    },
};

let packages_schema = #{
    "type": "object",
    "required": ["packages", "recommended_first", "rationale"],
    "properties": #{
        "packages": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["package_id", "title", "priority", "rule_ids", "scope", "out_of_scope", "acceptance", "estimate"],
                "properties": #{
                    "package_id": #{ "type": "string" },
                    "title": #{ "type": "string" },
                    "priority": #{ "type": "string" },
                    "rule_ids": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
                    "scope": #{ "type": "string" },
                    "out_of_scope": #{ "type": "string" },
                    "acceptance": #{ "type": "string" },
                    "estimate": #{ "type": "string" },
                    "touches_ui": #{ "type": "boolean" },
                    "depends_on": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
                },
            },
        },
        "recommended_first": #{ "type": "string" },
        "rationale": #{ "type": "string" },
    },
};

let plan_schema = #{
    "type": "object",
    "required": ["package_id", "steps", "files", "tests", "docs", "risks"],
    "properties": #{
        "package_id": #{ "type": "string" },
        "steps": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "files": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "tests": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "docs": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "risks": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "product_map": #{ "type": "string" },
    },
};

let implement_schema = #{
    "type": "object",
    "required": ["package_id", "done", "summary", "changed_files", "tests_run", "docs_updated", "follow_ups"],
    "properties": #{
        "package_id": #{ "type": "string" },
        "done": #{ "type": "boolean" },
        "summary": #{ "type": "string" },
        "changed_files": #{ "type": "array", "maxItems": 40, "items": #{ "type": "string" } },
        "tests_run": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "docs_updated": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "follow_ups": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "blocked": #{ "type": "string" },
    },
};

let verify_schema = #{
    "type": "object",
    "required": ["ok", "checks", "failures", "notes"],
    "properties": #{
        "ok": #{ "type": "boolean" },
        "checks": #{
            "type": "array",
            "maxItems": 16,
            "items": #{
                "type": "object",
                "required": ["name", "passed", "detail"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "passed": #{ "type": "boolean" },
                    "detail": #{ "type": "string" },
                },
            },
        },
        "failures": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "notes": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

// --- args ---

fn str_or(v, fallback) {
    if v == () { return fallback; }
    if type_of(v) != "string" { return fallback; }
    let s = v;
    s.trim();
    if s == "" { return fallback; }
    s
}

fn bool_or(v, fallback) {
    if v == () { return fallback; }
    if type_of(v) == "bool" { return v; }
    fallback
}

fn int_or(v, fallback) {
    if v == () { return fallback; }
    if type_of(v) == "i64" || type_of(v) == "int" || type_of(v) == "f64" {
        return v;
    }
    fallback
}

let mode = "scan";
let focus = "";
let package_id = "";
let max_packages = 5;
let do_commit = false;
let skip_product_map = false;

if args != () {
    mode = str_or(args.mode, "scan");
    focus = str_or(args.focus, "");
    package_id = str_or(args.package_id, "");
    max_packages = int_or(args.max_packages, 5);
    do_commit = bool_or(args.commit, false);
    skip_product_map = bool_or(args.skip_product_map, false);
}

if max_packages < 1 { max_packages = 1; }
if max_packages > 8 { max_packages = 8; }

// normalize mode
if mode != "scan" && mode != "implement" && mode != "full" {
    mode = "scan";
}

log("align-product-implement mode=" + mode + " focus=" + (if focus == "" { "(all open)" } else { focus }));

// === SOURCE OF TRUTH (hard rules for every agent in this workflow) ===
// 1. Product requirements (Obsidian ProjectTracker via requirements/) — intent, framing, Domains/Areas/Destiny Objects
// 2. Specs — enforceable DBR-* / DAC-* / BR-* in specs/ (+ PRODUCT.md whole-product framing)
// 3. Dart implementation under flutter/ — code under test
// NextJS (web/NextJS/) is NOT a source of truth. Do not treat Next behavior, tests, or "golden parity with Next"
// as acceptance criteria. Do not invent product rules from Next. Optional legacy reference only if user asks.
//
// Vault mount: requirements/ → C:\Users\Owner\SyncThing\Obsidian\ProjectTracker (gitignored junction).
// Recreate: pwsh -File scripts/link-projecttracker-requirements.ps1
// Pointer: docs/products/README.md
let product_req_paths = "requirements/Projects/Destiny 2 Build Creator/Products.md, requirements/Projects/Destiny 2 Build Creator/Domains/, requirements/Projects/Destiny 2 Build Creator/Areas/, requirements/Projects/Destiny 2 Build Creator/Destiny Objects/, requirements/Projects/Destiny 2 Build Creator.md (project note)";
let product_req_fallback = "If requirements/ is missing: docs/products/README.md + absolute vault C:\\Users\\Owner\\SyncThing\\Obsidian\\ProjectTracker\\Projects\\Destiny 2 Build Creator\\";
let domain_paths = "specs/domain-business-rules.md (DBR-*), specs/domain-acceptance-criteria.md (DAC-*), specs/business-rules.md (BR-*), PRODUCT.md, docs/multiplatform-dart-feature-gaps.md, docs/multiplatform-dart-slice-roadmap.md, docs/multiplatform-dart-ui-fidelity.md, AGENTS.md";
let ssot_rules = "";
ssot_rules += "SOURCE OF TRUTH (mandatory):\n";
ssot_rules += "1. Product requirements — " + product_req_paths + "\n";
ssot_rules += "2. Specs — DBR/DAC/BR in specs/ (enforceable). PRODUCT.md for whole-product framing.\n";
ssot_rules += "3. Dart code under flutter/ packages and apps — implementation evidence only.\n";
ssot_rules += "PRECEDENCE: On conflict, specs (DBR/DAC/BR) win over vault prose; vault prose informs intent/scope language; both win over any legacy code (including NextJS).\n";
ssot_rules += "NextJS (web/NextJS/, residual src/) is NOT SSoT. Forbidden as acceptance: \"match Next\", \"port Next Phase X\", \"golden parity with Next tests\", cloning Next behavior without a DBR/DAC/BR or product-req citation.\n";
ssot_rules += "You may open Next only as optional historical reference if a gap note already points there — never to invent rules or override specs/product reqs.\n";

// =============================================================================
phase("Context");
// =============================================================================

let context_prompt = "";
context_prompt += "You are aligning multiplatform Dart (flutter/) with product requirements and domain specs.\n";
context_prompt += "This monorepo: flutter/packages/* (domain, db, bungie, app, …), flutter/apps/* hosts, docs/, specs/, requirements/ (Obsidian mount).\n";
context_prompt += "Use read_file and grep only. Do not invent rule IDs or GAP/DART IDs.\n\n";
context_prompt += ssot_rules + "\n";
context_prompt += "HIGH-LEVEL PRODUCT REQUIREMENTS (Obsidian ProjectTracker) — REQUIRED every alignment pass:\n";
context_prompt += "- Soft link mount: requirements/ → ProjectTracker vault (see docs/products/README.md).\n";
context_prompt += "- MUST open and use: " + product_req_paths + "\n";
context_prompt += "- " + product_req_fallback + "\n";
context_prompt += "- Product descriptions own intent, framing, scope narrative (Domains + Areas + Destiny Objects).\n";
context_prompt += "- List every vault product note you opened under sources_read (requirements/... paths).\n\n";
context_prompt += "MUST also read (all that exist):\n";
context_prompt += "- " + domain_paths + "\n";
context_prompt += "- docs/multiplatform-dart-feature-gaps.md inventory + open GAP-* rows\n";
context_prompt += "- docs/multiplatform-dart-slice-roadmap.md for DART-NNN ownership\n";
context_prompt += "- Do NOT treat web/NextJS as authoritative; skip Next unless a gap note requires a historical cite.\n\n";
if focus != "" {
    context_prompt += "FOCUS filter (prioritize related open gaps): " + focus + "\n\n";
}
context_prompt += "Produce open_gaps from: (1) Obsidian product descriptions vs Dart code, (2) feature-gap catalog, (3) domain DBR/DAC/BR contradictions, (4) incomplete DART slices.\n";
context_prompt += "status values: Gap | Partial | Done | OK | N/A.\n";
context_prompt += "Only include open items (Gap or Partial) in open_gaps unless focus names a Done item for regression check.\n";
context_prompt += "List solid_areas briefly (shipped FEAT / pure packages).\n";
context_prompt += "product_map_notes: docs/product-map/ when present; else multiplatform-dart-ui-fidelity.md.\n";
context_prompt += "sources_read: paths you actually opened (include requirements/ vault notes + specs).\n";

let ctx = agent(context_prompt, #{
    label: "context",
    capability_mode: "read-only",
    output_schema: context_schema,
});

if ctx == () || !ctx.success || ctx.output == () {
    pause("infra", "Context agent failed. Resume to retry or fix tool access.");
}

let open_gaps = ctx.output.open_gaps;
if open_gaps == () { open_gaps = []; }

log("Context: " + open_gaps.len().to_string() + " open gap rows");

// =============================================================================
phase("Probe");
// =============================================================================

// Fixed probe themes (bounded fan-out). Script enforces list; agents do not invent themes.
// host-ui-fidelity = Flutter hosts vs product/specs (not Next parity).
let themes = [
    "sets-and-occupancy",
    "builds-identity-kit",
    "synergy-links-coverage",
    "completeness-gates-ui",
    "host-ui-fidelity",
];

if focus != "" {
    // Narrow: still probe all themes but emphasize focus in prompts
    log("Probes will emphasize focus: " + focus);
}

let probe_jobs = [];
for t in themes {
    let pp = "";
    pp += "Product/domain gap probe theme: " + t + "\n";
    pp += "Read-only: grep/read_file under flutter/packages/, flutter/apps/, flutter/tool/, specs/, docs/, requirements/ (product reqs).\n";
    pp += ssot_rules + "\n";
    pp += "HIGH-LEVEL PRODUCT REQS (required): " + product_req_paths + "\n";
    pp += product_req_fallback + "\n";
    pp += "Specs: " + domain_paths + "\n";
    pp += "Also re-read docs/multiplatform-dart-feature-gaps.md and slice roadmap for this theme.\n";
    if focus != "" {
        pp += "Emphasize focus: " + focus + "\n";
    }
    pp += "Cross-check vault Domains/Areas notes for this theme against Dart code; cite requirements/... and specs/ rule IDs.\n";
    pp += "For each relevant DBR/DAC/BR/GAP/DART item in this theme, report status with evidence_path (real file under flutter/, specs/, docs/, or requirements/).\n";
    pp += "Prefer packages/domain and packages/app evidence for product rules; flutter/apps/* for host UI.\n";
    pp += "Do NOT open web/NextJS unless a feature-gap row already names a historical residual; never status a gap as Gap solely because Next differs.\n";
    pp += "Empty findings only if you searched and theme is fully OK.\n";
    pp += "suggested_fix: concrete next Dart/doc step grounded in specs/product reqs, not vague and not \"port from Next\".\n";
    pp += "theme field in output MUST be exactly: " + t + "\n";
    probe_jobs.push(#{
        prompt: pp,
        label: "probe:" + t,
        capability_mode: "read-only",
        output_schema: probe_schema,
    });
}

let probe_results = parallel(probe_jobs);

let all_findings = [];
let probe_i = 0;
for pr in probe_results {
    let expected_theme = themes[probe_i];
    if pr != () && pr.success && pr.output != () && pr.output.findings != () {
        for f in pr.output.findings {
            // annotate theme for packaging
            let row = #{
                theme: expected_theme,
                rule_id: f.rule_id,
                status: f.status,
                evidence_path: f.evidence_path,
                summary: f.summary,
                suggested_fix: f.suggested_fix,
            };
            all_findings.push(row);
        }
    } else {
        log("Probe failed or empty: " + expected_theme);
    }
    probe_i += 1;
}

log("Probes produced " + all_findings.len().to_string() + " findings");

// =============================================================================
phase("Packages");
// =============================================================================

let packages_prompt = "";
packages_prompt += "Synthesize ranked implementation packages for multiplatform Dart from product requirements + domain specs + probe findings.\n";
packages_prompt += ssot_rules + "\n";
packages_prompt += "Max packages: " + max_packages.to_string() + "\n";
packages_prompt += "Style packages as small vertical slices with hard gates (DART-NNN or pkg-* slugs).\n";
packages_prompt += "Each package: package_id (short slug), title, priority (P0/P1/P2), rule_ids, scope, out_of_scope, acceptance, estimate, touches_ui, depends_on.\n";
packages_prompt += "Prefer pure packages (flutter/packages/domain, db, app, …) then host wiring. Prefer shipping one coherent DBR/GAP cluster.\n";
packages_prompt += "Acceptance criteria MUST cite DBR/DAC/BR and/or product-req outcomes — NEVER \"match Next\" or \"Next golden parity\".\n";
packages_prompt += "Scope MUST describe Dart work under flutter/; do not prescribe porting Next files as the definition of done.\n";
packages_prompt += "Domain wins over feature specs on conflict (AGENTS.md). FEAT cutover PASS does not override open BR/DAC gaps.\n";
if focus != "" {
    packages_prompt += "Focus filter: " + focus + "\n";
}
if package_id != "" {
    packages_prompt += "REQUIRED: Include package_id exactly \"" + package_id + "\" in packages[] and set recommended_first to that id. Fully specify that package; other packages may fill remaining slots.\n";
}
packages_prompt += "\nContext open_gaps JSON:\n";
packages_prompt += json_encode(open_gaps);
packages_prompt += "\n\nProbe findings JSON:\n";
packages_prompt += json_encode(all_findings);
packages_prompt += "\n\nrecommended_first = package_id of the best next slice (must equal args package_id when provided).\n";
packages_prompt += "Do not invent rule/GAP/DART IDs not present in inputs or docs you re-read.\n";

let pkgs = agent(packages_prompt, #{
    label: "packages",
    capability_mode: "read-only",
    output_schema: packages_schema,
});

let package_list = [];
let recommended = "";
let packages_rationale = "";

if pkgs != () && pkgs.success && pkgs.output != () && pkgs.output.packages != () {
    package_list = pkgs.output.packages;
    recommended = str_or(pkgs.output.recommended_first, "");
    packages_rationale = str_or(pkgs.output.rationale, "");
} else {
    // Fallback: one package per open gap (scan still useful if synthesis fails)
    log("Package synthesis failed or incomplete — building packages from open_gaps");
    let gi = 0;
    for g in open_gaps {
        if gi >= max_packages { break; }
        let pid = "gap-" + gi.to_string();
        let title = str_or(g.theme, "Open gap");
        let pri = str_or(g.priority, "P2");
        let rids = g.rule_ids;
        if rids == () { rids = []; }
        let scope = str_or(g.gap_action, str_or(g.evidence, ""));
        package_list.push(#{
            package_id: pid,
            title: title,
            priority: pri,
            rule_ids: rids,
            scope: scope,
            out_of_scope: "Unspecified — refine with a full packages agent run",
            acceptance: "Close gap status in docs/multiplatform-dart-feature-gaps.md (and domain docs if rules change) with code evidence",
            estimate: "unknown",
            touches_ui: false,
            depends_on: [],
        });
        gi += 1;
    }
    packages_rationale = "Fallback packages derived from context open_gaps after packages agent failure.";
}

if recommended == "" && package_list.len() > 0 {
    recommended = package_list[0].package_id;
}

log("Packages: " + package_list.len().to_string() + "; recommended=" + recommended);

// Scan-only: report and stop before implement
if mode == "scan" {
    phase("Report");
    let report = "";
    report += "# Product align report (scan)\n\n";
    report += "## Summary\n\n";
    report += str_or(ctx.output.summary, "") + "\n\n";
    report += "## Recommended first\n\n";
    report += recommended + "\n\n";
    report += packages_rationale + "\n\n";
    report += "## Packages\n\n";
    for p in package_list {
        report += "### " + p.package_id + " — " + p.title + "\n";
        report += "- **Priority**: " + p.priority + "\n";
        report += "- **Rules**: " + json_encode(p.rule_ids) + "\n";
        report += "- **Scope**: " + p.scope + "\n";
        report += "- **Out of scope**: " + p.out_of_scope + "\n";
        report += "- **Acceptance**: " + p.acceptance + "\n";
        report += "- **Estimate**: " + p.estimate + "\n\n";
    }
    report += "## Open gaps (context)\n\n";
    report += json_encode(open_gaps) + "\n\n";
    report += "## Next\n\n";
    report += "Run with `mode: \"full\"` or `mode: \"implement\"` and optional `package_id`.\n";
    report += "Example args: `{ \"mode\": \"full\", \"package_id\": \"" + recommended + "\" }`\n";

    let path = write_scratch_file("align-scan-report.md", report);
    complete(#{
        mode: "scan",
        path: path,
        recommended_first: recommended,
        package_count: package_list.len(),
        packages: package_list,
    });
}

// =============================================================================
phase("Select");
// =============================================================================

let selected = package_id;
if selected == "" {
    selected = recommended;
}

// Validate selected is in package_list. Honor explicit package_id — never silently swap packages.
let selected_ok = false;
let selected_pkg = ();
for p in package_list {
    if p.package_id == selected {
        selected_ok = true;
        selected_pkg = p;
    }
}

if package_list.len() == 0 && package_id == "" {
    complete(#{
        mode: mode,
        summary: "No packages to implement — product alignment found no open work under focus.",
        packages: [],
    });
}

if !selected_ok {
    if package_id != "" {
        // Build a minimal package shell so implement still targets the requested id
        // rather than hijacking to recommended (prevents dart-070 → three-gates swaps).
        log("package_id " + package_id + " not in synthesis list; forcing requested package shell");
        selected = package_id;
        selected_pkg = #{
            package_id: package_id,
            title: package_id,
            priority: "P0",
            rule_ids: [],
            scope: "Implement package_id=" + package_id + " from product requirements (requirements/) + specs DBR/DAC/BR. Do not substitute a different package. Do not use NextJS as SSoT.",
            out_of_scope: "Other packages; NextJS ports as definition of done",
            acceptance: "Package intent met against product requirements and specs; Dart tests green; docs updated if rules/gaps close",
            estimate: "unknown",
            touches_ui: false,
            depends_on: [],
        };
        package_list.push(selected_pkg);
        selected_ok = true;
    } else if package_list.len() > 0 {
        selected = package_list[0].package_id;
        selected_pkg = package_list[0];
        log("no package_id; using first synthesized " + selected);
    } else {
        complete(#{
            mode: mode,
            summary: "No packages to implement.",
            packages: [],
        });
    }
}

if package_id == "" {
    let gate_msg = "";
    gate_msg += "Selected package: " + selected + " — " + selected_pkg.title + "\n";
    gate_msg += "Priority: " + selected_pkg.priority + "\n";
    gate_msg += "Rules: " + json_encode(selected_pkg.rule_ids) + "\n";
    gate_msg += "Scope: " + selected_pkg.scope + "\n\n";
    gate_msg += "SSoT: product requirements + specs (not NextJS).\n";
    gate_msg += "Resume to implement this package.\n";
    gate_msg += "Or re-run with args.package_id set to another package_id from the list.\n";
    await_user("user", gate_msg);
}

log("Implementing package " + selected);

// =============================================================================
phase("Plan");
// =============================================================================

let plan_prompt = "";
plan_prompt += "Write a concrete implementation plan for package_id=" + selected + " on multiplatform Dart (flutter/).\n";
plan_prompt += "You MUST implement THIS package_id only — do not substitute another package.\n";
plan_prompt += ssot_rules + "\n";
plan_prompt += "Read product reqs + specs + existing Dart code with tools before planning.\n";
plan_prompt += "Product reqs: " + product_req_paths + "\n";
plan_prompt += "Specs: " + domain_paths + "\n";
plan_prompt += "Package JSON:\n" + json_encode(selected_pkg) + "\n\n";
plan_prompt += "Related probe findings:\n" + json_encode(all_findings) + "\n\n";
plan_prompt += "steps: ordered implementation steps grounded in DBR/DAC/BR + product reqs.\n";
plan_prompt += "files: paths under flutter/packages/, flutter/apps/, flutter/tool/, specs/, docs/ only (do not plan edits under web/NextJS).\n";
plan_prompt += "tests: dart/flutter test for packages and hosts; tool/*_gate.dart as applicable. Tests assert product/spec behavior — not Next fixtures.\n";
plan_prompt += "docs: multiplatform-dart-feature-gaps.md, slice roadmap, DBR/DAC/BR if product rules change; vault product notes only if description meaning changes (requirements/ / Obsidian).\n";
plan_prompt += "product_map: use docs/product-map when present; else ui-fidelity / host notes.\n";
plan_prompt += "risks: short.\n";
plan_prompt += "Pure UI polish without product semantics stays out of domain P1/P2 (AGENTS.md); track under docs/ui-polish-tracker.md if needed.\n";

let plan = agent(plan_prompt, #{
    label: "plan",
    capability_mode: "read-only",
    output_schema: plan_schema,
});

if plan == () || !plan.success || plan.output == () {
    pause("infra", "Plan agent failed. Resume to retry.");
}

log("Plan ready for " + selected);

// Optional second gate before writes
if mode == "full" {
    let plan_gate = "";
    plan_gate += "Plan for " + selected + ":\n";
    plan_gate += json_encode(plan.output.steps) + "\n";
    plan_gate += "Files: " + json_encode(plan.output.files) + "\n";
    plan_gate += "Resume to implement. Do not commit unless args.commit=true.\n";
    await_user("user", plan_gate);
}

// =============================================================================
phase("Implement");
// =============================================================================

let impl_prompt = "";
impl_prompt += "Implement package_id=" + selected + " per the plan under flutter/. Use tools; do not skip tests.\n";
impl_prompt += "You MUST implement THIS package_id only — do not switch to a different package mid-flight.\n";
impl_prompt += ssot_rules + "\n";
impl_prompt += "Product intent: " + product_req_paths + "\n";
impl_prompt += "Specs (enforceable): " + domain_paths + "\n\n";
impl_prompt += "Package:\n" + json_encode(selected_pkg) + "\n\n";
impl_prompt += "Plan:\n" + json_encode(plan.output) + "\n\n";
impl_prompt += "Rules:\n";
impl_prompt += "1. Update domain docs (DBR/DAC/BR) in the same change when you ship a new/changed product rule; update Obsidian product notes under requirements/ when description meaning changes.\n";
impl_prompt += "2. Update docs/multiplatform-dart-feature-gaps.md (and slice roadmap) when closing GAP/DART items.\n";
impl_prompt += "3. Prefer flutter/packages/domain + app pure logic; wire flutter/apps/* only as needed.\n";
if skip_product_map {
    impl_prompt += "4. skip_product_map=true — note UI fidelity follow-up instead of product-map sync.\n";
} else {
    impl_prompt += "4. If docs/product-map exists and UI structure changes, sync it; otherwise update multiplatform-dart-ui-fidelity.md notes.\n";
}
impl_prompt += "5. Prefer pure Dart evaluators + hard gates + package tests derived from specs/product reqs — do NOT port NextJS as the design authority.\n";
impl_prompt += "6. Do not edit web/NextJS for this package unless the user explicitly asked; default is Dart-only.\n";
impl_prompt += "7. Do NOT git commit unless commit flag is true (currently " + do_commit.to_string() + ").\n";
if do_commit {
    impl_prompt += "8. If commit=true: stage only related files, conventional commit message, do not push unless user already requested push in args (not set by default).\n";
} else {
    impl_prompt += "8. Leave changes uncommitted for user review.\n";
}
impl_prompt += "9. Run focused dart/flutter tests for touched areas; fix failures you introduced.\n";
impl_prompt += "Return done=true only if acceptance criteria for THIS package are met in Dart against product/specs.\n";

let impl = agent(impl_prompt, #{
    label: "implement",
    capability_mode: "all",
    output_schema: implement_schema,
});

if impl == () || !impl.success || impl.output == () {
    pause("infra", "Implement agent failed. Resume to retry or inspect workspace.");
}

log("Implement done=" + impl.output.done.to_string());

// =============================================================================
phase("Verify");
// =============================================================================

let verify_prompt = "";
verify_prompt += "Verify implementation of package " + selected + " on multiplatform Dart (flutter/).\n";
verify_prompt += ssot_rules + "\n";
verify_prompt += "Use grep/read_file and run focused dart/flutter tests (and tool gates if relevant) via shell.\n";
verify_prompt += "Check:\n";
verify_prompt += "1. Acceptance from package is met against product requirements + specs (not Next parity), or explicitly blocked with evidence.\n";
verify_prompt += "2. Wrong package was not implemented (changed files/summary must match package_id=" + selected + ").\n";
verify_prompt += "3. Domain docs / multiplatform-dart-feature-gaps.md updated if behavior shipped.\n";
verify_prompt += "4. No bare-hash primary labels regressions if UI touched (DBR-UI-006).\n";
verify_prompt += "5. Pure package boundaries respected (domain does not import Flutter UI).\n";
verify_prompt += "Implement report:\n" + json_encode(impl.output) + "\n\n";
verify_prompt += "Plan:\n" + json_encode(plan.output) + "\n\n";
verify_prompt += "ok=false if any required check fails.\n";

let ver = agent(verify_prompt, #{
    label: "verify",
    capability_mode: "all",
    output_schema: verify_schema,
});

let verify_ok = false;
let verify_out = #{ ok: false, checks: [], failures: ["verify agent failed"], notes: [] };
if ver != () && ver.success && ver.output != () {
    verify_out = ver.output;
    verify_ok = ver.output.ok == true;
}

// =============================================================================
phase("Report");
// =============================================================================

let final_report = "";
final_report += "# Product align + implement report\n\n";
final_report += "- **Mode**: " + mode + "\n";
final_report += "- **Package**: " + selected + "\n";
final_report += "- **Implement done**: " + impl.output.done.to_string() + "\n";
final_report += "- **Verify ok**: " + verify_ok.to_string() + "\n\n";

final_report += "## Package\n\n";
final_report += json_encode(selected_pkg) + "\n\n";

final_report += "## Plan\n\n";
final_report += json_encode(plan.output) + "\n\n";

final_report += "## Implementation\n\n";
final_report += str_or(impl.output.summary, "") + "\n\n";
final_report += "- Changed files: " + json_encode(impl.output.changed_files) + "\n";
final_report += "- Tests run: " + json_encode(impl.output.tests_run) + "\n";
final_report += "- Docs updated: " + json_encode(impl.output.docs_updated) + "\n";
if impl.output.blocked != () && impl.output.blocked != "" {
    final_report += "- **Blocked**: " + impl.output.blocked + "\n";
}
final_report += "\n## Verification\n\n";
final_report += json_encode(verify_out) + "\n\n";

final_report += "## Follow-ups\n\n";
if impl.output.follow_ups != () {
    for fu in impl.output.follow_ups {
        final_report += "- " + fu + "\n";
    }
}
final_report += "\n## Other packages (not implemented)\n\n";
for p in package_list {
    if p.package_id != selected {
        final_report += "- `" + p.package_id + "`: " + p.title + " (" + p.priority + ")\n";
    }
}

final_report += "\n## How to re-run\n\n";
final_report += "```json\n";
final_report += "{ \"mode\": \"scan\" }\n";
final_report += "{ \"mode\": \"full\", \"package_id\": \"" + selected + "\", \"commit\": false }\n";
final_report += "{ \"mode\": \"implement\", \"package_id\": \"...\", \"focus\": \"optional theme\" }\n";
final_report += "```\n";

let report_path = write_scratch_file("align-implement-report.md", final_report);

complete(#{
    mode: mode,
    package_id: selected,
    implement_done: impl.output.done,
    verify_ok: verify_ok,
    path: report_path,
    changed_files: impl.output.changed_files,
    recommended_next: recommended,
});
