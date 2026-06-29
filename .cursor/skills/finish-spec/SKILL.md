---
name: finish-spec
description: Commits remaining work on a Spec Kit feature branch, merges it into the configured base branch, and checks out that branch. Use when the user says finish spec, complete spec, merge feature branch, or wants to land a specs/00N-* branch onto feature/overhall (or git-config base_branch).
compatibility: Requires spec-kit project structure with .specify/ directory and a git repository
---

# Finish Spec

Land a completed Spec Kit feature: commit outstanding work on the **feature branch**, merge into the **base branch**, and end on the base branch.

## Prerequisites

- Git repository (`git rev-parse --is-inside-work-tree`)
- Current branch is a Spec Kit feature branch: `NNN-short-name` or `YYYYMMDD-HHMMSS-short-name` (see `speckit-git-validate`)
- Implementation is ready to land (run `npm run gate` when code changed)

## Resolve branches

1. **Feature branch** — current branch (`git rev-parse --abbrev-ref HEAD`). Save as `FEATURE_BRANCH`.
2. **Base branch** — read `.specify/extensions/git/git-config.yml`:
   - Use `base_branch` when set (this repo: `feature/overhall`)
   - If unset, ask the user which branch to merge into
3. Confirm `FEATURE_BRANCH` ≠ base branch before proceeding.

## Workflow

Copy and track:

```
Finish spec:
- [ ] Step 1: Preflight
- [ ] Step 2: Commit all feature work
- [ ] Step 3: Merge into base branch
- [ ] Step 4: Verify and report
```

### Step 1: Preflight

Run in parallel:

```bash
git status
git diff
git log -3 --oneline
```

Check:

- On a valid feature branch (not `main`, not base branch unless user explicitly requested)
- No unintended secrets in changes (`.env`, credentials)
- If the user changed application code, `npm run gate` MUST pass before merge

**Do not merge** if gate fails — fix or report blockers first.

**Default exclusions** (never stage/commit):

- `.cursor/debug-*.log`, `.cache/`, `.next/`, `node_modules/`
- Obvious local-only artifacts unless the user explicitly asks to include them

### Step 2: Commit all feature work

If there are uncommitted changes:

1. Stage all relevant files (`git add` paths; avoid exclusion list above).
2. Draft a commit message from the diff (1–2 sentences, focus on **why**).
3. Commit:

```bash
git commit -m "$(cat <<'EOF'
<message>

EOF
)"
```

On PowerShell, use a here-string:

```powershell
git commit -m @"
<message>

"@
```

If nothing to commit, note "working tree clean" and continue.

**Never** amend, force-push, or skip hooks unless the user explicitly requests it.

### Step 3: Merge into base branch

Sequential commands:

```bash
git fetch origin
git checkout <base_branch>
git pull origin <base_branch>
git merge <FEATURE_BRANCH> --no-edit
```

Rules:

- Prefer a **merge commit** (`--no-edit`) unless the user asks for squash/rebase.
- On merge conflict: stop, list conflicted files, do not force. User resolves or asks you to fix.
- **Do not push** to remote unless the user explicitly asks.

After a successful merge, the current branch MUST be `<base_branch>`.

### Step 4: Verify and report

```bash
git status
git log -3 --oneline
```

Report to the user:

- `FEATURE_BRANCH` merged into `<base_branch>`
- Current branch (should be base)
- Commits created in step 2 (if any)
- Whether local base is ahead of `origin/<base_branch>` (push optional)

Optional cleanup (only if user asks): delete local `FEATURE_BRANCH` after merge.

## Failure handling

| Situation | Action |
|-----------|--------|
| Not on a feature branch | Stop; run `speckit-git-validate` or ask user for branch name |
| Uncommitted changes block checkout | Commit or stash per user preference; default is commit via Step 2 |
| `base_branch` missing locally | `git fetch origin` then `git checkout -b <base> origin/<base>` or ask user |
| Merge conflicts | Stop on base branch mid-merge; report files; do not push |
| Gate fails | Stop before merge; list failing step |

## Related skills

- `speckit-git-validate` — confirm feature branch naming
- `speckit-git-commit` — hook auto-commit during Spec Kit commands (not a substitute for this workflow)
- User commit/PR rules — no push unless requested; no destructive git without explicit approval
