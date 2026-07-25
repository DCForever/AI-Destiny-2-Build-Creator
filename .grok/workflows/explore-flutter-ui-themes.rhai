let meta = #{
    name: "explore-flutter-ui-themes",
    description: "Explore alternate UI treatments and color schemes for the Flutter Destiny 2 Build Creator hosts",
    when_to_use: "When comparing visual directions, palettes, density treatments, or theme variants before changing Matte Flap tokens",
    phases: [
        #{ title: "Baseline", detail: "map current Flutter visual system" },
        #{ title: "Explore", detail: "parallel treatment + palette proposals" },
        #{ title: "Critique", detail: "product-fit and constraint checks" },
        #{ title: "Synthesize", detail: "ranked comparison report" },
    ],
};

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------

let baseline_schema = #{
    "type": "object",
    "required": ["summary", "north_star", "palette", "typography", "layout_language", "key_surfaces", "constraints", "anti_references"],
    "properties": #{
        "summary": #{ "type": "string" },
        "north_star": #{ "type": "string" },
        "palette": #{
            "type": "object",
            "required": ["void_canvas", "surface", "accent", "status_lamps", "element_ink_notes"],
            "properties": #{
                "void_canvas": #{ "type": "string" },
                "surface": #{ "type": "string" },
                "accent": #{ "type": "string" },
                "status_lamps": #{ "type": "string" },
                "element_ink_notes": #{ "type": "string" },
                "light_mode_status": #{ "type": "string" },
            },
        },
        "typography": #{ "type": "string" },
        "layout_language": #{ "type": "string" },
        "key_surfaces": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["name", "path", "visual_notes"],
                "properties": #{
                    "name": #{ "type": "string" },
                    "path": #{ "type": "string" },
                    "visual_notes": #{ "type": "string" },
                },
            },
        },
        "token_paths": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "constraints": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "anti_references": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "flexibility_hooks": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
    },
};

let treatment_schema = #{
    "type": "object",
    "required": [
        "id",
        "title",
        "creative_pitch",
        "mood_keywords",
        "color_scheme",
        "ui_treatment",
        "flutter_mapping",
        "sample_surfaces",
        "pros",
        "cons",
        "risk_to_product",
        "effort_band",
        "fit_score",
    ],
    "properties": #{
        "id": #{ "type": "string" },
        "title": #{ "type": "string" },
        "creative_pitch": #{ "type": "string" },
        "mood_keywords": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "color_scheme": #{
            "type": "object",
            "required": ["background", "surface", "surface_raised", "line", "foreground", "muted", "accent", "accent_role", "danger", "success", "warning"],
            "properties": #{
                "background": #{ "type": "string" },
                "surface": #{ "type": "string" },
                "surface_raised": #{ "type": "string" },
                "line": #{ "type": "string" },
                "foreground": #{ "type": "string" },
                "muted": #{ "type": "string" },
                "accent": #{ "type": "string" },
                "accent_role": #{ "type": "string" },
                "danger": #{ "type": "string" },
                "success": #{ "type": "string" },
                "warning": #{ "type": "string" },
                "element_ink_policy": #{ "type": "string" },
                "light_variant_notes": #{ "type": "string" },
            },
        },
        "ui_treatment": #{
            "type": "object",
            "required": ["density", "library_pattern", "chrome_style", "radius_elevation", "selection_language", "typography_notes"],
            "properties": #{
                "density": #{ "type": "string" },
                "library_pattern": #{ "type": "string" },
                "chrome_style": #{ "type": "string" },
                "radius_elevation": #{ "type": "string" },
                "selection_language": #{ "type": "string" },
                "typography_notes": #{ "type": "string" },
                "mobile_adaptation": #{ "type": "string" },
            },
        },
        "flutter_mapping": #{
            "type": "object",
            "required": ["token_changes", "theme_extension_notes", "widget_kit_notes", "migration_sketch"],
            "properties": #{
                "token_changes": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
                "theme_extension_notes": #{ "type": "string" },
                "widget_kit_notes": #{ "type": "string" },
                "migration_sketch": #{ "type": "string" },
            },
        },
        "sample_surfaces": #{
            "type": "array",
            "maxItems": 6,
            "items": #{
                "type": "object",
                "required": ["surface", "look_description"],
                "properties": #{
                    "surface": #{ "type": "string" },
                    "look_description": #{ "type": "string" },
                },
            },
        },
        "pros": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "cons": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "risk_to_product": #{ "type": "string" },
        "effort_band": #{ "type": "string" },
        "fit_score": #{ "type": "string" },
        "keeps_from_baseline": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
    },
};

