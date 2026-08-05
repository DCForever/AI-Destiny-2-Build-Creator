let meta = #{
    name: "area-implement",
    description: "Implement a locked area UX brief into Flutter hosts with structure verify + dual-truth shot matrix",
    when_to_use: "After area-ux-redesign has locked a brief and approved interactive HTML mockups",
    phases: [
        #{ title: "Load", detail: "load brief + mockups + rules" },
        #{ title: "Plan", detail: "file plan + tests + shot_matrix contract" },
        #{ title: "Human gate", detail: "approve plan" },
        #{ title: "Implement", detail: "Flutter code + tests + fixtures for matrix" },
        #{ title: "Verify-structure", detail: "analyze + widget/host tests only" },
        #{ title: "Review", detail: "product/UX vs brief (structure)" },
        #{ title: "Capture", detail: "Driver PNGs scored against shot_matrix" },
        #{ title: "Human capture", detail: "pause until dual_truth_ok or structure-only" },
        #{ title: "Report", detail: "ship notes + matrix status + Widgetbook backlog" },
    ],
};

let load_schema = #{
    "type": "object",
    "required": ["brief_path", "mockup_paths", "rule_ids", "hosts", "summary"],
    "properties": #{
        "brief_path": #{ "type": "string" },
        "mockup_paths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "rule_ids": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "hosts": #{ "type": "array", "maxItems": 4, "items": #{ "type": "string" } },
        "summary": #{ "type": "string" },
        "widget_test_inventory": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
    },
};

let plan_schema = #{
    "type": "object",
    "required": ["files", "tests", "acceptance", "risks", "shot_matrix"],
    "properties": #{
        "files": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "tests": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "acceptance": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "risks": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "product_map_updates": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "shot_matrix": #{
            "type": "array",
            "minItems": 1,
            "maxItems": 16,
            "items": #{
                "type": "object",
                "required": ["id", "must", "proves", "drive"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "must": #{ "type": "boolean" },
                    "proves": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
                    "drive": #{ "type": "string" },
                },
            },
        },
    },
};

let impl_schema = #{
    "type": "object",
    "required": ["changed_paths", "tests_added", "notes"],
    "properties": #{
        "changed_paths": #{ "type": "array", "maxItems": 40, "items": #{ "type": "string" } },
        "tests_added": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "notes": #{ "type": "string" },
        "fixtures_for_matrix": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

// Structure only — no Driver / PNGs here
let verify_structure_schema = #{
    "type": "object",
    "required": ["structure_ok", "analyze_ok", "tests_ok", "commands", "failures"],
    "properties": #{
        "structure_ok": #{ "type": "boolean" },
        "analyze_ok": #{ "type": "boolean" },
        "tests_ok": #{ "type": "boolean" },
        "commands": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "failures": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
    },
};

let review_schema = #{
    "type": "object",
    "required": ["matches_brief", "gaps", "widgetbook_backlog"],
    "properties": #{
        "matches_brief": #{ "type": "boolean" },
        "matches_dual_truth": #{ "type": "boolean" },
        "gaps": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "widgetbook_backlog": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "vault_note_updated": #{ "type": "boolean" },
    },
};

let capture_schema = #{
    "type": "object",
    "required": [
        "shots_dir",
        "shot_paths",
        "compare_index_path",
        "mockup_paths",
        "gaps_for_next_redesign",
        "notes",
        "dual_truth_ok",
        "matrix_coverage",
        "human_capture_required",
        "launch_method",
        "slice_status",
    ],
    "properties": #{
        "shots_dir": #{ "type": "string" },
        "shot_paths": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "compare_index_path": #{ "type": "string" },
        "mockup_paths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "gaps_for_next_redesign": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "notes": #{ "type": "string" },
        "dual_truth_ok": #{ "type": "boolean" },
        "structure_only_accepted": #{ "type": "boolean" },
        "human_capture_required": #{ "type": "boolean" },
        "launch_method": #{ "type": "string" },
        "slice_status": #{ "type": "string" },
        "matrix_coverage": #{
            "type": "array",
            "maxItems": 16,
            "items": #{
                "type": "object",
                "required": ["id", "status"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "status": #{ "type": "string" },
                    "path": #{ "type": "string" },
                    "reason": #{ "type": "string" },
                },
            },
        },
    },
};

