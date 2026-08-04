let meta = #{
    name: "area-ux-redesign",
    description: "Product + UX redesign for one Flutter area/slice: grill, interactive HTML mockups, human gate, architect, Obsidian UX note",
    when_to_use: "When redesigning Catalog, Sets, Build, Synergy, Loadouts, Shell, or any subarea UX before implementing Flutter UI",
    phases: [
        #{ title: "Context", detail: "load product + map + design system + host code" },
        #{ title: "Product", detail: "product-manager grill questions" },
        #{ title: "UX", detail: "UX grill + mockup state matrix" },
        #{ title: "Mockups", detail: "interactive HTML mockups desktop+mobile" },
        #{ title: "Human gate", detail: "review loop until user says continue with workflow" },
        #{ title: "Synthesis", detail: "lock brief only after mockup approval" },
        #{ title: "Architect", detail: "structure + widget test inventory" },
        #{ title: "Verify", detail: "adversarial product/UX/arch checks" },
        #{ title: "Docs", detail: "repo brief + Obsidian UX note" },
    ],
};

let context_schema = #{
    "type": "object",
    "required": ["summary", "product_sources", "rule_ids", "surfaces", "host_code_notes", "design_system_notes"],
    "properties": #{
        "summary": #{ "type": "string" },
        "product_sources": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "rule_ids": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "surfaces": #{ "type": "array", "maxItems": 20, "items": #{ "type": "string" } },
        "host_code_notes": #{ "type": "string" },
        "design_system_notes": #{ "type": "string" },
        "constraints": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "prior_implementation_shots": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "prior_compare_index": #{ "type": "string" },
    },
};

let grill_schema = #{
    "type": "object",
    "required": ["role", "questions", "must_challenge", "non_goals"],
    "properties": #{
        "role": #{ "type": "string" },
        "questions": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["id", "question", "why_it_matters", "recommended_default"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "question": #{ "type": "string" },
                    "why_it_matters": #{ "type": "string" },
                    "recommended_default": #{ "type": "string" },
                    "options": #{ "type": "array", "maxItems": 6, "items": #{ "type": "string" } },
                },
            },
        },
        "must_challenge": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "non_goals": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "mockup_state_matrix": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

let mockup_schema = #{
    "type": "object",
    "required": ["desktop_path", "mobile_path", "flows_demonstrated", "notes"],
    "properties": #{
        "desktop_path": #{ "type": "string" },
        "mobile_path": #{ "type": "string" },
        "flows_demonstrated": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "notes": #{ "type": "string" },
    },
};

let brief_schema = #{
    "type": "object",
    "required": ["title", "slice_goal", "out_of_scope", "locked_decisions", "surfaces", "acceptance", "mockup_paths", "obsidian_path"],
    "properties": #{
        "title": #{ "type": "string" },
        "slice_goal": #{ "type": "string" },
        "out_of_scope": #{ "type": "string" },
        "locked_decisions": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "surfaces": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "acceptance": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "mockup_paths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "obsidian_path": #{ "type": "string" },
        "rule_ids": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
    },
};

let arch_schema = #{
    "type": "object",
    "required": ["package_placement", "widget_inventory", "widget_test_inventory", "risks", "anti_bloat"],
    "properties": #{
        "package_placement": #{ "type": "string" },
        "widget_inventory": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "widget_test_inventory": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "risks": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "anti_bloat": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
    },
};

let verdict_schema = #{
    "type": "object",
    "required": ["ok", "issues"],
    "properties": #{
        "ok": #{ "type": "boolean" },
        "issues": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

// --- args ---
let area = if args == () { () } else { args.area };
let subarea = if args == () { () } else { args.subarea };
let slice_goal = if args == () { () } else { args.slice_goal };
let out_of_scope = if args == () { () } else { args.out_of_scope };
let hosts = if args == () { () } else { args.hosts };

if area == () {
    pause("verification", "Pass args.area (e.g. catalog). Optional: subarea, slice_goal, out_of_scope, hosts.");
}

let sub = if subarea == () { "default" } else { subarea };
let goal = if slice_goal == () { "Redesign the area slice for product-correct UX" } else { slice_goal };
let oos = if out_of_scope == () { "Anything not in slice_goal; do not invent a new design system" } else { out_of_scope };
let host_list = if hosts == () { "windows and mobile" } else { json_encode(hosts) };

