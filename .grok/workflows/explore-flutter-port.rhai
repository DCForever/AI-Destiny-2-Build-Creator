let meta = #{
    name: "explore-flutter-port",
    description: "Explore multiplatform Dart port (Jaspr web + Flutter desktop/mobile) of Destiny 2 Build Creator: map, analyze, synthesize, verify",
    when_to_use: "When considering Flutter/Jaspr multiplatform clients or a Dart rewrite of the Destiny build app",
    phases: [
        #{ title: "Map", detail: "inventory stack, surfaces, domain, and constraints" },
        #{ title: "Analyze", detail: "parallel Flutter port dimensions" },
        #{ title: "Synthesize", detail: "options, risks, phased plan" },
        #{ title: "Verify", detail: "adversarial check on top risks" },
    ],
};

let map_schema = #{
    "type": "object",
    "required": ["summary", "surfaces", "stack", "domain_hotspots", "constraints", "non_goals"],
    "properties": #{
        "summary": #{ "type": "string" },
        "surfaces": #{
            "type": "array",
            "maxItems": 16,
            "items": #{
                "type": "object",
                "required": ["name", "role", "complexity"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "role": #{ "type": "string" },
                    "complexity": #{ "type": "string" },
                    "key_paths": #{ "type": "array", "items": #{ "type": "string" } },
                },
            },
        },
        "stack": #{
            "type": "object",
            "required": ["frontend", "backend", "data", "integrations"],
            "properties": #{
                "frontend": #{ "type": "string" },
                "backend": #{ "type": "string" },
                "data": #{ "type": "string" },
                "integrations": #{ "type": "array", "items": #{ "type": "string" } },
            },
        },
        "domain_hotspots": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["area", "why_hard", "evidence_path"],
                "properties": #{
                    "area": #{ "type": "string" },
                    "why_hard": #{ "type": "string" },
                    "evidence_path": #{ "type": "string" },
                },
            },
        },
        "constraints": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "non_goals": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
    },
};

let dimension_schema = #{
    "type": "object",
    "required": ["dimension", "findings", "flutter_mapping", "risks", "effort_band"],
    "properties": #{
        "dimension": #{ "type": "string" },
        "findings": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["claim", "evidence"],
                "properties": #{
                    "claim": #{ "type": "string" },
                    "evidence": #{ "type": "string" },
                },
            },
        },
        "flutter_mapping": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["web_piece", "flutter_approach", "notes"],
                "properties": #{
                    "web_piece": #{ "type": "string" },
                    "flutter_approach": #{ "type": "string" },
                    "notes": #{ "type": "string" },
                },
            },
        },
        "risks": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["risk", "severity", "mitigation"],
                "properties": #{
                    "risk": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "mitigation": #{ "type": "string" },
                },
            },
        },
        "effort_band": #{ "type": "string" },
        "recommendation": #{ "type": "string" },
    },
};

let plan_schema = #{
    "type": "object",
    "required": ["executive_summary", "options", "recommended_option", "phased_plan", "top_risks", "open_questions"],
    "properties": #{
        "executive_summary": #{ "type": "string" },
        "options": #{
            "type": "array",
            "maxItems": 5,
            "items": #{
                "type": "object",
                "required": ["name", "description", "pros", "cons", "fit"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "description": #{ "type": "string" },
                    "pros": #{ "type": "array", "items": #{ "type": "string" } },
                    "cons": #{ "type": "array", "items": #{ "type": "string" } },
                    "fit": #{ "type": "string" },
                },
            },
        },
        "recommended_option": #{ "type": "string" },
        "phased_plan": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["phase", "goal", "deliverables", "exit_criteria"],
                "properties": #{
                    "phase": #{ "type": "string" },
                    "goal": #{ "type": "string" },
                    "deliverables": #{ "type": "array", "items": #{ "type": "string" } },
                    "exit_criteria": #{ "type": "string" },
                },
            },
        },
        "top_risks": #{
            "type": "array",
            "maxItems": 6,
            "items": #{
                "type": "object",
                "required": ["risk", "severity", "why"],
                "properties": #{
                    "risk": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "why": #{ "type": "string" },
                },
            },
        },
        "open_questions": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "do_not_port_yet": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
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

fn trimmed(s) {
    if type_of(s) == "string" {
        s.trim();
        s
    } else {
        ""
    }
}

fn arr_len(a) {
    if a == () { 0 } else if type_of(a) == "array" { a.len() } else { 0 }
}

fn as_str(v) {
    if v == () { "" } else if type_of(v) == "string" { trimmed(v) } else { "" }
}