let brief_path = if args == () { () } else { args.brief_path };
let area = if args == () { () } else { args.area };
let subarea = if args == () { () } else { args.subarea };

if brief_path == () && area == () {
    pause("verification", "Pass args.brief_path and/or args.area (+ optional subarea).");
}

let brief_arg = if brief_path == () { "(discover under docs/ux-redesign)" } else { brief_path };
let area_s = if area == () { "unknown" } else { area };
let sub_s = if subarea == () { "default" } else { subarea };

// --- Load ---
phase("Load");
let load_prompt = "";
load_prompt += "Load the locked UX brief and approved mockups for Flutter area implement. ";
load_prompt += "brief_path arg: ";
load_prompt += brief_arg;
load_prompt += "; area=";
load_prompt += area_s;
load_prompt += "; subarea=";
load_prompt += sub_s;
load_prompt += ". USE read_file/grep. Read docs/ux-redesign/README.md, docs/ux-redesign/CAPTURE.md, the brief, mockup HTML, product rules referenced, and current flutter hosts. ";
load_prompt += "Return brief_path, mockup_paths, rule_ids, hosts, summary, widget_test_inventory from brief/architect notes. ";
load_prompt += "Fail closed if mockups or brief missing.";

let loaded = agent(load_prompt, #{
    label: "load-brief",
    capability_mode: "read-only",
    agent_type: "explore",
    output_schema: load_schema,
});

if loaded == () || !loaded.success || loaded.output == () {
    complete(#{ summary: "Failed to load brief/mockups", ok: false });
}

let loaded_json = json_encode(loaded.output);

// --- Plan ---
phase("Plan");
let plan_prompt = "";
plan_prompt += "You are flutter-architect + implement planner. Produce a file-level implementation plan for: ";
plan_prompt += loaded_json;
plan_prompt += ". Map mockup regions to Flutter widgets in packages/ui_flutter and thin host wiring in apps/windows_host and apps/mobile_host as needed. ";
plan_prompt += "REQUIRED: tests array must include higher-level widget tests (cards, chips, empty states, detail pieces) plus host smoke — tests always, never optional. ";
plan_prompt += "REQUIRED: shot_matrix — structured dual-truth scenario contract (see docs/ux-redesign/CAPTURE.md). ";
plan_prompt += "Each row: id (PNG basename without .png), must (bool), proves (string tokens), drive (live-inventory|host-fixture|widget-test-only). ";
plan_prompt += "At least one must:true row. Prefer host-fixture for enhanced map, catalyst-present, enhance-note when live inventory cannot guarantee. ";
plan_prompt += "widget-test-only rows must NOT be must:true. ";
plan_prompt += "Do not change design system tokens. Do not reintroduce stripped unrelated areas. Honor purity. USE tools to inspect existing packages.";

let plan = agent(plan_prompt, #{
    label: "implement-plan",
    capability_mode: "read-only",
    agent_type: "flutter-architect",
    output_schema: plan_schema,
});

