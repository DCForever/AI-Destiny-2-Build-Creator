/** Default post-login path when returnUrl is missing or unsafe. Product home is /build. */
export const DEFAULT_POST_LOGIN_PATH = "/build";

/**
 * Allow only same-origin relative paths (no protocol-relative or external URLs).
 * Unsafe or missing values fall back to {@link DEFAULT_POST_LOGIN_PATH}.
 */
export function sanitizeReturnUrl(raw: string | null, requestUrl: URL): string {
  if (!raw || !raw.startsWith("/") || raw.startsWith("//")) {
    return DEFAULT_POST_LOGIN_PATH;
  }
  try {
    const resolved = new URL(raw, requestUrl.origin);
    if (resolved.origin !== requestUrl.origin) {
      return DEFAULT_POST_LOGIN_PATH;
    }
    return resolved.pathname + resolved.search;
  } catch {
    return DEFAULT_POST_LOGIN_PATH;
  }
}