let critique_schema = #{
    "type": "object",
    "required": ["treatment_id", "viable", "severity", "violations", "strengths", "must_change", "verdict"],
    "properties": #{
        "treatment_id": #{ "type": "string" },
        "viable": #{ "type": "boolean" },
        "severity": #{ "type": "string" },
        "violations": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["rule", "why", "fixable"],
                "properties": #{
                    "rule": #{ "type": "string" },
                    "why": #{ "type": "string" },
                    "fixable": #{ "type": "boolean" },
                },
            },
        },
        "strengths": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
        "must_change": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
        "verdict": #{ "type": "string" },
        "a11y_notes": #{ "type": "string" },
    },
};

let report_schema = #{
    "type": "object",
    "required": [
        "executive_summary",
        "baseline_one_liner",
        "ranked_treatments",
        "recommended_next_steps",
        "do_not_do",
        "token_experiment_plan",
    ],
    "properties": #{
        "executive_summary": #{ "type": "string" },
        "baseline_one_liner": #{ "type": "string" },
        "ranked_treatments": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["rank", "id", "title", "fit", "one_liner", "when_to_pick"],
                "properties": #{
                    "rank": #{ "type": "integer" },
                    "id": #{ "type": "string" },
                    "title": #{ "type": "string" },
                    "fit": #{ "type": "string" },
                    "one_liner": #{ "type": "string" },
                    "when_to_pick": #{ "type": "string" },
                    "effort_band": #{ "type": "string" },
                },
            },
        },
        "palette_comparison_table": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["id", "background", "accent", "mood"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "background": #{ "type": "string" },
                    "accent": #{ "type": "string" },
                    "mood": #{ "type": "string" },
                },
            },
        },
        "recommended_next_steps": #{
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
        "do_not_do": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "token_experiment_plan": #{ "type": "string" },
        "hybrid_option": #{ "type": "string" },
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

fn as_display(v) {
    if v == () { "" }
    else if type_of(v) == "string" { trimmed(v) }
    else { v.to_string() }
}

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
// worktree     — multiplatform monorepo root
// host         — windows | mobile | both
// focus        — free-text emphasis (e.g. "light mode", "mobile density")
// count        — number of default directions to explore (3–6, default 5)
// directions   — optional CSV of direction ids to force (overrides default set)
// include_baseline_refine — if true, one direction is "refined current flap"

let worktree = "F:/Destiny2BuildCreator-multiplatform-dart";
let host = "both";
let focus = "";
let count = 5;
let directions_csv = "";
let include_baseline_refine = true;

if args != () {
    if args.worktree != () { worktree = trimmed(args.worktree); }
    if args.host != () { host = trimmed(args.host); }
    if args.focus != () { focus = trimmed(args.focus); }
    if args.directions != () { directions_csv = trimmed(args.directions); }
    if args.include_baseline_refine != () && args.include_baseline_refine == false {
        include_baseline_refine = false;
    }
    if args.count != () {
        if type_of(args.count) == "i64" || type_of(args.count) == "int" {
            count = args.count;
        }
    }
}
if worktree == "" { worktree = "F:/Destiny2BuildCreator-multiplatform-dart"; }
if host != "windows" && host != "mobile" && host != "both" { host = "both"; }
if count < 3 { count = 3; }
if count > 6 { count = 6; }

