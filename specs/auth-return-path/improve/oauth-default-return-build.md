---
status: DONE
priority: P2
effort: S
risk: LOW
category: bug
depends: []
planned_at: 799a9d6
issue: ""
---

# Default OAuth return path to /build

## Objective

When login is started without a safe `returnUrl`, OAuth callback falls back to **`/analyze`**, a secondary surface. Product home is **`/build`** (README: `/` redirects to `/build`; primary journey intent → compose → equip). After this lands, missing or invalid return URLs default to `/build` while still blocking open redirects.

## Current context

- `src/app/api/auth/login/route.ts` — `sanitizeReturnUrl`
- `src/app/api/auth/callback/route.ts` — `session.oauthReturnUrl ?? "/analyze"`
- Product: PRODUCT.md / README primary nav Build at `/build`
- Security: allow only same-origin relative paths (existing checks against `//` and external origins must remain)
- Verification: `npm run typecheck`, `npm run lint`, `npm run test` (add unit tests if sanitize is exported or testable)

```ts
// login/route.ts:17-25
function sanitizeReturnUrl(raw: string | null, requestUrl: URL): string {
  if (!raw || !raw.startsWith("/") || raw.startsWith("//")) return "/analyze";
  try {
    const resolved = new URL(raw, requestUrl.origin);
    if (resolved.origin !== requestUrl.origin) return "/analyze";
    return resolved.pathname + resolved.search;
  } catch {
    return "/analyze";
  }
}
```

```ts
// callback/route.ts:28
const returnUrl = session.oauthReturnUrl ?? "/analyze";
```

## Detailed instructions

### Requirements

- R1: Default fallback path is `/build` everywhere `sanitizeReturnUrl` or callback used `/analyze` as default.
- R2: Explicit `returnUrl=/analyze` (or other same-origin relative path) still works when provided by the client.
- R3: Open-redirect protections remain: reject `//evil`, absolute external URLs, and non-path inputs by falling back to `/build`.
- R4: Debug layout login redirect may keep its own entry; only change defaults in auth login/callback unless a shared constant is cleaner.
- R5: Prefer a single shared constant e.g. `DEFAULT_POST_LOGIN_PATH = "/build"` used by login + callback.

### Acceptance criteria

- [ ] `rg -n 'return "/analyze"|\\?\\? "/analyze"' src/app/api/auth` shows no default fallback to analyze (explicit allowlist tests may still mention analyze as a valid returnUrl)
- [ ] Unit test or equivalent covers: null → `/build`; `/settings` → `/settings`; `//evil.com` → `/build`; `https://evil.com` → `/build`
- [ ] `npm run typecheck` and `npm run lint` pass
- [ ] `npm run test` passes

### Scope boundaries

**In scope**

- `src/app/api/auth/login/route.ts`
- `src/app/api/auth/callback/route.ts`
- Optional small shared module under `src/lib/auth/`
- Tests for sanitize helper

**Out of scope**

- Changing Bungie OAuth redirect_uri registration
- Removing Analyze feature
- Session cookie flag changes
- Adding `redirect_uri` to token exchange (separate finding)

### Risks and notes

- Bookmarks or docs that assumed post-login Analyze should be updated only if they claim default behavior.
- Reviewer: confirm `returnUrl` query param from Settings/Build sign-in controls still honored.
