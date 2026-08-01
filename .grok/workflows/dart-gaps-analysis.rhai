let meta = #{
    name: "dart-gaps-analysis",
    description: "Compare Next.js product vs multiplatform Dart port; refresh feature-gap catalog and planned DART-050+ slices",
    when_to_use: "After dual-use findings or before planning next DART slices; keeps gaps documented and planned",
    phases: [
        #{ title: "Seed", detail: "load gap catalog + cutover + Next surfaces" },
        #{ title: "Scan", detail: "parallel Next vs Dart capability scans" },
        #{ title: "Plan", detail: "ensure every P0-P1 gap has a DART-NNN plan" },
        #{ title: "Write", detail: "update docs + report" },
    ],
};

let seed_schema = #{
    "type": "object",
    "required": ["worktree", "catalog_path", "known_gap_ids", "next_planned_slice", "summary"],
    "properties": #{
        "worktree": #{ "type": "string" },
        "catalog_path": #{ "type": "string" },
        "known_gap_ids": #{ "type": "array", "items": #{ "type": "string" } },
        "next_planned_slice": #{ "type": "string" },
        "summary": #{ "type": "string" },
    },
};

let scan_schema = #{
    "type": "object",
    "required": ["dimension", "findings", "new_or_updated_gaps"],
    "properties": #{
        "dimension": #{ "type": "string" },
        "findings": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["claim", "next_path", "dart_path", "severity"],
                "properties": #{
                    "claim": #{ "type": "string" },
                    "next_path": #{ "type": "string" },
                    "dart_path": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                },
            },
        },
        "new_or_updated_gaps": #{
            "type": "array",
            "maxItems": 10,
            "items": #{
                "type": "object",
                "required": ["gap_id", "title", "severity", "status", "planned_slice", "exit_criteria"],
                "properties": #{
                    "gap_id": #{ "type": "string" },
                    "title": #{ "type": "string" },
                    "severity": #{ "type": "string" },
                    "status": #{ "type": "string" },
                    "planned_slice": #{ "type": "string" },
                    "exit_criteria": #{ "type": "string" },
                    "evidence": #{ "type": "string" },
                },
            },
        },
    },
};

let plan_schema = #{
    "type": "object",
    "required": ["unplanned_p0_p1", "slice_plan", "roadmap_edits", "summary"],
    "properties": #{
        "unplanned_p0_p1": #{ "type": "array", "items": #{ "type": "string" } },
        "slice_plan": #{
            "type": "array",
            "maxItems": 20,
            "items": #{
                "type": "object",
                "required": ["dart_id", "short_name", "gap_ids", "phase", "exit_criteria"],
                "properties": #{
                    "dart_id": #{ "type": "string" },
                    "short_name": #{ "type": "string" },
                    "gap_ids": #{ "type": "array", "items": #{ "type": "string" } },
                    "phase": #{ "type": "string" },
                    "exit_criteria": #{ "type": "string" },
                },
            },
        },
        "roadmap_edits": #{ "type": "array", "items": #{ "type": "string" } },
        "summary": #{ "type": "string" },
    },
};

let write_schema = #{
    "type": "object",
    "required": ["success", "files_touched", "summary", "next_slice"],
    "properties": #{
        "success": #{ "type": "boolean" },
        "files_touched": #{ "type": "array", "items": #{ "type": "string" } },
        "summary": #{ "type": "string" },
        "next_slice": #{ "type": "string" },
        "blocker": #{ "type": "string" },
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

fn as_str(v) {
    if v == () { "" } else if type_of(v) == "string" { trimmed(v) } else { "" }
}

fn as_arr(v) {
    if v == () { [] } else if type_of(v) == "array" { v } else { [] }
}

let worktree = "F:/Destiny2BuildCreator-multiplatform-dart";
let product_root = "F:/Destiny2BuildCreator";
if args != () {
    if args.worktree != () { worktree = as_str(args.worktree); }
    if args.product_root != () { product_root = as_str(args.product_root); }
}