// Default creative directions (deterministic ordered list; take first `count`)
let default_dirs = [
    #{
        id: "refined-flap",
        title: "Refined Matte Flap (evolution)",
        brief: "Stay on Matte Flap Ledger north star but polish contrast, light mode, status/element ThemeExtension dosage, denser seals, and calmer chrome. Not a rebrand — the best version of current.",
    },
    #{
        id: "cold-graphite",
        title: "Cold Graphite Board",
        brief: "Cooler blue-gray void (not pure black), steel-less matte graphite plates, cyan-teal readiness lamp instead of amber, still square ruled boards. Test if colder field improves long sessions.",
    },
    #{
        id: "paper-ledger",
        title: "Paper Ledger (light-first)",
        brief: "Light paper board as primary experience: cream field, ink lettering, deepened amber lamps, Destiny element ink at paper contrast. Dark becomes secondary. Density stays board-not-cards.",
    },
    #{
        id: "dense-radar",
        title: "Dense Radar Console",
        brief: "Ultra-dense tactical console: tighter type scale, mono tallies dominant, thin accent only on READY/selection, higher information per row. Avoid neon sports HUD and purple AI. Still matte, still square.",
    },
    #{
        id: "soft-atelier",
        title: "Soft Atelier",
        brief: "Slightly airier compose floor with subtle raised plates, warmer neutrals, softer selection wash — without becoming SaaS cards or rounded consumer chrome. Libraries stay continuous boards.",
    },
    #{
        id: "element-chromatic",
        title: "Element Chromatic Spine",
        brief: "Keep void neutrals but let subclass/element ink drive selection channel and identity column chroma more boldly (still One Lamp for amber readiness). Explore channel lattice dosage that feels alive, not garish.",
    },
];

let dirs = [];
if directions_csv != "" {
    // Parse simple CSV of ids against default catalog
    let parts = [];
    let buf = "";
    let i = 0;
    while i < directions_csv.len() {
        let ch = directions_csv.sub_string(i, 1);
        if ch == "," {
            buf.trim();
            if buf != "" { parts.push(buf); }
            buf = "";
        } else {
            buf += ch;
        }
        i += 1;
    }
    buf.trim();
    if buf != "" { parts.push(buf); }

    for p in parts {
        let found = false;
        for d in default_dirs {
            if d.id == p {
                dirs.push(d);
                found = true;
            }
        }
        if !found {
            dirs.push(#{
                id: p,
                title: p,
                brief: "User-requested direction id `" + p + "`. Invent a coherent Flutter UI treatment + color scheme for Destiny 2 build composition that is not Matte Flap clone and not anti-reference junk.",
            });
        }
    }
} else {
    let n = 0;
    for d in default_dirs {
        if n >= count { break; }
        if d.id == "refined-flap" && !include_baseline_refine { continue; }
        dirs.push(d);
        n += 1;
    }
    // If refine skipped left us short, fill from remaining
    if dirs.len() < count {
        for d in default_dirs {
            if dirs.len() >= count { break; }
            let already = false;
            for x in dirs {
                if x.id == d.id { already = true; }
            }
            if !already { dirs.push(d); }
        }
    }
}

if dirs.len() == 0 {
    pause("verification", "No directions to explore — pass args.directions or args.count >= 3.");
}

log("explore-flutter-ui-themes: worktree=" + worktree + " host=" + host
    + " directions=" + dirs.len().to_string()
    + " focus=" + (if focus == "" { "(broad)" } else { focus }));

// =============================================================================
// Phase 1: Baseline current Flutter visual system
// =============================================================================
phase("Baseline");

let base_prompt = "";
base_prompt += "You are documenting the CURRENT Flutter visual system for Destiny 2 Build Creator. ";
base_prompt += "Monorepo: " + worktree + ". Host filter: " + host + ". ";
base_prompt += "Use read-only tools (read_file, list_dir, grep). Do NOT invent paths. ";
base_prompt += "MUST open: DESIGN.md; packages/ui_tokens/README.md; packages/ui_tokens/lib/src/colors.dart; ";
base_prompt += "packages/ui_tokens/lib/src/flap_board_layout.dart; packages/ui_flutter/ (if present) README + flap_palette/theme; ";
base_prompt += "apps/windows_host/lib/theme/flap_theme.dart; apps/mobile_host/lib/theme/flap_theme.dart; ";
base_prompt += "sample library pages (sets/synergies/builds). ";
base_prompt += "Capture north star (Matte Flap Ledger), real hexes, typography, board language, constraints, anti-references from DESIGN.md, ";
base_prompt += "and flexibility hooks already in code (ThemeExtension, tokens package, light palette constants). ";
if focus != "" {
    base_prompt += "User focus: " + focus + ". Emphasize baseline details relevant to that focus. ";
}
base_prompt += "Return structured JSON only.";

