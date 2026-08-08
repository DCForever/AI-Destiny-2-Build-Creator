let meta = #{
    name: "area-ux-component",
    description: "Lightweight UX redesign for one Flutter component (not a full area): residual mock + ship code + Widgetbook → short grill → focused mock → human gate → brief",
    when_to_use: "When polishing a single ui_flutter control (e.g. WeaponInstanceStrip, CatalogPerkGrid) against residual mock/dual-truth — too small for full area-ux-redesign",
    phases: [
        #{ title: "Context", detail: "component code + residual mock + gaps + Widgetbook" },
        #{ title: "UX delta", detail: "ship vs mock deltas and locked decisions" },
        #{ title: "Mockup", detail: "focused interactive HTML for the component states" },
        #{ title: "Human gate", detail: "review until continue with workflow" },
        #{ title: "Brief", detail: "short locked component brief + implement notes" },
    ],
};

let context_schema = #{
    "type": "object",
    "required": ["summary", "component", "ship_paths", "mockup_ssot", "open_gaps", "widgetbook_paths", "deltas"],
    "properties": #{
        "summary": #{ "type": "string" },
        "component": #{ "type": "string" },
        "ship_paths": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "mockup_ssot": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "open_gaps": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "widgetbook_paths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "deltas": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "rule_ids": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
    },
};

let delta_schema = #{
    "type": "object",
    "required": ["role", "must_match_mock", "nice_to_have", "non_goals", "state_matrix", "recommended_defaults"],
    "properties": #{
        "role": #{ "type": "string" },
        "must_match_mock": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "nice_to_have": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "non_goals": #{ "type": "array", "maxItems": 10, "items": #{ "type": "string" } },
        "state_matrix": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "recommended_defaults": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
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
    "required": ["title", "slice_goal", "out_of_scope", "locked_decisions", "acceptance", "mockup_paths", "implement_notes"],
    "properties": #{
        "title": #{ "type": "string" },
        "slice_goal": #{ "type": "string" },
        "out_of_scope": #{ "type": "string" },
        "locked_decisions": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "acceptance": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
        "mockup_paths": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "implement_notes": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "widget_test_inventory": #{ "type": "array", "maxItems": 12, "items": #{ "type": "string" } },
        "widgetbook_backlog": #{ "type": "array", "maxItems": 8, "items": #{ "type": "string" } },
        "rule_ids": #{ "type": "array", "maxItems": 16, "items": #{ "type": "string" } },
    },
};

// --- args ---
// area (required), component (required), slice_goal?, out_of_scope?, hosts?
let area = if args == () { () } else { args.area };
let component = if args == () { () } else { args.component };
let slice_goal = if args == () { () } else { args.slice_goal };
let out_of_scope = if args == () { () } else { args.out_of_scope };
let hosts = if args == () { () } else { args.hosts };

if area == () || component == () {
    pause("verification", "Pass args.area and args.component (e.g. area=catalog, component=WeaponInstanceStrip). Optional: slice_goal, out_of_scope, hosts.");
}

let goal = if slice_goal == () {
    "Close dual-truth gaps for this component vs residual mock; keep Neon/Flap; Widgetbook knobs stay"
} else {
    slice_goal
};
let oos = if out_of_scope == () {
    "Full area redesign; new design system; other catalog components except required parents; host OAuth invent"
} else {
    out_of_scope
};
let host_list = if hosts == () { "windows (Widgetbook primary)" } else { json_encode(hosts) };

let area_json = json_encode(area);
let component_json = json_encode(component);
let goal_json = json_encode(goal);
let oos_json = json_encode(oos);