log("dart-gaps-analysis: worktree=" + worktree);

// =============================================================================
phase("Seed");
// =============================================================================
let seed_p = "";
seed_p += "You are seeding a Next.js vs multiplatform Dart gaps analysis. ";
seed_p += "Read with tools (read_file, list_dir, grep) — do not invent paths. ";
seed_p += "PRIMARY worktree (Dart port): " + worktree + " ";
seed_p += "PRODUCT root (Next.js): " + product_root + " ";
seed_p += "Required reads: ";
seed_p += worktree + "/docs/multiplatform-dart-feature-gaps.md (Product feature inventory FEAT-* + GAP-* tables) ; ";
seed_p += worktree + "/docs/multiplatform-dart-slice-roadmap.md (header + DART-050+ rows + Current pointer) ; ";
seed_p += worktree + "/docs/multiplatform-dart-cutover-parity-checklist.md (residual blockers + capability matrix) ; ";
seed_p += product_root + "/PRODUCT.md (capabilities) ; ";
seed_p += product_root + "/src/components/AppShell.tsx or NAV links. ";
seed_p += "Return known_gap_ids from the catalog (GAP-*), next_planned_slice (e.g. DART-050), catalog_path, summary. ";
seed_p += "In summary note whether Product feature inventory covers all AppShell keys + PRODUCT capabilities. ";
seed_p += "JSON only per schema.";

let seed_r = agent(seed_p, #{
    label: "seed-gaps",
    capability_mode: "read-only",
    output_schema: seed_schema,
});

if seed_r == () || !seed_r.success || seed_r.output == () {
    complete(#{ summary: "Seed failed", error: "seed_failed" });
}

let seed = seed_r.output;
log("Seeded gaps: " + as_arr(seed.known_gap_ids).len().to_string() + " next=" + as_str(seed.next_planned_slice));
let seed_json = json_encode(seed);

// =============================================================================
phase("Scan");
// =============================================================================
let dimensions = [
    #{
        id: "inventory-sync",
        title: "Inventory sync fidelity",
        brief: "Compare Next syncInventory/profile parse vs Dart syncUserInventory/inventory_parse. Focus vault/postmaster resolution, roll tags, socket plugs, diagnostics, owned catalog join. Windows host InventorySyncController wiring is critical.",
    },
    #{
        id: "nav-surfaces",
        title: "AppShell nav surfaces",
        brief: "Compare product NAV_LINKS (build, synergy, sets, catalog, settings, loadouts) to Windows/mobile/Jaspr hosts. Mark MISS/PARTIAL with evidence paths.",
    },
    #{
        id: "compose-equip",
        title: "Compose to equip spine",
        brief: "Hard/soft domain, equip-ready, equip, DIM, optimizer presence per shell vs Next build/equip/export.",
    },
    #{
        id: "auth-data-ops",
        title: "Auth data and ops",
        brief: "Public+PKCE vs Confidential, manifest/entity bundles, legacy db import, dual-run ops, cutover residuals RB-*.",
    },
    #{
        id: "process-gaps",
        title: "Process / evaluation gaps",
        brief: "Why thin exit criteria shipped (optional equipmentBucketLookup, no live harness). Propose PROC-* improvements already in catalog or new ones.",
    },
];

let jobs = [];
for d in dimensions {
    let p = "";
    p += "You are a product-parity analyst for dimension: " + d.title + ". ";
    p += d.brief + " ";
    p += "Use read-only tools on BOTH trees. Next root: " + product_root + " ; Dart: " + worktree + ". ";
    p += "Do not answer from memory — open real files (grep/read_file). ";
    p += "Seed context (verify claims against code): " + seed_json + " ";
    p += "Prefer reusing existing GAP-* IDs from the catalog when the finding matches. ";
    p += "New gaps only if truly absent; use GAP-INV-*, GAP-NAV-*, GAP-WEB-*, GAP-AUTH-*, GAP-OPS-*, PROC-* patterns. ";
    p += "severity: P0|P1|P2|P3. status: open|partial|planned|done|deferred|n/a. ";
    p += "planned_slice must be DART-NNN form (050+ for new work). exit_criteria must be parity-specific and testable. ";
    p += "Return JSON per schema.";
    jobs.push(#{
        prompt: p,
        label: "scan:" + d.id,
        capability_mode: "read-only",
        output_schema: scan_schema,
    });
}