let base_r = agent(base_prompt, #{
    label: "baseline-visual",
    capability_mode: "read-only",
    output_schema: baseline_schema,
});

if base_r == () || !base_r.success || base_r.output == () {
    complete(#{
        summary: "Baseline phase failed — cannot explore alternatives without grounded current system.",
        error: "baseline_failed",
        worktree: worktree,
    });
}

let baseline = base_r.output;
let baseline_json = json_encode(baseline);
log("Baseline captured: " + as_str(baseline.north_star));

// =============================================================================
// Phase 2: Parallel treatment explorations
// =============================================================================
phase("Explore");

let jobs = [];
for d in dirs {
    let p = "";
    p += "You are a product design director proposing ONE alternate UI treatment + color scheme for the Flutter Destiny 2 Build Creator. ";
    p += "Direction id: " + d.id + ". Title: " + d.title + ". ";
    p += "Brief: " + d.brief + " ";
    p += "Monorepo: " + worktree + ". Hosts: " + host + " (Windows dual-pane boards + mobile Focus Swap). ";
    p += "Ground yourself in the CURRENT baseline (verify critical claims with read_file/grep if needed): ";
    p += baseline_json;
    p += " ";
    p += "Rules for a good proposal: ";
    p += "(1) Provide COMPLETE concrete hex color_scheme (not vague 'darker blues'). ";
    p += "(2) Destiny element ink must remain sandbox-true when used (identity/seals only) — state element_ink_policy. ";
    p += "(3) Soft guidance must never auto-apply; amber (or your lamp) is readiness/selection not every border — One Lamp spirit. ";
    p += "(4) Hard anti-references to avoid: Vault Terminal notches, brushed steel, DIM pixel-clone, purple AI gradients, sports neon floods, light SaaS card stacks for libraries. ";
    p += "(5) Map to Flutter reality: packages/ui_tokens (pure) + destiny2_ui_flutter ThemeExtension + host pages — say what changes where. ";
    p += "(6) effort_band: S (token swap hours), M (1-3 days theme+kit), L (week+ surface rewrite). ";
    p += "(7) fit_score: excellent|good|mixed|weak relative to product north star AND user goals. ";
    p += "(8) sample_surfaces must include at least Builds library + compose detail + Settings or soft coverage chips. ";
    if focus != "" {
        p += "User focus: " + focus + ". Bias the proposal toward that. ";
    }
    p += "Be creative but implementable. Return JSON only per schema. id must equal " + d.id + ".";
    jobs.push(#{
        prompt: p,
        label: "explore:" + d.id,
        capability_mode: "read-only",
        output_schema: treatment_schema,
    });
}

let explore_results = parallel(jobs);

let treatments = [];
let ei = 0;
for r in explore_results {
    let dir = dirs[ei];
    if r != () && r.success && r.output != () {
        // Normalize id if agent drifted
        let t = r.output;
        if as_str(t.id) == "" {
            t.id = dir.id;
        }
        treatments.push(t);
    } else {
        log("Explore failed for direction: " + dir.id);
    }
    ei += 1;
}

if treatments.len() == 0 {
    complete(#{
        summary: "All exploration agents failed.",
        error: "explore_failed",
        worktree: worktree,
    });
}

log("Explored " + treatments.len().to_string() + " treatments");
let treatments_json = json_encode(treatments);

// =============================================================================
// Phase 3: Critique each treatment (fail-closed on non-viable product breaks)
// =============================================================================
phase("Critique");