// --- Phase: Context ---
phase("Context");
let ctx_prompt = "";
ctx_prompt += "Lightweight COMPONENT UX context for Destiny 2 Build Creator. ";
ctx_prompt += "Area=";
ctx_prompt += area_json;
ctx_prompt += " Component=";
ctx_prompt += component_json;
ctx_prompt += " Goal=";
ctx_prompt += goal_json;
ctx_prompt += " OOS=";
ctx_prompt += oos_json;
ctx_prompt += " Hosts=";
ctx_prompt += host_list;
ctx_prompt += ". USE TOOLS (read_file/grep/list_dir). ";
ctx_prompt += "(1) Find the Flutter widget class and all call sites under flutter/packages/ui_flutter and apps/widgetbook. ";
ctx_prompt += "(2) Read residual catalog mockups under docs/ux-redesign/catalog/mockups/ for this component chrome (e.g. .inst-chip / instance-strip CSS + JS). ";
ctx_prompt += "(3) Read docs/ux-redesign/DUAL-TRUTH-GAPS.md open gaps mentioning this component. ";
ctx_prompt += "(4) List Widgetbook use cases/knobs for the component. ";
ctx_prompt += "(5) List concrete ship-vs-mock deltas (not product invention). ";
ctx_prompt += "Return structured context only. component field must equal the class name.";

let ctx = agent(ctx_prompt, #{
    label: "context",
    capability_mode: "read-only",
    agent_type: "explore",
    output_schema: context_schema,
});

if ctx == () || !ctx.success || ctx.output == () {
    complete(#{ summary: "Component context load failed", ok: false });
}

let ctx_json = json_encode(ctx.output);

// --- Phase: UX delta ---
phase("UX delta");
let ux_prompt = "";
ux_prompt += "You are a desktop/mobile UX specialist. Lightweight COMPONENT redesign only for ";
ux_prompt += component_json;
ux_prompt += " in area ";
ux_prompt += area_json;
ux_prompt += ". Goal: ";
ux_prompt += goal_json;
ux_prompt += ". Context JSON: ";
ux_prompt += ctx_json;
ux_prompt += ". Produce: must_match_mock (parity that closes dual-truth), nice_to_have, non_goals, state_matrix for Widgetbook/mock, recommended_defaults. ";
ux_prompt += "DIM is presentation North Star for Destiny data; Neon/Flap for chrome. Do NOT invent a new design system. ";
ux_prompt += "Do NOT expand scope to full Catalog redesign. role must be ux. USE tools to re-read residual mock CSS if needed.";

let ux = agent(ux_prompt, #{
    label: "ux-delta",
    capability_mode: "read-only",
    agent_type: "desktop-ui-frontend",
    output_schema: delta_schema,
});

// --- Phase: Mockup ---
phase("Mockup");
let mock_prompt = "";
mock_prompt += "Create a FOCUSED interactive HTML mockup pair for component ";
mock_prompt += component_json;
mock_prompt += " only (not full Catalog shell unless needed as thin frame). Area=";
mock_prompt += area_json;
mock_prompt += ". Goal=";
mock_prompt += goal_json;
mock_prompt += ". Context=";
mock_prompt += ctx_json;
mock_prompt += ". UX delta=";
if ux != () && ux.success && ux.output != () {
    mock_prompt += json_encode(ux.output);
} else {
    mock_prompt += "(unavailable)";
}
mock_prompt += ". Write under docs/ux-redesign/";
mock_prompt += area;
mock_prompt += "/mockups/ using names like 002-weapon-instance-strip-desktop.html and -mobile.html (pick next free 00N prefix if 002 taken). ";
mock_prompt += "Demonstrate all state_matrix states as clickable scenarios. Approximate Neon void dark. Match residual .inst-chip language when this is the instance strip. ";
mock_prompt += "No build step. USE write tools. Return desktop_path, mobile_path, flows_demonstrated, notes.";

let mock = agent(mock_prompt, #{
    label: "mockups",
    capability_mode: "read-write",
    agent_type: "web-ui-frontend",
    output_schema: mockup_schema,
});