fn as_arr(v) {
    if v == () { [] } else if type_of(v) == "array" { v } else { [] }
}

// --- args (guard unit) ---
let focus = "";
// Default: multiplatform Dart — Jaspr for web, Flutter for desktop/mobile
let platforms = "Web (Jaspr), Windows desktop (Flutter), Android (Flutter), iOS (Flutter)";
if args != () {
    if args.focus != () { focus = trimmed(args.focus); }
    if args.platforms != () { platforms = trimmed(args.platforms); }
}

log("explore-flutter-port: focus=" + (if focus == "" { "(broad)" } else { focus }) + " platforms=" + platforms);

// =============================================================================
// Phase 1: Map current app from the repo (read-only)
// =============================================================================
phase("Map");

let map_prompt = "";
map_prompt += "You are mapping Destiny 2 Build Creator for a multiplatform Dart port feasibility study. ";
map_prompt += "Target stack direction: Web via Jaspr (Dart), Windows desktop + Android + iOS via Flutter — shared Dart packages where possible. ";
map_prompt += "This is a local-first Next.js Destiny 2 build composition app (intent → compose → equip). ";
map_prompt += "Use read-only tools (read_file, list_dir, grep). Do NOT answer from memory alone. ";
map_prompt += "Read at least: PRODUCT.md, README.md, package.json, specs/domain-business-rules.md (skim headings + key DBR), ";
map_prompt += "src/app/ (routes), src/lib/ (top-level modules), src/components/ (surfaces). ";
map_prompt += "Inventory production surfaces (build, sets, synergy, catalog, loadouts, analyze, settings), stack, ";
map_prompt += "domain hotspots that make a port hard (variants, soft guidance, optimizer, inventory pins, equip, Bungie OAuth, SQLite), ";
map_prompt += "and durable product constraints / non-goals from PRODUCT.md. ";
if focus != "" {
    map_prompt += "User focus for this exploration: " + focus + ". Emphasize map detail relevant to that focus. ";
}
map_prompt += "Target platforms of interest: " + platforms + ". ";
map_prompt += "Return structured JSON only per schema. complexity for each surface: low|medium|high|extreme. ";
map_prompt += "evidence_path must be real repo paths you opened or grepped.";

let map_r = agent(map_prompt, #{
    label: "map-app",
    capability_mode: "read-only",
    output_schema: map_schema,
});

if map_r == () || !map_r.success || map_r.output == () {
    complete(#{
        summary: "Map phase failed — cannot explore Flutter port without a grounded app inventory.",
        error: "map_failed",
    });
}

let app_map = map_r.output;
let map_surfaces = as_arr(app_map.surfaces);
let map_hotspots = as_arr(app_map.domain_hotspots);
let map_constraints = as_arr(app_map.constraints);
let map_summary = as_str(app_map.summary);
let map_stack = if app_map.stack != () { app_map.stack } else {
    #{ frontend: "", backend: "", data: "", integrations: [] }
};
log("Mapped " + map_surfaces.len().to_string() + " surfaces, " + map_hotspots.len().to_string() + " domain hotspots");

let map_json = json_encode(app_map);

// =============================================================================
// Phase 2: Parallel Flutter-oriented analyses
// =============================================================================
phase("Analyze");

let dimensions = [
    #{
        id: "architecture",
        title: "Architecture & shared Dart packages",
        brief: "Assess how cleanly domain/logic can separate from Next.js UI/API for a multiplatform Dart monorepo: shared packages + Jaspr web shell + Flutter desktop/mobile shells. Look at src/lib/* vs src/app/api/* vs components. Propose package layout (domain / data / application / jaspr_ui / flutter_ui).",
    },
    #{
        id: "data-local",
        title: "Local-first data & SQLite",
        brief: "Map better-sqlite3 + Drizzle schema/repositories to Dart (drift preferred for multiplatform). Cover web (Jaspr/wasm or IndexedDB limits) vs desktop/mobile SQLite, single-process assumptions, manifest caches, inventory sync, migration, offline-first UX.",
    },
    #{
        id: "bungie-auth",
        title: "Bungie OAuth, API, equip",
        brief: "Assess Bungie OAuth (confidential client, HTTPS localhost today), session/cookies (iron-session), inventory sync, equip/write for Jaspr web + Flutter Windows/Android/iOS. Cover redirect URIs per platform, PKCE, secret storage, no confidential client secrets in mobile/web clients.",
    },
    #{
        id: "ui-domain",
        title: "UI surfaces Jaspr vs Flutter",
        brief: "Map primary UI (Build composer, Sets, Synergy, Catalog, Settings) to Jaspr (web, desktop-class density) vs Flutter (Windows/Android/iOS). State management that can be shared (riverpod etc.). Call out what stays desktop-class on web/Windows and what must adapt for phone.",
    },
    #{
        id: "domain-logic",
        title: "Portable domain / pure Dart logic",
        brief: "Identify pure TypeScript domain (builds constraints, coverage, soft stats, exotic limits, mod energy, finish gaps, optimizer) for reimplementation in pure Dart packages shared by Jaspr and Flutter. Compare full reimplementation vs temporary Node/sidecar API during migration.",
    },
    #{
        id: "integrations",
        title: "DIM, LLM, manifest pipeline",
        brief: "Assess optional DIM export, LLM propose-for-confirm, and Bungie manifest download/entity cache for Dart multiplatform (Jaspr web + Flutter). Rank MVP vs later per platform.",
    },
];

