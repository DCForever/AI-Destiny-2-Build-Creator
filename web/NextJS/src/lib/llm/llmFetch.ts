import { Agent, fetch as undiciFetch } from "undici";

import type { LlmFetchFn } from "./llmClient";

/**
 * Node's global fetch uses undici with a 300s headersTimeout. Local LLMs
 * (especially reasoning models) often exceed that before returning a
 * non-streaming /chat/completions response.
 */
const LLM_HTTP_AGENT = new Agent({
  headersTimeout: 0,
  bodyTimeout: 0,
});

export const llmFetch: LlmFetchFn = (input, init) =>
  undiciFetch(input, {
    ...init,
    dispatcher: LLM_HTTP_AGENT,
  } as Parameters<typeof undiciFetch>[1]) as unknown as Promise<Response>;