let area_json = json_encode(area);
let sub_json = json_encode(sub);
let goal_json = json_encode(goal);
let oos_json = json_encode(oos);

// --- Phase: Context ---
phase("Context");
let ctx_prompt = "";
ctx_prompt += "You are gathering redesign context for Flutter area ";
ctx_prompt += area_json;
ctx_prompt += " subarea ";
ctx_prompt += sub_json;
ctx_prompt += ". Slice goal: ";
ctx_prompt += goal_json;
ctx_prompt += ". Out of scope: ";
ctx_prompt += oos_json;
ctx_prompt += ". Hosts: ";
ctx_prompt += host_list;
ctx_prompt += ". USE TOOLS: read_file/grep/list_dir. Read (1) requirements/Projects/Destiny 2 Build Creator/Areas for matching Area note ";
ctx_prompt += "(or absolute vault path if requirements missing), (2) Destiny Objects if gear-related, (3) PRODUCT.md, ";
ctx_prompt += "(4) docs/product-map/surfaces.yaml + flows.yaml for this area, (5) specs BR-CAT / DBR-ROLL / DBR-UI as relevant, ";
ctx_prompt += "(6) flutter/packages/ui_flutter and ui_tokens README/exports, (7) current host code under flutter/apps/windows_host and mobile_host, ";
ctx_prompt += "(8) **required for iteration** — prior implementation screenshots beside mockups: list_dir docs/ux-redesign/<area>/implementation-shots/ and read any COMPARE.md; ";
ctx_prompt += "include shot paths in prior_implementation_shots and compare index path in prior_compare_index (empty array/string if none yet). ";
ctx_prompt += "Next-round mockups must react to deltas between prior mockups and those shots (not mockups alone). ";
ctx_prompt += "Do not invent product rules. Return structured context only.";

let ctx = agent(ctx_prompt, #{
    label: "context",
    capability_mode: "read-only",
    agent_type: "explore",
    output_schema: context_schema,
});

if ctx == () || !ctx.success || ctx.output == () {
    complete(#{ summary: "Context load failed", ok: false });
}

let ctx_json = json_encode(ctx.output);

// --- Phase: Product grill ---
phase("Product");
let prod_prompt = "";
prod_prompt += "You are the product-manager for Destiny 2 Build Creator. Area=";
prod_prompt += area_json;
prod_prompt += " subarea=";
prod_prompt += sub_json;
prod_prompt += " goal=";
prod_prompt += goal_json;
prod_prompt += ". Context JSON: ";
prod_prompt += ctx_json;
prod_prompt += ". Produce a GRILL for the human product owner: hard questions that refine scope. ";
prod_prompt += "Challenge feature creep, Catalog-as-home, lite forks of Sets/Synergy lifecycles, and primary-job drift (DBR-PUR-002). ";
prod_prompt += "If prior_implementation_shots exist in context, grill residuals (mock vs ship gaps) before inventing new chrome. ";
prod_prompt += "Include recommended_default per question. List non_goals. role must be product. USE tools if you need to re-check Area notes or DBR/BR IDs.";

let prod = agent(prod_prompt, #{
    label: "product-grill",
    capability_mode: "read-only",
    agent_type: "product-manager",
    output_schema: grill_schema,
});

// --- Phase: UX grill ---
phase("UX");
let ux_prompt = "";
ux_prompt += "You are a UX specialist (desktop + mobile) for this Flutter product. Area=";
ux_prompt += area_json;
ux_prompt += " subarea=";
ux_prompt += sub_json;
ux_prompt += " goal=";
ux_prompt += goal_json;
ux_prompt += ". Context: ";
ux_prompt += ctx_json;
ux_prompt += ". Product grill (may be incomplete): ";
if prod != () && prod.success && prod.output != () {
    ux_prompt += json_encode(prod.output);
} else {
    ux_prompt += "(product grill unavailable)";
}
ux_prompt += ". Produce UX grill questions AND a mockup_state_matrix (signed-out, empty sync, loading, results, no matches, detail, stubs disabled, errors). ";
ux_prompt += "DIM is North Star for Destiny data presentation (DBR-UI-001); shell is Matte/Neon brand chrome. ";
ux_prompt += "Do NOT invent a new design system — compose existing Neon/Flap language. role must be ux. USE tools to read ui_flutter tokens and DIM refs under docs/dim-reference-screenshots/README.md.";