let jobs = [];
for d in dimensions {
    let p = "";
    p += "You are a multiplatform Dart port specialist (Jaspr web + Flutter desktop/mobile) for dimension: " + d.title + ". ";
    p += d.brief + " ";
    p += "Ground every claim in this repo using read_file/grep/list_dir — open real files under src/, specs/, PRODUCT.md as needed. ";
    p += "Do not invent packages or APIs that do not fit Destiny 2 / Bungie constraints. ";
    p += "Prefer shared pure-Dart packages; UI may diverge (Jaspr for web vs Flutter widgets for Windows/Android/iOS). ";
    p += "App inventory (from a prior mapper agent — verify critical claims against the code): ";
    p += map_json;
    p += " ";
    p += "Target platforms: " + platforms + ". ";
    if focus != "" {
        p += "User focus: " + focus + ". ";
    }
    p += "Return JSON per schema. effort_band one of: S (days), M (1-3 weeks), L (1-2 months), XL (multi-month). ";
    p += "severity: low|medium|high|critical. Empty findings only if you truly inspected code and found nothing — unlikely; dig deeper first.";
    jobs.push(#{
        prompt: p,
        label: "dim:" + d.id,
        capability_mode: "read-only",
        output_schema: dimension_schema,
    });
}

let dim_results = parallel(jobs);

let analyses = [];
let i = 0;
for r in dim_results {
    let dim_id = dimensions[i].id;
    if r != () && r.success && r.output != () {
        analyses.push(r.output);
        log("Dimension OK: " + dim_id + " effort=" + as_str(r.output.effort_band));
    } else {
        log("Dimension failed/open: " + dim_id);
        analyses.push(#{
            dimension: dim_id,
            findings: [],
            flutter_mapping: [],
            risks: [#{ risk: "Analysis agent failed", severity: "medium", mitigation: "Re-run this dimension manually" }],
            effort_band: "unknown",
            recommendation: "Retry dimension analysis",
        });
    }
    i += 1;
}

let analyses_json = json_encode(analyses);

// =============================================================================
// Phase 3: Synthesize options + plan
// =============================================================================
phase("Synthesize");

let synth_prompt = "";
synth_prompt += "Synthesize a multiplatform Dart port exploration report for Destiny 2 Build Creator. ";
synth_prompt += "Platforms: Web via Jaspr (Dart), Windows desktop via Flutter, Android + iOS via Flutter, with shared pure-Dart packages. ";
synth_prompt += "You must use read-only tools to spot-check any claim that seems overconfident. ";
synth_prompt += "Compare realistic options, not hype: e.g. (1) full Dart monorepo rewrite (Jaspr+Flutter+shared domain), ";
synth_prompt += "(2) Flutter/Jaspr UI + local Node/sidecar for domain, (3) mobile companion only while web stays Next.js, ";
synth_prompt += "(4) extract pure domain to shared Dart package first then grow shells, (5) stay Next.js web and only add Flutter mobile. ";
synth_prompt += "Call out Jaspr vs Flutter web tradeoffs explicitly (user prefers Jaspr for web). ";
synth_prompt += "Product is local-first, desktop-first, Bungie OAuth + SQLite, complex domain (builds/sets/synergies/variants/optimizer/equip). ";
synth_prompt += "Preserve domain constraints: soft suggestions never auto-apply; illegal kits hard-block; private per-user data. ";
synth_prompt += "\nAPP MAP JSON:\n";
synth_prompt += map_json;
synth_prompt += "\nDIMENSION ANALYSES JSON:\n";
synth_prompt += analyses_json;
synth_prompt += "\nTarget platforms: " + platforms + ". ";
if focus != "" {
    synth_prompt += "User focus: " + focus + ". ";
}
synth_prompt += "Pick one recommended_option by name matching an options[].name. ";
synth_prompt += "phased_plan should be realistic MVP-first (auth+manifest+catalog browse before full composer). ";
synth_prompt += "do_not_port_yet: things that should stay Next.js initially (debug tools, full LLM generator, etc.). ";
synth_prompt += "Return JSON only per schema.";

