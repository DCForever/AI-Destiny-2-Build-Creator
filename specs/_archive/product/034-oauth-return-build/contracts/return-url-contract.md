# Contract: OAuth return URL sanitization

## `DEFAULT_POST_LOGIN_PATH`

- Type: `string` constant
- Value: `"/build"`
- Used by: `sanitizeReturnUrl` fallback; callback when `session.oauthReturnUrl` is missing

## `sanitizeReturnUrl(raw, requestUrl)`

| Input `raw` | Output |
|-------------|--------|
| `null` / `""` / missing | `DEFAULT_POST_LOGIN_PATH` |
| does not start with `/` | `DEFAULT_POST_LOGIN_PATH` |
| starts with `//` | `DEFAULT_POST_LOGIN_PATH` |
| absolute URL different origin | `DEFAULT_POST_LOGIN_PATH` |
| same-origin relative path | `pathname + search` |
| `/analyze` | `/analyze` (explicit allow) |
| `/settings` | `/settings` |

## Session

- Login writes `oauthReturnUrl` = sanitize result
- Callback reads `oauthReturnUrl ?? DEFAULT_POST_LOGIN_PATH`, then clears oauth fields
- Redirect: `NextResponse.redirect(new URL(returnUrl, request.url), 307)`
