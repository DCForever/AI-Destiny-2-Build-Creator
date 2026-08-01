import { describe, expect, it } from "vitest";

import { DEFAULT_POST_LOGIN_PATH, sanitizeReturnUrl } from "./returnUrl";

const origin = "https://127.0.0.1:3000";
const requestUrl = new URL("/", origin);

describe("DEFAULT_POST_LOGIN_PATH", () => {
  it("is /build", () => {
    expect(DEFAULT_POST_LOGIN_PATH).toBe("/build");
  });
});

describe("sanitizeReturnUrl", () => {
  it("defaults null to /build", () => {
    expect(sanitizeReturnUrl(null, requestUrl)).toBe("/build");
  });

  it("defaults empty string to /build", () => {
    expect(sanitizeReturnUrl("", requestUrl)).toBe("/build");
  });

  it("allows same-origin relative /settings", () => {
    expect(sanitizeReturnUrl("/settings", requestUrl)).toBe("/settings");
  });

  it("allows explicit /analyze", () => {
    expect(sanitizeReturnUrl("/analyze", requestUrl)).toBe("/analyze");
  });

  it("preserves query string on safe paths", () => {
    expect(sanitizeReturnUrl("/build?tab=library", requestUrl)).toBe("/build?tab=library");
  });

  it("rejects protocol-relative //evil.com", () => {
    expect(sanitizeReturnUrl("//evil.com", requestUrl)).toBe("/build");
  });

  it("rejects absolute external https://evil.com", () => {
    expect(sanitizeReturnUrl("https://evil.com", requestUrl)).toBe("/build");
  });

  it("rejects paths that do not start with /", () => {
    expect(sanitizeReturnUrl("build", requestUrl)).toBe("/build");
  });
});