if plan == () || !plan.success || plan.output == () {
    complete(#{ summary: "Plan failed", ok: false });
}

// --- Human gate (plan) ---
phase("Human gate");
let gate = "";
gate += "Approve this implementation plan (or request changes on resume):\n";
gate += json_encode(plan.output);
gate += "\n\nshot_matrix is the dual-truth contract — every must:true id needs a real PNG after Capture.\n";
gate += "Brief/mockups: ";
gate += loaded_json;
await_user("user", gate);

// --- Implement ---
phase("Implement");
let impl_prompt = "";
impl_prompt += "Implement the approved plan for the UX brief. Plan: ";
impl_prompt += json_encode(plan.output);
impl_prompt += ". Load context: ";
impl_prompt += loaded_json;
impl_prompt += ". Write production Flutter code + unit tests + REQUIRED higher-level widget tests. ";
impl_prompt += "If shot_matrix has drive=host-fixture rows, implement fixtures/seeds/harness so Capture can drive them (document under fixtures_for_matrix). ";
impl_prompt += "Match mockup interaction model (not pixel-perfect HTML port). Reuse ui_flutter/tokens. ";
impl_prompt += "Melos root is flutter/. No secrets. No purity violations. USE tools to edit and run tests as you go.";

let impl = agent(impl_prompt, #{
    label: "implement",
    capability_mode: "all",
    agent_type: "flutter-implementor",
    output_schema: impl_schema,
});

// --- Verify-structure (no screenshots) ---
phase("Verify-structure");
let ver_prompt = "";
ver_prompt += "STRUCTURE GATE ONLY — do not launch Flutter UI or take screenshots. ";
ver_prompt += "Read docs/ux-redesign/CAPTURE.md (two gates). ";
ver_prompt += "Run dart analyze / flutter test for touched packages and hosts under flutter/. ";
ver_prompt += "Confirm widget tests exist for higher-level composables listed in the plan tests array. ";
ver_prompt += "Set analyze_ok and tests_ok from real command results. ";
ver_prompt += "structure_ok = analyze_ok AND tests_ok. ";
ver_prompt += "List commands and failures honestly. ";
ver_prompt += "Implementation notes: ";
if impl != () && impl.success { ver_prompt += json_encode(impl.output); } else { ver_prompt += "implement result missing"; }
ver_prompt += ". Plan tests: ";
ver_prompt += json_encode(plan.output.tests);
ver_prompt += ". Load: ";
ver_prompt += loaded_json;
ver_prompt += ". USE shell tools. Do NOT run flutter run foreground. Do NOT call launch_app.";

let ver = agent(ver_prompt, #{
    label: "verify-structure",
    capability_mode: "all",
    agent_type: "general-purpose",
    output_schema: verify_structure_schema,
});

if ver == () || !ver.success || ver.output == () {
    complete(#{ summary: "Structure verify failed (agent)", ok: false });
}
if ver.output.structure_ok != true {
    complete(#{
        summary: "Structure gate failed — analyze/tests not green",
        ok: false,
        verify: ver.output,
    });
}

// --- Review (structure-level) ---
phase("Review");
let rev_prompt = "";
rev_prompt += "Product/UX review vs locked brief and mockups (structure). Dual-truth shots may still be missing. ";
rev_prompt += "Load: ";
rev_prompt += loaded_json;
rev_prompt += ". Plan: ";
rev_prompt += json_encode(plan.output);
rev_prompt += ". Impl: ";
if impl != () && impl.success { rev_prompt += json_encode(impl.output); } else { rev_prompt += "n/a"; }
rev_prompt += ". Structure verify: ";
rev_prompt += json_encode(ver.output);
rev_prompt += ". Set matches_brief from structure evidence. Set matches_dual_truth=false unless you have on-disk PNGs for every must shot_matrix row (usually false here). ";
rev_prompt += "List gaps. List Widgetbook backlog use-cases (components, sub-screens, screens). ";
rev_prompt += "If ship diverged, update vault UX note under requirements/Projects/Destiny 2 Build Creator/UX/. USE tools.";

let rev = agent(rev_prompt, #{
    label: "product-ux-review",
    capability_mode: "read-write",
    agent_type: "product-manager",
    output_schema: review_schema,
});

// --- Capture (dual-truth matrix) ---
phase("Capture");

