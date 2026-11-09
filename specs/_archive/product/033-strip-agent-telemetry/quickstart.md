# Quickstart: Verify strip agent debug telemetry

## Prerequisites

- Worktree on branch `033-strip-agent-telemetry`
- Dependencies installed (`npm ci` or `npm install` if needed)

## Validation steps

### 1. Static absence check

```powershell
rg -n "7497/ingest|#region agent log" src
```

**Expected**: no matches (exit code 1 from rg is success for this check).

### 2. Quality gate

```powershell
npm run typecheck
npm run lint
npm run test
npm run build
```

**Expected**: all commands exit 0.

### 3. Smoke (optional)

Trigger generate in dev without anything listening on port 7497. Success and failure paths should not attempt local ingest; UI/API errors still display.

## Contract reference

See [contracts/no-agent-ingest.md](./contracts/no-agent-ingest.md).
