let meta = #{
    name: "dart-speckit-loop",
    description: "Advance multiplatform DART slices via full Spec Kit lifecycle (specify→plan→tasks→implement→finish) in order",
    when_to_use: "Run the parallel DART-001+ port automatically; re-run to continue from next pending slice",
    phases: [
        #{ title: "Resolve", detail: "pick next pending DART slice from roadmap" },
        #{ title: "SpecKit", detail: "specify plan tasks implement finish-spec" },
        #{ title: "Record", detail: "update roadmap pointer and report" },
    ],
};

let resolve_schema = #{
    "type": "object",
    "required": ["slice_id", "short_name", "branch", "phase", "goal", "exit_criteria", "ready"],
    "properties": #{
        "slice_id": #{ "type": "string" },
        "short_name": #{ "type": "string" },
        "branch": #{ "type": "string" },
        "phase": #{ "type": "string" },
        "goal": #{ "type": "string" },
        "exit_criteria": #{ "type": "string" },
        "ready": #{ "type": "boolean" },
        "blocked_reason": #{ "type": "string" },
        "roadmap_path": #{ "type": "string" },
    },
};

let slice_result_schema = #{
    "type": "object",
    "required": ["slice_id", "success", "status", "summary"],
    "properties": #{
        "slice_id": #{ "type": "string" },
        "success": #{ "type": "boolean" },
        "status": #{ "type": "string" },
        "summary": #{ "type": "string" },
        "branch": #{ "type": "string" },
        "spec_dir": #{ "type": "string" },
        "merged_to_base": #{ "type": "boolean" },
        "blocker": #{ "type": "string" },
        "next_action": #{ "type": "string" },
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

// --- args ---
let worktree = "F:/Destiny2BuildCreator-multiplatform-dart";
let max_slices = 49;
let stop_on_fail = true;
let auto_finish = true;
let skip_clarify_unless_needed = true;

if args != () {
    if args.worktree != () { worktree = as_str(args.worktree); }
    if args.max_slices != () {
        // Rhai may pass number
        if type_of(args.max_slices) == "i64" || type_of(args.max_slices) == "int" {
            max_slices = args.max_slices;
        } else if type_of(args.max_slices) == "string" {
            // leave default if unparsable; agents still respect prompt
            max_slices = 49;
        }
    }
    if args.stop_on_fail != () && args.stop_on_fail == false { stop_on_fail = false; }
    if args.auto_finish != () && args.auto_finish == false { auto_finish = false; }
}

if max_slices < 1 { max_slices = 1; }
if max_slices > 49 { max_slices = 49; }

log("dart-speckit-loop: worktree=" + worktree + " max_slices=" + max_slices.to_string());

let completed = [];
let failed = [];
let slice_index = 0;