let ux = agent(ux_prompt, #{
    label: "ux-grill",
    capability_mode: "read-only",
    agent_type: "desktop-ui-frontend",
    output_schema: grill_schema,
});

// --- Phase: Mockups ---
phase("Mockups");
let mock_prompt = "";
mock_prompt += "Create simple INTERACTIVE HTML mockups for area ";
mock_prompt += area_json;
mock_prompt += " / ";
mock_prompt += sub_json;
mock_prompt += " goal ";
mock_prompt += goal_json;
mock_prompt += ". Hosts: ";
mock_prompt += host_list;
mock_prompt += ". Context: ";
mock_prompt += ctx_json;
mock_prompt += ". UX grill: ";
if ux != () && ux.success && ux.output != () {
    mock_prompt += json_encode(ux.output);
} else {
    mock_prompt += "(ux grill unavailable)";
}
mock_prompt += ". Write self-contained HTML files under docs/ux-redesign/";
mock_prompt += area;
mock_prompt += "/mockups/ with desktop and mobile variants (e.g. 001-";
mock_prompt += sub;
mock_prompt += "-desktop.html and -mobile.html). ";
mock_prompt += "Requirements: clickable facet chips (off/include/exclude cycle if filters apply), search, select item to detail, empty/error states, DISABLED stub CTAs with honest product copy when outbound areas do not exist. ";
mock_prompt += "If prior_implementation_shots / prior_compare_index are present in context, treat them as ship ground truth: mockups must close residual gaps from COMPARE.md (structure + interaction), not redesign only from old HTML. ";
mock_prompt += "Approximate Neon void dark palette; icon-first density; no new brand. No build step. USE write/search_replace tools. Return paths and flows_demonstrated.";

let mock = agent(mock_prompt, #{
    label: "mockups",
    capability_mode: "read-write",
    agent_type: "web-ui-frontend",
    output_schema: mockup_schema,
});