let plan_r = agent(synth_prompt, #{
    label: "synthesize-plan",
    capability_mode: "read-only",
    output_schema: plan_schema,
});

if plan_r == () || !plan_r.success || plan_r.output == () {
    // Fail open with partial: still write map + analyses
    let partial = "";
    partial += "# Flutter port exploration (partial)\n\n";
    partial += "Synthesis agent failed. Raw map and dimension analyses follow as JSON.\n\n";
    partial += "## App map\n\n```json\n" + map_json + "\n```\n\n";
    partial += "## Analyses\n\n```json\n" + analyses_json + "\n```\n";
    let partial_path = write_scratch_file("flutter-port-exploration.md", partial);
    complete(#{
        summary: "Partial exploration — synthesis failed; map and analyses saved.",
        path: partial_path,
        map: app_map,
        analyses: analyses,
    });
}

let plan = plan_r.output;
let plan_recommended = as_str(plan.recommended_option);
let plan_summary = as_str(plan.executive_summary);
let plan_options = as_arr(plan.options);
let plan_phases = as_arr(plan.phased_plan);
let plan_top_risks = as_arr(plan.top_risks);
let plan_questions = as_arr(plan.open_questions);
let plan_skip = as_arr(plan.do_not_port_yet);
log("Recommended: " + plan_recommended + "; risks=" + plan_top_risks.len().to_string());

// =============================================================================
// Phase 4: Adversarial verify top risks (fail closed — unverified risks stay flagged)
// =============================================================================
phase("Verify");

let risks_to_check = [];
let ri = 0;
for risk in plan_top_risks {
    if ri < 4 {
        risks_to_check.push(risk);
    }
    ri += 1;
}

let verified_risks = [];
if risks_to_check.len() == 0 {
    log("No top risks to verify");
} else {
    let vjobs = [];
    for risk in risks_to_check {
        let vp = "";
        vp += "Adversarially verify this Flutter-port risk claim for Destiny 2 Build Creator. ";
        vp += "Read the actual codebase (src/lib, auth/oauth, db, bungie, optimizer as relevant). ";
        vp += "Set real=true ONLY if the risk is substantiated by concrete code/docs evidence you inspected. ";
        vp += "Set real=false if it is overstated, speculative, or contradicted. ";
        vp += "Risk: " + json_encode(risk) + ". ";
        vp += "Recommended option context: " + plan_recommended + ". ";
        vp += "evidence must cite file paths/symbols. Default real=false without independent evidence.";
        vjobs.push(#{
            prompt: vp,
            label: "verify-risk",
            capability_mode: "read-only",
            output_schema: verdict_schema,
        });
    }
    let verdicts = parallel(vjobs);
    let vi = 0;
    for v in verdicts {
        let original = risks_to_check[vi];
        let risk_label = as_str(original.risk);
        let sev_label = as_str(original.severity);
        if v != () && v.success && v.output != () && v.output.real == true
            && v.output.evidence != () && as_str(v.output.evidence) != "" {
            verified_risks.push(#{
                risk: risk_label,
                severity: sev_label,
                confirmed: true,
                reason: as_str(v.output.reason),
                evidence: as_str(v.output.evidence),
            });
        } else {
            let reason = "unverified";
            if v != () && v.success && v.output != () {
                reason = as_str(v.output.reason);
                if reason == "" { reason = "unverified"; }
            }
            verified_risks.push(#{
                risk: risk_label,
                severity: sev_label,
                confirmed: false,
                reason: reason,
                evidence: "",
            });
        }
        vi += 1;
    }
    log(verified_risks.len().to_string() + " risks processed");
}

// =============================================================================
// Write human-readable report to scratch
// =============================================================================
let report = "";
report += "# Multiplatform Dart port exploration — Destiny 2 Build Creator\n\n";
report += "Generated by workflow `explore-flutter-port` (Jaspr web + Flutter desktop/mobile).\n\n";
report += "- **Platforms:** " + platforms + "\n";
if focus != "" {
    report += "- **Focus:** " + focus + "\n";
}
report += "- **Recommended option:** " + plan_recommended + "\n\n";

report += "## Executive summary\n\n";
report += plan_summary + "\n\n";

