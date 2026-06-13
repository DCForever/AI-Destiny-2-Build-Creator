import { describe, expect, it } from "vitest";

import { formatLlmFetchError } from "./llmClient";

describe("formatLlmFetchError", () => {
  it("wraps ECONNREFUSED fetch failures with the LLM URL", () => {
    const error = new TypeError("fetch failed", { cause: { code: "ECONNREFUSED" } });
    const formatted = formatLlmFetchError("http://127.0.0.1:1234/v1/chat/completions", error);
    expect(formatted.message).toContain("http://127.0.0.1:1234/v1/chat/completions");
    expect(formatted.message).toContain("ECONNREFUSED");
    expect(formatted.message).toContain("LM Studio or Ollama");
  });

  it("rethrows abort errors unchanged", () => {
    const error = new DOMException("The operation was aborted.", "AbortError");
    expect(formatLlmFetchError("http://127.0.0.1:1234/v1/chat/completions", error)).toBe(error);
  });

  it("explains headers timeout failures", () => {
    const error = new TypeError("fetch failed", {
      cause: new Error("Headers Timeout Error"),
    });
    const formatted = formatLlmFetchError("http://127.0.0.1:1234/v1/chat/completions", error);
    expect(formatted.message).toContain("still generating");
  });
});