if mock == () || !mock.success || mock.output == () {
    complete(#{ summary: "Mockup creation failed", ok: false });
}

// --- Phase: Human gate (re-review loop) ---
// Protocol:
// - Feedback: user messages the chat agent (do NOT resume). Agent updates mockups.
// - Approve: user says "continue with workflow" AND writes MOCKUP-APPROVED.md, then resume.
// Resume without approval file → UX agent applies any grill feedback and waits again.
phase("Human gate");
let review_schema = #{
    "type": "object",
    "required": ["approved", "action", "notes", "desktop_path", "mobile_path"],
    "properties": #{
        "approved": #{ "type": "boolean" },
        "action": #{ "type": "string" },
        "notes": #{ "type": "string" },
        "desktop_path": #{ "type": "string" },
        "mobile_path": #{ "type": "string" },
        "flows_demonstrated": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

let mock_approved = false;
let review_round = 0;
let max_review_rounds = 8;
let last_mock = mock.output;

while !mock_approved && review_round < max_review_rounds {
    review_round += 1;
    log("Mockup review round " + review_round.to_string());

    let gate_msg = "";
    gate_msg += "MOCKUP REVIEW (round ";
    gate_msg += review_round.to_string();
    gate_msg += ") — do not implement Flutter yet.\n\n";
    gate_msg += "Desktop: ";
    gate_msg += last_mock.desktop_path;
    gate_msg += "\nMobile: ";
    gate_msg += last_mock.mobile_path;
    gate_msg += "\n\nPROTOCOL:\n";
    gate_msg += "1) Open mockups in a browser and exercise flows.\n";
    gate_msg += "2) To request changes: message the chat agent with feedback. Do NOT resume this workflow.\n";
    gate_msg += "   The UX agent will evaluate feedback, update HTML mockups, and you re-review.\n";
    gate_msg += "3) Only when you are done reviewing, say exactly: continue with workflow\n";
    gate_msg += "   and ensure docs/ux-redesign/";
    gate_msg += area;
    gate_msg += "/MOCKUP-APPROVED.md exists containing that phrase, then resume this run.\n";
    gate_msg += "4) Resuming without MOCKUP-APPROVED.md returns to UX revision — does not lock the brief.\n";
    await_user("user", gate_msg);

    let check_prompt = "";
    check_prompt += "You are the UX gate for area ";
    check_prompt += area_json;
    check_prompt += " subarea ";
    check_prompt += sub_json;
    check_prompt += ". Mockup paths: ";
    check_prompt += json_encode(last_mock);
    check_prompt += ". USE tools. Read docs/ux-redesign/";
    check_prompt += area;
    check_prompt += "/MOCKUP-APPROVED.md if it exists. ";
    check_prompt += "Set approved=true ONLY if that file exists and its text contains the phrase 'continue with workflow' (case-insensitive). ";
    check_prompt += "If NOT approved: also read docs/ux-redesign/";
    check_prompt += area;
    check_prompt += "/*grill*.md and any notes; evaluate feedback; UPDATE the interactive HTML mockups under docs/ux-redesign/";
    check_prompt += area;
    check_prompt += "/mockups/ accordingly (desktop+mobile); set action=revised; return updated paths. ";
    check_prompt += "If approved: action=proceed; do not change mockups. Design system: Neon/Flap, icon-first, no new brand.";

    let review = agent(check_prompt, #{
        label: "mockup-review-" + review_round.to_string(),
        capability_mode: "read-write",
        agent_type: "web-ui-frontend",
        output_schema: review_schema,
    });

    if review != () && review.success && review.output != () {
        if review.output.approved == true {
            mock_approved = true;
            last_mock = #{
                desktop_path: review.output.desktop_path,
                mobile_path: review.output.mobile_path,
                flows_demonstrated: if review.output.flows_demonstrated != () { review.output.flows_demonstrated } else { last_mock.flows_demonstrated },
                notes: review.output.notes,
            };
            log("Mockups approved by user (MOCKUP-APPROVED.md)");
        } else {
            last_mock = #{
                desktop_path: review.output.desktop_path,
                mobile_path: review.output.mobile_path,
                flows_demonstrated: if review.output.flows_demonstrated != () { review.output.flows_demonstrated } else { last_mock.flows_demonstrated },
                notes: review.output.notes,
            };
            log("Mockups revised — another human review required");
        }
    } else {
        log("Review agent failed — another human review required");
    }
}

if !mock_approved {
    complete(#{ summary: "Stopped: mockups not approved after review rounds", ok: false, rounds: review_round });
}

// Keep mock.output shape for later phases
mock = #{ success: true, output: last_mock };

// --- Phase: Synthesis ---
phase("Synthesis");
let syn_prompt = "";
syn_prompt += "Synthesize a LOCKED UX brief for area ";
syn_prompt += area_json;
syn_prompt += " subarea ";
syn_prompt += sub_json;
syn_prompt += ". Goal: ";
syn_prompt += goal_json;
syn_prompt += ". OOS: ";
syn_prompt += oos_json;
syn_prompt += ". Context: ";
syn_prompt += ctx_json;
syn_prompt += ". Product grill: ";
if prod != () && prod.success { syn_prompt += json_encode(prod.output); } else { syn_prompt += "n/a"; }
syn_prompt += ". UX grill: ";
if ux != () && ux.success { syn_prompt += json_encode(ux.output); } else { syn_prompt += "n/a"; }
syn_prompt += ". APPROVED Mockups: ";
syn_prompt += json_encode(last_mock);
syn_prompt += ". Read docs/ux-redesign/";
syn_prompt += area;
syn_prompt += "/ grill notes and MOCKUP-APPROVED.md. Incorporate locked decisions. ";
syn_prompt += "Write markdown brief to docs/ux-redesign/";
syn_prompt += area;
syn_prompt += "/ following docs/ux-redesign/_template-area-brief.md. Link mockup paths. USE write tools.";

let brief = agent(syn_prompt, #{
    label: "synthesis",
    capability_mode: "read-write",
    agent_type: "product-manager",
    output_schema: brief_schema,
});