fn build_capture_prompt(loaded_json, plan_out, ver_out, rev_out, prior_cap_notes) {
    let cap_prompt = "";
    cap_prompt += "DUAL-TRUTH CAPTURE GATE. Read docs/ux-redesign/CAPTURE.md and follow it exactly. ";
    cap_prompt += "Score plan.shot_matrix — dual_truth_ok true ONLY if every must:true row is status=captured with a real PNG on disk. ";
    cap_prompt += "Never invent images. ";
    cap_prompt += "Launch rules: NEVER flutter run/attach as foreground blocking shell. Prefer Dart MCP launch_app + Driver + stop_app. ";
    cap_prompt += "Shell fallback ONLY background=true with ENABLE_FLUTTER_DRIVER + lib/main_mcp.dart; set_frame_sync false; always stop/kill. ";
    cap_prompt += "launch_method must be mcp_launch_app | background_shell | none. ";
    cap_prompt += "If launch fails, leave must-rows missing, human_capture_required=true, dual_truth_ok=false, slice_status=human-needed or capture-incomplete. ";
    cap_prompt += "matrix_coverage: one object per plan shot_matrix row {id, status:captured|missing|skipped, path?, reason?}. ";
    cap_prompt += "Write/update COMPARE.md (mockup|shot|scenario|residual) and area implementation-shots/README.md. ";
    cap_prompt += "slice_status: closed | structure-only | capture-incomplete | human-needed. ";
    cap_prompt += "structure_only_accepted=true only if user already accepted structure-only on a prior capture gate (default false). ";
    cap_prompt += "Load: ";
    cap_prompt += loaded_json;
    cap_prompt += ". Plan (includes shot_matrix): ";
    cap_prompt += json_encode(plan_out);
    cap_prompt += ". Structure verify: ";
    cap_prompt += json_encode(ver_out);
    cap_prompt += ". Review: ";
    if rev_out != () { cap_prompt += json_encode(rev_out); } else { cap_prompt += "n/a"; }
    if prior_cap_notes != () && prior_cap_notes != "" {
        cap_prompt += ". Prior capture notes / user direction: ";
        cap_prompt += prior_cap_notes;
    }
    cap_prompt += ". USE Dart MCP + file tools. Return full capture_schema.";
    cap_prompt
}

let cap = agent(build_capture_prompt(
    loaded_json,
    plan.output,
    ver.output,
    if rev != () && rev.success { rev.output } else { () },
    "",
), #{
    label: "capture-shots",
    capability_mode: "all",
    agent_type: "general-purpose",
    output_schema: capture_schema,
});

// --- Human capture gate (matrix incomplete) ---
phase("Human capture");
let capture_round = 0;
let max_capture_rounds = 4;
let dual_ok = false;
let structure_only = false;

if cap != () && cap.success && cap.output != () {
    if cap.output.dual_truth_ok == true { dual_ok = true; }
    if cap.output.structure_only_accepted == true { structure_only = true; }
}

