<!--
Sync Impact Report
- Version change: (template placeholders) → 1.0.0
- Modified principles: All 5 principles populated from placeholders (no renames, concrete definitions added)
- Added sections: Core Principles (detailed), Quality Gates, Development Workflow, Governance (full text)
- Removed sections: None
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ updated (Constitution Check expanded with specific gates)
  - .specify/templates/tasks-template.md ✅ updated (Test-First + Green Checkpoints language strengthened in notes and examples)
  - .specify/templates/spec-template.md ✅ reviewed + lightly updated (ties user stories to increments)
  - .specify/templates/constitution-template.md ✅ updated (example comments now reflect the principles)
  - .specify/templates/commands/*.md : ⚠ n/a — directory does not exist in this checkout; command sources live in skill metadata and extension definitions
- Follow-up TODOs: None (all placeholders replaced)
-->

# Destiny 2 Build Creator Constitution

## Core Principles

### I. Small Testable Increments

The scope of every feature, change, or fix MUST be broken down into small, independently testable increments. Each increment is a vertical slice that can be fully specified, implemented, tested, demonstrated, and committed without depending on later increments.

### II. Test-First Development (NON-NEGOTIABLE)

Tests are always created first. Before writing implementation for any new behavior, a corresponding test (or test update) is authored and confirmed to fail. This applies to unit tests, integration tests, contract tests, and schema validations.

### III. Green Commit Checkpoints (NON-NEGOTIABLE)

Commits are performed only at regular checkpoints. At every commit point the full test suite must pass and `npm run gate` (typecheck + lint + test + build) must succeed. No broken, partial, or failing states are committed to the repository.

### IV. Co-Located Test Verification

Tests are co-located with the modules they verify (`*.test.ts` next to `*.ts`). Tests serve as executable specification and regression protection. Core logic must be testable in isolation.

### V. Validation-First External Data

All data originating outside the deterministic core (Bungie manifest responses, LLM generations, third-party APIs) MUST be validated through strict schemas and rules before it influences build resolution or user-visible output. Failures are explicit and tested.

## Quality Gates

- `npm run gate` is the mandatory quality bar and includes: typecheck, lint, test, build.
- Every increment must pass the gate at its checkpoint.
- PRs and mainline integration require a clean gate.

## Development Workflow

- Features follow the speckit flow: specify (user stories as testable increments) → plan (with Constitution Check) → tasks (tests first within stories) → implement.
- Work proceeds increment-by-increment; each user story (or sub-increment) is independently valuable and testable.
- After each logical checkpoint the gate is run and changes are committed only when green.

## Governance

This constitution defines the non-negotiable rules for how software is built on this project. It takes precedence over individual preferences, convenience, or "temporary" shortcuts.

- All plans MUST contain a Constitution Check section evaluating compliance with these principles.
- Violations require documented justification in the plan's Complexity Tracking table.
- Amendments follow semantic versioning:
  - MAJOR for incompatible principle changes or removals
  - MINOR for new principles or significant expansions
  - PATCH for clarifications and non-semantic edits
- Compliance is reviewed on every plan, tasks, and during implementation reviews.
- Use of the gate script and explicit test-first ordering are auditable via task lists and commit history.

**Version**: 1.0.0 | **Ratified**: 2026-06-17 | **Last Amended**: 2026-06-17