if mock == () || !mock.success || mock.output == () {
    complete(#{ summary: "Component mockup creation failed", ok: false });
}

// --- Phase: Human gate ---
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
let max_review_rounds = 6;
let last_mock = mock.output;

while !mock_approved && review_round < max_review_rounds {
    review_round += 1;
    log("Component mockup review round " + review_round.to_string());

    let gate_msg = "";
    gate_msg += "COMPONENT MOCKUP REVIEW (";
    gate_msg += component;
    gate_msg += ", round ";
    gate_msg += review_round.to_string();
    gate_msg += ") — do not implement Flutter yet.\n\n";
    gate_msg += "Desktop: ";
    gate_msg += last_mock.desktop_path;
    gate_msg += "\nMobile: ";
    gate_msg += last_mock.mobile_path;
    gate_msg += "\n\nPROTOCOL:\n";
    gate_msg += "1) Open mockups in a browser.\n";
    gate_msg += "2) Feedback: message the chat agent (do NOT resume). UX will revise HTML.\n";
    gate_msg += "3) When done: say exactly `continue with workflow` and write docs/ux-redesign/";
    gate_msg += area;
    gate_msg += "/MOCKUP-APPROVED.md containing that phrase, then resume.\n";
    await_user("user", gate_msg);

    let check_prompt = "";
    check_prompt += "UX gate for component ";
    check_prompt += component_json;
    check_prompt += " area ";
    check_prompt += area_json;
    check_prompt += ". Mockups: ";
    check_prompt += json_encode(last_mock);
    check_prompt += ". USE tools. Read docs/ux-redesign/";
    check_prompt += area;
    check_prompt += "/MOCKUP-APPROVED.md if present. approved=true ONLY if file exists and contains 'continue with workflow' (case-insensitive). ";
    check_prompt += "If not approved: update the component HTML mockups from chat/grill feedback; action=revised. If approved: action=proceed.";

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
            log("Component mockups approved");
        } else {
            last_mock = #{
                desktop_path: review.output.desktop_path,
                mobile_path: review.output.mobile_path,
                flows_demonstrated: if review.output.flows_demonstrated != () { review.output.flows_demonstrated } else { last_mock.flows_demonstrated },
                notes: review.output.notes,
            };
            log("Component mockups revised — re-review");
        }
    }
}

if !mock_approved {
    complete(#{ summary: "Stopped: component mockups not approved", ok: false, rounds: review_round });
}

// --- Phase: Brief ---
phase("Brief");
let brief_prompt = "";
brief_prompt += "Write a SHORT locked component UX brief for ";
brief_prompt += component_json;
brief_prompt += " under docs/ux-redesign/";
brief_prompt += area;
brief_prompt += "/. Filename like 002-weapon-instance-strip-brief.md (component-slug). ";
brief_prompt += "Goal=";
brief_prompt += goal_json;
brief_prompt += " OOS=";
brief_prompt += oos_json;
brief_prompt += ". Context=";
brief_prompt += ctx_json;
brief_prompt += ". UX delta=";
if ux != () && ux.success { brief_prompt += json_encode(ux.output); } else { brief_prompt += "n/a"; }
brief_prompt += ". Approved mockups=";
brief_prompt += json_encode(last_mock);
brief_prompt += ". Include locked_decisions, acceptance, implement_notes (files in ui_flutter), widget_test_inventory, widgetbook_backlog. ";
brief_prompt += "Do not invent product rules. USE write tools. Return structured brief fields.";

let brief = agent(brief_prompt, #{
    label: "brief",
    capability_mode: "read-write",
    agent_type: "product-manager",
    output_schema: brief_schema,
});

let report = "";
report += "# area-ux-component report\n\n";
report += "Area: ";
report += area;
report += "\nComponent: ";
report += component;
report += "\n\n## Mockups\n";
report += json_encode(last_mock);
report += "\n\n## Brief\n";
if brief != () && brief.success { report += json_encode(brief.output); } else { report += "failed"; }
report += "\n\nNext: implement in flutter/packages/ui_flutter (component only) + Widgetbook + tests; ";
report += "or run area-implement with brief_path if you prefer the full implement gate.\n";

let path = write_scratch_file("area-ux-component-report.md", report);
complete(#{
    summary: "Lightweight component UX artifacts ready for implement",
    area: area,
    component: component,
    report: path,
    mockups: last_mock,
    brief: if brief != () && brief.success { brief.output } else { () },
});