let cjobs = [];
for t in treatments {
    let tid = as_str(t.id);
    let tjson = json_encode(t);
    let cp = "";
    cp += "You are a skeptical product design reviewer for Destiny 2 Build Creator Flutter. ";
    cp += "Critique this proposed UI treatment. Default viable=false if it breaks hard product rules. ";
    cp += "Hard rules: no soft-auto-apply semantics in chrome; Destiny element hexes stay truthful; ";
    cp += "libraries should not become elevated card stacks (Board Not Cards spirit) unless the proposal ";
    cp += "explicitly owns a deliberate alternative with clear density cost; no CLIENT_SECRET/UI secrets; ";
    cp += "avoid anti-references (steel, vault notches, purple AI, DIM clone, neon sports). ";
    cp += "Also check contrast plausibility (dark/light), One Lamp selection language, mobile Focus Swap fit, ";
    cp += "and whether Flutter token/theme mapping is realistic given packages/ui_tokens + ui_flutter. ";
    cp += "Baseline for comparison: ";
    cp += baseline_json;
    cp += " ";
    cp += "Proposal: ";
    cp += tjson;
    cp += " ";
    cp += "severity: none|low|medium|high|critical for worst issue. ";
    cp += "violations.fixable=true if a small tweak would make it viable. ";
    cp += "treatment_id must be " + tid + ". Return JSON only.";
    cjobs.push(#{
        prompt: cp,
        label: "critique:" + tid,
        capability_mode: "read-only",
        output_schema: critique_schema,
    });
}

let critiques = [];
let crit_results = parallel(cjobs);
let ci = 0;
for r in crit_results {
    if r != () && r.success && r.output != () {
        critiques.push(r.output);
    } else {
        // Fail open for missing critique — mark as unknown
        let tid = as_str(treatments[ci].id);
        critiques.push(#{
            treatment_id: tid,
            viable: true,
            severity: "low",
            violations: [],
            strengths: ["Critique agent failed; treated as provisional"],
            must_change: [],
            verdict: "Critique unavailable — do not trust without human review.",
            a11y_notes: "",
        });
        log("Critique missing for " + tid + " — provisional pass");
    }
    ci += 1;
}

let critiques_json = json_encode(critiques);

// =============================================================================
// Phase 4: Synthesize ranked report
// =============================================================================
phase("Synthesize");

let syn = "";
syn += "You are synthesizing a Flutter UI treatment exploration report for Destiny 2 Build Creator. ";
syn += "Worktree: " + worktree + ". Host: " + host + ". ";
syn += "Combine baseline, parallel proposals, and critiques into a ranked comparison. ";
syn += "Prefer treatments that are creative yet implementable via ui_tokens + ThemeExtension without rewriting domain. ";
syn += "Down-rank proposals that violate element-ink truth, One Lamp, or Board Not Cards without a strong alternative story. ";
syn += "If refined-flap scores high, say so — staying is valid. ";
syn += "\n\nBASELINE:\n";
syn += baseline_json;
syn += "\n\nTREATMENTS:\n";
syn += treatments_json;
syn += "\n\nCRITIQUES:\n";
syn += critiques_json;
syn += "\n\n";
if focus != "" {
    syn += "User focus: " + focus + ". ";
}
syn += "rank starts at 1 (best). fit: excellent|good|mixed|weak. effort_band: S|M|L. ";
syn += "token_experiment_plan: concrete steps to A/B in code (branch, swap FlapColorTokens, ThemeExtension, screenshot hosts). ";
syn += "hybrid_option: optional mix of best ideas. Return JSON only.";

let syn_r = agent(syn, #{
    label: "synthesize-ui-explore",
    capability_mode: "read-only",
    output_schema: report_schema,
});

if syn_r == () || !syn_r.success || syn_r.output == () {
    let fb = "";
    fb += "# Flutter UI Treatment Exploration (partial)\n\n";
    fb += "Synthesis failed. Raw treatment ids:\n\n";
    for t in treatments {
        fb += "- **" + as_str(t.id) + "**: " + as_str(t.title) + " — " + as_str(t.creative_pitch) + "\n";
    }
    let path = write_scratch_file("flutter-ui-themes-explore.md", fb);
    complete(#{
        summary: "Partial exploration: synthesis failed; " + treatments.len().to_string() + " treatments drafted.",
        path: path,
        treatments: treatments,
        critiques: critiques,
        error: "synthesize_failed",
    });
}