while slice_index < max_slices {
    // =========================================================================
    phase("Resolve");
    // =========================================================================
    let resolve_prompt = "";
    resolve_prompt += "You are the DART port Spec Kit dispatcher. ";
    resolve_prompt += "Working directory MUST be: " + worktree + " ";
    resolve_prompt += "Read docs/multiplatform-dart-slice-roadmap.md with tools (read_file). ";
    resolve_prompt += "Find the first slice whose Status is active or pending and whose Depends are all done ";
    resolve_prompt += "(active counts as the current slice to finish). Prefer the Current pointer section. ";
    resolve_prompt += "Also read docs/multiplatform-dart-port-decisions.md and docs/multiplatform-dart-branching.md. ";
    resolve_prompt += "Do not invent a product 0NN number. IDs are DART-001..DART-049 only. ";
    resolve_prompt += "Set ready=true only if dependencies are satisfied and work can start. ";
    resolve_prompt += "If no slice remains, set ready=false, slice_id=NONE, blocked_reason=all_done. ";
    resolve_prompt += "Return JSON only per schema.";

    let res = agent(resolve_prompt, #{
        label: "resolve-next",
        capability_mode: "read-only",
        output_schema: resolve_schema,
    });

    if res == () || !res.success || res.output == () {
        failed.push(#{ slice_id: "unknown", summary: "resolve agent failed" });
        log("Resolve failed");
        if stop_on_fail { break; }
        slice_index += 1;
        continue;
    }

    let slice = res.output;
    let slice_id = as_str(slice.slice_id);
    let ready = slice.ready == true;

    if !ready || slice_id == "" || slice_id == "NONE" {
        log("No ready slice: " + as_str(slice.blocked_reason));
        if as_str(slice.blocked_reason) == "all_done" || slice_id == "NONE" {
            break;
        }
        failed.push(#{ slice_id: slice_id, summary: as_str(slice.blocked_reason) });
        if stop_on_fail { break; }
        slice_index += 1;
        continue;
    }

    log("Next slice: " + slice_id + " " + as_str(slice.branch));

    // =========================================================================
    phase("SpecKit");
    // =========================================================================
    let sk = "";
    sk += "You are a Spec Kit implementer for the multiplatform DART workstream. ";
    sk += "ALL git and file work happens under: " + worktree + " ";
    sk += "Use shell with cwd " + worktree + ". Never edit F:/Destiny2BuildCreator product worktree for this task. ";
    sk += "\n## Slice (must not expand scope)\n";
    sk += "ID: " + slice_id + "\n";
    sk += "Short name: " + as_str(slice.short_name) + "\n";
    sk += "Branch: " + as_str(slice.branch) + "\n";
    sk += "Phase: " + as_str(slice.phase) + "\n";
    sk += "Goal: " + as_str(slice.goal) + "\n";
    sk += "Exit criteria: " + as_str(slice.exit_criteria) + "\n";
    sk += "\n## Hard rules\n";
    sk += "- Parallel workstream IDs: DART-NNN only. Branch/specs: dart-NNN-short-name. Never product 044+.\n";
    sk += "- Integration base: feature/multiplatform-dart. finish-spec merges THERE only (not main, not product branches).\n";
    sk += "- Read and obey docs/multiplatform-dart-port-decisions.md and the slice roadmap row.\n";
    sk += "- Do not implement later DART slices in this run.\n";
    sk += "- Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET in clients.\n";
    sk += "- Soft guidance never auto-applies; hard DBR blocks stay hard.\n";
    if skip_clarify_unless_needed {
        sk += "- Skip interactive clarify unless the spec would retain NEEDS CLARIFICATION; then make reasonable defaults and document Assumptions.\n";
    }
    sk += "\n## Spec Kit lifecycle (execute fully with tools)\n";
    sk += "1) Ensure git: checkout feature/multiplatform-dart; pull if remote; create/checkout branch " + as_str(slice.branch) + " from feature/multiplatform-dart if needed.\n";
    sk += "2) SPECIFY: Create specs/" + as_str(slice.branch) + "/ with spec.md from .specify/templates/spec-template.md, ";
    sk += "checklists/requirements.md, update .specify/feature.json feature_directory. Scope ONLY this slice exit criteria.\n";
    sk += "3) PLAN: Write plan.md (and research.md if needed) from plan-template; tech stack Dart/Flutter/Jaspr only as required by this slice.\n";
    sk += "4) TASKS: Write tasks.md with small ordered tasks; mark none complete yet.\n";
    sk += "5) IMPLEMENT: Execute every task; mark [x] in tasks.md; run tests (dart test / melos) appropriate to the slice.\n";
    if auto_finish {
        sk += "6) FINISH: Commit remaining work; checkout feature/multiplatform-dart; merge branch --no-edit; ";
        sk += "update docs/multiplatform-dart-slice-roadmap.md: this row status done, Current pointer to next pending; commit on base.\n";
    } else {
        sk += "6) Do NOT merge; leave branch ready for human finish-spec. Still update roadmap status to active if needed.\n";
    }
    sk += "7) If blocked (missing Dart SDK, unclear product decision), stop, leave status blocked, set success=false with blocker.\n";
    sk += "Use read_file, search_replace/write, run_terminal_command extensively. Do not claim done without evidence (files, test output).\n";
    sk += "Return JSON per schema.";

    let impl = agent(sk, #{
        label: "speckit:" + slice_id,
        capability_mode: "all",
        output_schema: slice_result_schema,
    });

    // =========================================================================
    phase("Record");
    // =========================================================================
    if impl == () || !impl.success || impl.output == () {
        failed.push(#{ slice_id: slice_id, summary: "speckit agent failed or empty" });
        log("SpecKit agent failed for " + slice_id);
        if stop_on_fail { break; }
        slice_index += 1;
        continue;
    }

    let out = impl.output;
    let ok = out.success == true;
    let summary = as_str(out.summary);
    log(slice_id + " success=" + ok.to_string() + " " + summary);

    if ok {
        completed.push(#{
            slice_id: slice_id,
            status: as_str(out.status),
            summary: summary,
            branch: as_str(out.branch),
            merged_to_base: out.merged_to_base == true,
        });
    } else {
        failed.push(#{
            slice_id: slice_id,
            summary: summary,
            blocker: as_str(out.blocker),
            next_action: as_str(out.next_action),
        });
        if stop_on_fail { break; }
    }

    slice_index += 1;
}

let report = "";
report += "# DART Spec Kit loop report\n\n";
report += "- Worktree: `" + worktree + "`\n";
report += "- max_slices: " + max_slices.to_string() + "\n";
report += "- Completed this run: " + completed.len().to_string() + "\n";
report += "- Failed/blocked: " + failed.len().to_string() + "\n\n";

report += "## Completed\n\n";
if completed.len() == 0 {
    report += "_None_\n\n";
} else {
    for c in completed {
        report += "- **" + as_str(c.slice_id) + "**: " + as_str(c.summary) + "\n";
    }
    report += "\n";
}

report += "## Failed / blocked\n\n";
if failed.len() == 0 {
    report += "_None_\n\n";
} else {
    for f in failed {
        report += "- **" + as_str(f.slice_id) + "**: " + as_str(f.summary);
        if as_str(f.blocker) != "" { report += " — " + as_str(f.blocker); }
        report += "\n";
    }
    report += "\n";
}

report += "Re-run `/dart-speckit-loop` to continue from the next pending DART slice.\n";

let path = write_scratch_file("dart-speckit-loop-report.md", report);

complete(#{
    summary: "DART Spec Kit loop finished: " + completed.len().to_string() + " completed, " + failed.len().to_string() + " failed",
    path: path,
    completed_count: completed.len(),
    failed_count: failed.len(),
    completed: completed,
    failed: failed,
    worktree: worktree,
});