report += "## Current app (map)\n\n";
report += map_summary + "\n\n";
report += "### Stack\n\n";
report += "- Frontend: " + as_str(map_stack.frontend) + "\n";
report += "- Backend: " + as_str(map_stack.backend) + "\n";
report += "- Data: " + as_str(map_stack.data) + "\n";
let stack_integs = as_arr(map_stack.integrations);
if stack_integs.len() > 0 {
    report += "- Integrations: ";
    let ii = 0;
    for integ in stack_integs {
        if ii > 0 { report += ", "; }
        report += as_str(integ);
        ii += 1;
    }
    report += "\n";
}
report += "\n### Surfaces\n\n";
for s in map_surfaces {
    report += "- **" + as_str(s.name) + "** (" + as_str(s.complexity) + "): " + as_str(s.role) + "\n";
}
report += "\n### Domain hotspots\n\n";
for h in map_hotspots {
    report += "- **" + as_str(h.area) + "**: " + as_str(h.why_hard);
    report += " (`" + as_str(h.evidence_path) + "`)\n";
}
report += "\n### Constraints\n\n";
for c in map_constraints {
    report += "- " + as_str(c) + "\n";
}
report += "\n";

report += "## Options\n\n";
for opt in plan_options {
    report += "### " + as_str(opt.name) + "\n\n";
    report += as_str(opt.description) + "\n\n";
    report += "**Fit:** " + as_str(opt.fit) + "\n\n";
    let opt_pros = as_arr(opt.pros);
    if opt_pros.len() > 0 {
        report += "Pros:\n";
        for pr in opt_pros { report += "- " + as_str(pr) + "\n"; }
        report += "\n";
    }
    let opt_cons = as_arr(opt.cons);
    if opt_cons.len() > 0 {
        report += "Cons:\n";
        for cn in opt_cons { report += "- " + as_str(cn) + "\n"; }
        report += "\n";
    }
}

report += "## Phased plan\n\n";
for ph in plan_phases {
    report += "### " + as_str(ph.phase) + " — " + as_str(ph.goal) + "\n\n";
    let dels = as_arr(ph.deliverables);
    for d in dels { report += "- " + as_str(d) + "\n"; }
    report += "\nExit: " + as_str(ph.exit_criteria) + "\n\n";
}

report += "## Dimension analyses\n\n";
for a in analyses {
    report += "### " + as_str(a.dimension) + " (effort: " + as_str(a.effort_band) + ")\n\n";
    if a.recommendation != () {
        report += as_str(a.recommendation) + "\n\n";
    }
    let a_risks = as_arr(a.risks);
    if a_risks.len() > 0 {
        report += "Risks:\n";
        for rk in a_risks {
            report += "- [" + as_str(rk.severity) + "] " + as_str(rk.risk);
            report += " — " + as_str(rk.mitigation) + "\n";
        }
        report += "\n";
    }
    let a_map = as_arr(a.flutter_mapping);
    if a_map.len() > 0 {
        report += "Mapping:\n";
        for m in a_map {
            report += "- `" + as_str(m.web_piece) + "` → " + as_str(m.flutter_approach);
            let notes = as_str(m.notes);
            if notes != "" {
                report += " (" + notes + ")";
            }
            report += "\n";
        }
        report += "\n";
    }
}

report += "## Risk verification\n\n";
if verified_risks.len() == 0 {
    report += "_No risks were adversarially verified._\n\n";
} else {
    for vr in verified_risks {
        let badge = if vr.confirmed { "CONFIRMED" } else { "NOT CONFIRMED" };
        report += "- **" + badge + "** [" + as_str(vr.severity) + "] " + as_str(vr.risk) + "\n";
        report += "  - " + as_str(vr.reason) + "\n";
        let ev = as_str(vr.evidence);
        if ev != "" {
            report += "  - Evidence: " + ev + "\n";
        }
    }
    report += "\n";
}

if plan_questions.len() > 0 {
    report += "## Open questions\n\n";
    for q in plan_questions {
        report += "- " + as_str(q) + "\n";
    }
    report += "\n";
}

if plan_skip.len() > 0 {
    report += "## Do not port yet\n\n";
    for skip in plan_skip {
        report += "- " + as_str(skip) + "\n";
    }
    report += "\n";
}

report += "---\n\n_Read-only exploration. No code was generated or migrated._\n";

let report_path = write_scratch_file("flutter-port-exploration.md", report);

complete(#{
    summary: "Flutter port exploration complete. Recommended: " + plan_recommended,
    path: report_path,
    recommended_option: plan_recommended,
    confirmed_risk_count: verified_risks.len(),
    platforms: platforms,
    focus: focus,
});