// --- Phase: Architect ---
phase("Architect");
let arch_prompt = "";
arch_prompt += "You are flutter-architect for this Melos workspace (flutter/). Review the UX brief and mockups for area ";
arch_prompt += area_json;
arch_prompt += ". Brief: ";
if brief != () && brief.success { arch_prompt += json_encode(brief.output); } else { arch_prompt += "missing brief"; }
arch_prompt += ". Mockups: ";
arch_prompt += json_encode(mock.output);
arch_prompt += ". Produce package_placement, widget_inventory, REQUIRED widget_test_inventory (higher-level widgets e.g. cards, facet chips, empty states — not only pure helpers), risks, anti_bloat. ";
arch_prompt += "Honor purity (domain/sandbox_data pure), keep design system, hosts thin. USE tools to inspect packages.";

let arch = agent(arch_prompt, #{
    label: "architect",
    capability_mode: "read-only",
    agent_type: "flutter-architect",
    output_schema: arch_schema,
});

// --- Phase: Verify ---
phase("Verify");
let vjobs = [];
vjobs.push(#{
    prompt: "Adversarially check product fidelity for this redesign brief/mockups. Fail if Catalog/home drift, illegal lite Set/Synergy forks, or missing hard rules. Context+brief+mockups: " + ctx_json + " | " + (if brief != () && brief.success { json_encode(brief.output) } else { "no-brief" }) + " | " + json_encode(mock.output) + ". Set ok=true only with concrete evidence you read.",
    label: "verify-product",
    capability_mode: "read-only",
    agent_type: "product-manager",
    output_schema: verdict_schema,
});
vjobs.push(#{
    prompt: "Adversarially check UX risks: chrome explosion, identity vs instance confusion, mobile/desktop gaps, stub honesty. Mockups must be interactive for core flows. Paths: " + json_encode(mock.output) + ". Read the HTML. Set ok=true only with evidence.",
    label: "verify-ux",
    capability_mode: "read-only",
    agent_type: "desktop-ui-frontend",
    output_schema: verdict_schema,
});
vjobs.push(#{
    prompt: "Adversarially check Flutter architecture risks for implementing this brief: purity, god-page risk, missing widget tests inventory. Arch: " + (if arch != () && arch.success { json_encode(arch.output) } else { "n/a" }) + ". Set ok=true only with evidence from packages layout.",
    label: "verify-arch",
    capability_mode: "read-only",
    agent_type: "flutter-architect",
    output_schema: verdict_schema,
});
let verdicts = parallel(vjobs);

// --- Phase: Docs (Obsidian) ---
phase("Docs");
let docs_prompt = "";
docs_prompt += "Document high-level UX/UI for this area in Obsidian ProjectTracker. ";
docs_prompt += "Create or update requirements/Projects/Destiny 2 Build Creator/UX/UX ";
docs_prompt += area;
docs_prompt += ".md (or UX ";
docs_prompt += area;
docs_prompt += " — ";
docs_prompt += sub;
docs_prompt += ".md for subarea). Include job, journeys, IA, key surfaces, interaction principles, desktop vs mobile, out of scope, links to repo brief and mockups. ";
docs_prompt += "Also add a short Experience link from Areas/Area ";
// Capitalize roughly via area name as-is; agent should find the file.
docs_prompt += " note if present. Brief: ";
if brief != () && brief.success { docs_prompt += json_encode(brief.output); } else { docs_prompt += "n/a"; }
docs_prompt += ". USE write tools. Return paths written.";

let docs = agent(docs_prompt, #{
    label: "obsidian-ux",
    capability_mode: "read-write",
    agent_type: "product-manager",
});

let report = "";
report += "# area-ux-redesign report\n\n";
report += "Area: ";
report += area;
report += " / ";
report += sub;
report += "\n\n## Mockups\n";
report += json_encode(mock.output);
report += "\n\n## Brief\n";
if brief != () && brief.success { report += json_encode(brief.output); } else { report += "failed"; }
report += "\n\n## Architect\n";
if arch != () && arch.success { report += json_encode(arch.output); } else { report += "failed"; }
report += "\n\n## Verdicts\n";
report += json_encode(verdicts);
report += "\n\nNext: run area-implement with brief_path pointing at the locked brief.\n";

let path = write_scratch_file("area-ux-redesign-report.md", report);
complete(#{
    summary: "UX redesign artifacts produced; human reviewed mockups",
    area: area,
    subarea: sub,
    report: path,
    mockups: mock.output,
    brief: if brief != () && brief.success { brief.output } else { () },
    architect: if arch != () && arch.success { arch.output } else { () },
});