while !dual_ok && !structure_only && capture_round < max_capture_rounds {
    capture_round += 1;
    log("Dual-truth incomplete — human capture round " + capture_round.to_string());

    let hmsg = "";
    hmsg += "DUAL-TRUTH incomplete (round ";
    hmsg += capture_round.to_string();
    hmsg += "). Structure gate already passed.\n\n";
    hmsg += "shot_matrix + coverage:\n";
    if cap != () && cap.success && cap.output != () {
        hmsg += json_encode(cap.output);
    } else {
        hmsg += "capture agent failed";
    }
    hmsg += "\n\nPROTOCOL (see docs/ux-redesign/CAPTURE.md):\n";
    hmsg += "1) Finish missing must:true PNGs (Driver or drop files under shots_dir named <id>.png), then resume.\n";
    hmsg += "2) Or accept structure-only: say you accept structure-only ship (dual-truth stays open for next redesign).\n";
    hmsg += "3) Do not claim dual-truth complete without real PNGs.\n";
    await_user("user", hmsg);

    let re_notes = "";
    re_notes += "User resumed after dual-truth gate. Re-score matrix on disk. ";
    re_notes += "If user accepted structure-only, set structure_only_accepted=true, dual_truth_ok=false, slice_status=structure-only, human_capture_required=false. ";
    re_notes += "If new PNGs exist for must rows, set dual_truth_ok accordingly. Never invent images.";

    cap = agent(build_capture_prompt(
        loaded_json,
        plan.output,
        ver.output,
        if rev != () && rev.success { rev.output } else { () },
        re_notes,
    ), #{
        label: "capture-shots-retry-" + capture_round.to_string(),
        capability_mode: "all",
        agent_type: "general-purpose",
        output_schema: capture_schema,
    });

    dual_ok = false;
    structure_only = false;
    if cap != () && cap.success && cap.output != () {
        if cap.output.dual_truth_ok == true { dual_ok = true; }
        if cap.output.structure_only_accepted == true { structure_only = true; }
    }
}

if !dual_ok && !structure_only {
    complete(#{
        summary: "Stopped: dual-truth matrix not closed and structure-only not accepted",
        ok: false,
        verify: ver.output,
        capture: if cap != () && cap.success { cap.output } else { () },
        capture_rounds: capture_round,
    });
}

// --- Report ---
phase("Report");
let report = "";
report += "# area-implement report\n\n";
report += "## Gates\n";
report += "- STRUCTURE: pass\n";
if dual_ok {
    report += "- DUAL_TRUTH: pass\n";
} else if structure_only {
    report += "- DUAL_TRUTH: structure-only (accepted)\n";
} else {
    report += "- DUAL_TRUTH: fail\n";
}
report += "\n## Load\n";
report += loaded_json;
report += "\n\n## Plan (includes shot_matrix)\n";
report += json_encode(plan.output);
report += "\n\n## Implement\n";
if impl != () && impl.success { report += json_encode(impl.output); } else { report += "failed"; }
report += "\n\n## Verify-structure\n";
report += json_encode(ver.output);
report += "\n\n## Review\n";
if rev != () && rev.success { report += json_encode(rev.output); } else { report += "failed"; }
report += "\n\n## Capture (shot_matrix coverage)\n";
if cap != () && cap.success { report += json_encode(cap.output); } else { report += "failed"; }
report += "\n\n## Next redesign\n";
report += "Start the next area-ux-redesign for this area with **mockups + implementation-shots/COMPARE.md** as dual ground truth.\n";
report += "Read docs/ux-redesign/CAPTURE.md for matrix status semantics.\n";

let path = write_scratch_file("area-implement-report.md", report);

// Best-effort: ask report agent to also write repo implement report under docs/ux-redesign
let docs_report_prompt = "";
docs_report_prompt += "Write or overwrite docs/ux-redesign/";
docs_report_prompt += area_s;
docs_report_prompt += "/ with an implement report markdown file for subarea ";
docs_report_prompt += sub_s;
docs_report_prompt += " (e.g. 001-<subarea>-implement-report.md if pattern exists). ";
docs_report_prompt += "Content basis:\n";
docs_report_prompt += report;
docs_report_prompt += "\nUSE write tools. Return path written or skip if area folder missing.";

let docs_rep = agent(docs_report_prompt, #{
    label: "write-implement-report",
    capability_mode: "read-write",
    agent_type: "general-purpose",
});

complete(#{
    summary: "Area implement finished — structure pass; dual-truth " + (if dual_ok { "pass" } else { "structure-only" }),
    ok: true,
    report: path,
    structure_ok: true,
    dual_truth_ok: dual_ok,
    structure_only_accepted: structure_only,
    verify: ver.output,
    review: if rev != () && rev.success { rev.output } else { () },
    capture: if cap != () && cap.success { cap.output } else { () },
});