let report = syn_r.output;

// Markdown artifact
let md = "";
md += "# Flutter UI Treatments & Color Schemes\n\n";
md += "**Worktree:** `" + worktree + "` · **Host:** `" + host + "`\n\n";
md += as_str(report.executive_summary) + "\n\n";
md += "## Baseline\n\n";
md += as_str(report.baseline_one_liner) + "\n\n";
md += "## Ranked treatments\n\n";
for r in as_arr(report.ranked_treatments) {
    md += "### " + as_display(r.rank) + ". " + as_str(r.title)
        + " (`" + as_str(r.id) + "`) — " + as_str(r.fit) + "\n\n";
    md += as_str(r.one_liner) + "\n\n";
    md += "- **When to pick:** " + as_str(r.when_to_pick) + "\n";
    if as_str(r.effort_band) != "" {
        md += "- **Effort:** " + as_str(r.effort_band) + "\n";
    }
    md += "\n";
}

md += "## Palette comparison\n\n";
md += "| Id | Background | Accent | Mood |\n|----|------------|--------|------|\n";
for row in as_arr(report.palette_comparison_table) {
    md += "| " + as_str(row.id) + " | " + as_str(row.background)
        + " | " + as_str(row.accent) + " | " + as_str(row.mood) + " |\n";
}
md += "\n";

// Append detailed proposals (json blocks — safe with stub/canned outputs)
md += "## Detailed proposals\n\n";
for t in treatments {
    md += "### " + as_str(t.id) + " — " + as_str(t.title) + "\n\n";
    md += as_str(t.creative_pitch) + "\n\n";
    md += "```json\n" + json_encode(t) + "\n```\n\n";
    md += "Fit: " + as_str(t.fit_score) + " · Effort: " + as_str(t.effort_band)
        + " · Risk: " + as_str(t.risk_to_product) + "\n\n";
}

md += "## Critiques\n\n";
for c in critiques {
    md += "### " + as_str(c.treatment_id)
        + " — viable=" + (if c.viable == true { "yes" } else { "no" })
        + " (" + as_str(c.severity) + ")\n\n";
    md += as_str(c.verdict) + "\n\n";
    md += "```json\n" + json_encode(c) + "\n```\n\n";
}

md += "## Recommended next steps\n\n";
for a in as_arr(report.recommended_next_steps) {
    md += "1. **" + as_str(a.action) + "** (" + as_str(a.effort_band) + ") — "
        + as_str(a.why) + "\n";
}
md += "\n## Token experiment plan\n\n";
md += as_str(report.token_experiment_plan) + "\n\n";
if as_str(report.hybrid_option) != "" {
    md += "## Hybrid option\n\n";
    md += as_str(report.hybrid_option) + "\n\n";
}
md += "## Do not do\n\n";
for dnc in as_arr(report.do_not_do) {
    md += "- " + as_str(dnc) + "\n";
}
md += "\n---\n_Explored " + treatments.len().to_string() + " directions · focus: "
    + (if focus == "" { "broad" } else { focus }) + "_\n";

let report_path = write_scratch_file("flutter-ui-themes-explore.md", md);

// Best rank id for complete summary
let top_id = "";
let top_title = "";
let ranked = as_arr(report.ranked_treatments);
if ranked.len() > 0 {
    top_id = as_str(ranked[0].id);
    top_title = as_str(ranked[0].title);
}

complete(#{
    summary: "Explored " + treatments.len().to_string() + " Flutter UI treatments"
        + (if top_title != "" { "; top pick: " + top_title } else { "" }),
    path: report_path,
    worktree: worktree,
    host: host,
    treatment_count: treatments.len(),
    top_pick_id: top_id,
    top_pick_title: top_title,
    report: report,
    treatments: treatments,
    critiques: critiques,
});