let scan_results = parallel(jobs);
let scans = [];
let si = 0;
for r in scan_results {
    let dim_id = dimensions[si].id;
    if r != () && r.success && r.output != () {
        scans.push(r.output);
        log("Scan OK: " + dim_id);
    } else {
        log("Scan failed: " + dim_id);
        scans.push(#{
            dimension: dim_id,
            findings: [],
            new_or_updated_gaps: [],
        });
    }
    si += 1;
}
let scans_json = json_encode(scans);

// =============================================================================
phase("Plan");
// =============================================================================
let plan_p = "";
plan_p += "Synthesize a complete plan so every P0/P1 gap has a DART-NNN slice AND every product feature is planned. ";
plan_p += "Read " + worktree + "/docs/multiplatform-dart-feature-gaps.md (inventory + gaps) and slice-roadmap DART-050+ rows. ";
plan_p += "SEED: " + seed_json + " ";
plan_p += "SCANS: " + scans_json + " ";
plan_p += "List unplanned_p0_p1 (gap ids still without a slice). ";
plan_p += "Also note any PRODUCT/AppShell features missing from the FEAT inventory or without Plan ownership. ";
plan_p += "slice_plan: ordered DART-050… with short_name, gap_ids, phase P6|P7|P8, exit_criteria. ";
plan_p += "Prefer existing DART-050–061 if they already cover gaps; only invent DART-062+ if necessary. ";
plan_p += "roadmap_edits: bullet strings describing doc updates needed (include inventory table if incomplete). ";
plan_p += "summary: one paragraph. JSON per schema. Use tools to verify paths.";

let plan_r = agent(plan_p, #{
    label: "plan-slices",
    capability_mode: "read-only",
    output_schema: plan_schema,
});

if plan_r == () || !plan_r.success || plan_r.output == () {
    let partial = "# Gaps analysis partial\n\nPlan agent failed.\n\n## Scans\n\n```json\n" + scans_json + "\n```\n";
    let path = write_scratch_file("dart-gaps-analysis-report.md", partial);
    complete(#{ summary: "Partial — plan failed", path: path, scans: scans });
}

let plan = plan_r.output;
log("Plan: unplanned=" + as_arr(plan.unplanned_p0_p1).len().to_string() + " slices=" + as_arr(plan.slice_plan).len().to_string());
let plan_json = json_encode(plan);

// =============================================================================
phase("Write");
// =============================================================================
let write_p = "";
write_p += "You write/update planning docs in the Dart worktree only: " + worktree + " ";
write_p += "Use read-write tools. Do NOT edit " + product_root + " product branch files. ";
write_p += "\n## Required outcomes\n";
write_p += "1) Ensure docs/multiplatform-dart-feature-gaps.md has BOTH: ";
write_p += "(a) **Product feature inventory** covering AppShell nav + PRODUCT confirmed capabilities + non-goals ";
write_p += "(FEAT-* rows with Plan ownership: shipped|planned|deferred|n/a and DART slices), and ";
write_p += "(b) GAP-* master table + detailed specs for all P0/P1 from SCANS with planned DART-NNN and parity-specific exit criteria. ";
write_p += "Merge new findings into existing FEAT-*/GAP-* IDs; do not wipe tables. Update **Updated** date. ";
write_p += "Every PRODUCT capability and AppShell nav key must appear in the inventory — no undocumented features. ";
write_p += "2) Ensure docs/multiplatform-dart-slice-roadmap.md has DART-050+ planned rows for the slice_plan (add missing only). ";
write_p += "Current pointer next slice = first planned inventory/fidelity slice (usually DART-050). ";
write_p += "3) Ensure docs/multiplatform-dart-cutover-parity-checklist.md residual table references DART-050–061 / RB-06 inventory fidelity if not already. ";
write_p += "4) Soft never auto-applies; no CLIENT_SECRET. ";
write_p += "\nSEED: " + seed_json + "\nSCANS: " + scans_json + "\nPLAN: " + plan_json + "\n";
write_p += "If unplanned_p0_p1 is non-empty, create GAP rows + DART-NNN plans for each before finishing. ";
write_p += "If any PRODUCT/AppShell feature lacks inventory Plan ownership, add FEAT row + plan before finishing. ";
write_p += "Return success=true only if every open P0/P1 has a planned_slice AND feature inventory coverage is complete. next_slice e.g. DART-050. JSON per schema.";

let write_r = agent(write_p, #{
    label: "write-docs",
    capability_mode: "all",
    output_schema: write_schema,
});

