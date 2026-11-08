# Quickstart: 034-oauth-return-build

## Verify sanitize

```bash
npx vitest run src/lib/auth/returnUrl.test.ts
```

## Manual OAuth (dev HTTPS)

1. `npm run dev:https` → open https://127.0.0.1:3000
2. Visit `/api/auth/login` (no query) → complete Bungie → land on `/build`
3. Visit `/api/auth/login?returnUrl=/analyze` → land on `/analyze`
4. Visit `/api/auth/login?returnUrl=//evil.com` → land on `/build` after OAuth

## Gates

```bash
npm run typecheck
npm run lint
npm run test
```

## Grep acceptance

```bash
rg -n 'return "/analyze"|\?\? "/analyze"' src/app/api/auth
# expect no matches
```
