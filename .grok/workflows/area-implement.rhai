let meta = #{
    name: "area-implement",
    description: "Implement a locked area UX brief into Flutter hosts with required widget tests and verification",
    when_to_use: "After area-ux-redesign has locked a brief and approved interactive HTML mockups",
    phases: [
        #{ title: "Load", detail: "load brief + mockups + rules" },
        #{ title: "Plan", detail: "file-level implement plan + test inventory" },
        #{ title: "Human gate", detail: "approve plan" },
        #{ title: "Implement", detail: "Flutter code + tests" },
        #{ title: "Verify", detail: "analyze + tests" },
        #{ title: "Review", detail: "product/UX vs brief" },
        #{ title: "Report", detail: "ship notes + Widgetbook backlog" },
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
    "required": ["files", "tests", "acceptance", "risks"],
    "properties": #{
        "files": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "tests": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "acceptance": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "risks": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "product_map_updates": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
    },
};

let impl_schema = #{
    "type": "object",
    "required": ["changed_paths", "tests_added", "notes"],
    "properties": #{
        "changed_paths": #{ "type": "array", "maxItems": 40, "items": #{ "type": "string" } },
        "tests_added": #{ "type": "array", "maxItems": 24, "items": #{ "type": "string" } },
        "notes": #{ "type": "string" },
    },
};

let verify_schema = #{
    "type": "object",
    "required": ["analyze_ok", "tests_ok", "commands", "failures"],
    "properties": #{
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
        "gaps": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "widgetbook_backlog": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "vault_note_updated": #{ "type": "boolean" },
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
load_prompt += ". USE read_file/grep. Read docs/ux-redesign/README.md, the brief, mockup HTML, product rules referenced, and current flutter hosts. ";
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
plan_prompt += "REQUIRED: tests array must include higher-level widget tests (cards, chips, empty states, detail pieces) plus host smoke. ";
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

// --- Human gate ---
phase("Human gate");
let gate = "";
gate += "Approve this implementation plan (or request changes on resume):\n";
gate += json_encode(plan.output);
gate += "\nBrief/mockups: ";
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
impl_prompt += "Match mockup interaction model (not pixel-perfect HTML port). Reuse ui_flutter/tokens. ";
impl_prompt += "Melos root is flutter/. No secrets. No purity violations. USE tools to edit and run tests as you go.";

let impl = agent(impl_prompt, #{
    label: "implement",
    capability_mode: "all",
    agent_type: "flutter-implementor",
    output_schema: impl_schema,
});

// --- Verify ---
phase("Verify");
let ver_prompt = "";
ver_prompt += "Verify the implementation. Run dart analyze / flutter test for touched packages and hosts under flutter/. ";
ver_prompt += "Confirm widget tests exist for higher-level composables listed in the plan. ";
ver_prompt += "Implementation notes: ";
if impl != () && impl.success { ver_prompt += json_encode(impl.output); } else { ver_prompt += "implement result missing"; }
ver_prompt += ". Plan tests: ";
ver_prompt += json_encode(plan.output.tests);
ver_prompt += ". USE shell tools. Report analyze_ok, tests_ok, commands, failures honestly.";

let ver = agent(ver_prompt, #{
    label: "verify",
    capability_mode: "all",
    agent_type: "general-purpose",
    output_schema: verify_schema,
});

// --- Review ---
phase("Review");
let rev_prompt = "";
rev_prompt += "Product/UX review vs locked brief and mockups. Load: ";
rev_prompt += loaded_json;
rev_prompt += ". Plan: ";
rev_prompt += json_encode(plan.output);
rev_prompt += ". Impl: ";
if impl != () && impl.success { rev_prompt += json_encode(impl.output); } else { rev_prompt += "n/a"; }
rev_prompt += ". List gaps. List Widgetbook backlog use-cases (components, sub-screens, screens) for later Phase 6. ";
rev_prompt += "If ship diverged, update vault UX note under requirements/Projects/Destiny 2 Build Creator/UX/. USE tools.";

let rev = agent(rev_prompt, #{
    label: "product-ux-review",
    capability_mode: "read-write",
    agent_type: "product-manager",
    output_schema: review_schema,
});

// --- Report ---
phase("Report");
let report = "";
report += "# area-implement report\n\n";
report += "## Load\n";
report += loaded_json;
report += "\n\n## Plan\n";
report += json_encode(plan.output);
report += "\n\n## Implement\n";
if impl != () && impl.success { report += json_encode(impl.output); } else { report += "failed"; }
report += "\n\n## Verify\n";
if ver != () && ver.success { report += json_encode(ver.output); } else { report += "failed"; }
report += "\n\n## Review\n";
if rev != () && rev.success { report += json_encode(rev.output); } else { report += "failed"; }
report += "\n";

let path = write_scratch_file("area-implement-report.md", report);
complete(#{
    summary: "Area implement workflow finished",
    report: path,
    verify: if ver != () && ver.success { ver.output } else { () },
    review: if rev != () && rev.success { rev.output } else { () },
});