let files = [];
let next_slice = as_str(seed.next_planned_slice);
let write_ok = false;
let write_summary = "write skipped";
if write_r != () && write_r.success && write_r.output != () {
    write_ok = write_r.output.success == true;
    write_summary = as_str(write_r.output.summary);
    files = as_arr(write_r.output.files_touched);
    if as_str(write_r.output.next_slice) != "" {
        next_slice = as_str(write_r.output.next_slice);
    }
    log("Write success=" + write_ok.to_string() + " next=" + next_slice);
} else {
    log("Write agent failed");
}

// Report
let report = "";
report += "# Dart gaps analysis report\n\n";
report += "- Worktree: `" + worktree + "`\n";
report += "- Product: `" + product_root + "`\n";
report += "- Write OK: " + write_ok.to_string() + "\n";
report += "- Next slice: **" + next_slice + "**\n";
report += "- Summary: " + write_summary + "\n\n";

report += "## Seed\n\n" + as_str(seed.summary) + "\n\n";
report += "## Plan summary\n\n" + as_str(plan.summary) + "\n\n";

report += "### Unplanned P0/P1 (should be empty after write)\n\n";
let unp = as_arr(plan.unplanned_p0_p1);
if unp.len() == 0 {
    report += "_None_\n\n";
} else {
    for u in unp { report += "- " + as_str(u) + "\n"; }
    report += "\n";
}

report += "### Slice plan\n\n";
for s in as_arr(plan.slice_plan) {
    report += "- **" + as_str(s.dart_id) + "** `" + as_str(s.short_name) + "` (" + as_str(s.phase) + "): ";
    report += as_str(s.exit_criteria) + "\n";
}
report += "\n### Files touched\n\n";
if files.len() == 0 {
    report += "_None reported_\n";
} else {
    for f in files { report += "- `" + as_str(f) + "`\n"; }
}
report += "\n### Scan dimensions\n\n";
for sc in scans {
    report += "#### " + as_str(sc.dimension) + "\n\n";
    for f in as_arr(sc.findings) {
        report += "- [" + as_str(f.severity) + "] " + as_str(f.claim) + "\n";
        report += "  - Next: `" + as_str(f.next_path) + "`\n";
        report += "  - Dart: `" + as_str(f.dart_path) + "`\n";
    }
    report += "\n";
}

report += "---\n\nCanonical catalog: `docs/multiplatform-dart-feature-gaps.md`\n";
report += "Roadmap: `docs/multiplatform-dart-slice-roadmap.md`\n";

let report_path = write_scratch_file("dart-gaps-analysis-report.md", report);

complete(#{
    summary: "Gaps analysis complete. next=" + next_slice + " write_ok=" + write_ok.to_string(),
    path: report_path,
    next_slice: next_slice,
    write_ok: write_ok,
    unplanned_count: unp.len(),
    files_touched: files,
});
