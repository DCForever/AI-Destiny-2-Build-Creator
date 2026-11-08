# Quickstart: Production SQLite Singleton

## Prerequisites

- Worktree on branch `032-prod-sqlite-singleton`
- `npm install` already satisfied

## Validate

```powershell
npm run typecheck
npm run lint
npm run test
```

Focused:

```powershell
npx vitest run src/lib/db/client.test.ts
# or project-equivalent single-file test invocation
rg -n "return openDatabase" src/lib/db/client.ts
```

Expected:
- typecheck/lint/test exit 0
- client test proves non-dev reuse of native handle
- `rg` shows no unconditional production-only `return openDatabase()` without cache
- `createTestDb` isolation assertion green
