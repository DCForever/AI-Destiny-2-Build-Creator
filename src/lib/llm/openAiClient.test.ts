import { describe, expect, it, vi } from "vitest";

import { OpenAiCompatibleClient } from "./openAiClient";
import type { ToolDefinition } from "./toolTypes";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function firstFetchCall(fetchFn: ReturnType<typeof vi.fn<typeof fetch>>) {
  const call = fetchFn.mock.calls[0];
  if (!call) throw new Error("fetch was not called");
  return { url: String(call[0]), init: call[1] as RequestInit };
}

describe("OpenAiCompatibleClient", () => {
  it("posts to /v1/chat/completions with temperature and stream false", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({
        choices: [{ message: { role: "assistant", content: "ok" } }],
      }),
    );
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "local-model",
      fetchFn,
    });

    await client.chat([{ role: "user", content: "hi" }]);

    const { url, init } = firstFetchCall(fetchFn);
    expect(url).toBe("http://127.0.0.1:1234/v1/chat/completions");
    const body = JSON.parse(String(init.body)) as Record<string, unknown>;
    expect(body.model).toBe("local-model");
    expect(body.stream).toBe(false);
    expect(body.temperature).toBe(0.2);
    expect(body.tools).toBeUndefined();
    expect(body.response_format).toBeUndefined();
  });

  it("maps tools and response_format when provided", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({
        choices: [{ message: { role: "assistant", content: "{}" } }],
      }),
    );
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });
    const tools = [
      { type: "function", function: { name: "search_items", description: "x", parameters: {} } },
    ] as ToolDefinition[];
    const format = { type: "object", properties: { name: { type: "string" } } };

    await client.chat([{ role: "user", content: "hi" }], { tools, format, temperature: 0.5 });

    const { init } = firstFetchCall(fetchFn);
    const body = JSON.parse(String(init.body)) as Record<string, unknown>;
    expect(body.tools).toEqual(tools);
    expect(body.tool_choice).toBe("auto");
    expect(body.temperature).toBe(0.5);
    expect(body.response_format).toEqual({
      type: "json_schema",
      json_schema: { name: "response", strict: true, schema: format },
    });
  });

  it("sends Authorization header when apiKey is set", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({ choices: [{ message: { role: "assistant", content: "ok" } }] }),
    );
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      apiKey: "secret-key",
      fetchFn,
    });

    await client.chat([{ role: "user", content: "hi" }]);

    const { init } = firstFetchCall(fetchFn);
    const headers = init.headers as Record<string, string>;
    expect(headers.Authorization).toBe("Bearer secret-key");
  });

  it("maps tool messages with tool_call_id on the wire", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({ choices: [{ message: { role: "assistant", content: "ok" } }] }),
    );
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    await client.chat([
      { role: "tool", tool_call_id: "call_1", content: '{"ok":true}' },
    ]);

    const { init } = firstFetchCall(fetchFn);
    const body = JSON.parse(String(init.body)) as {
      messages: Array<Record<string, unknown>>;
    };
    expect(body.messages[0]).toEqual({
      role: "tool",
      tool_call_id: "call_1",
      content: '{"ok":true}',
    });
  });

  it("parses tool_calls with stringified arguments", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({
        choices: [
          {
            message: {
              role: "assistant",
              content: "",
              tool_calls: [
                {
                  id: "call_1",
                  type: "function",
                  function: {
                    name: "search_items",
                    arguments: JSON.stringify({ query: "fatebringer" }),
                  },
                },
              ],
            },
          },
        ],
      }),
    );
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    const response = await client.chat([{ role: "user", content: "find weapon" }]);
    expect(response.message.tool_calls?.[0]?.id).toBe("call_1");
    expect(response.message.tool_calls?.[0]?.function.arguments).toEqual({
      query: "fatebringer",
    });
  });

  it("throws on non-OK responses without leaking api key", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () => new Response("bad request", { status: 400 }));
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      apiKey: "secret-key",
      fetchFn,
    });

    await expect(client.chat([{ role: "user", content: "hi" }])).rejects.toSatisfy(
      (error: unknown) =>
        error instanceof Error &&
        error.message.includes("OpenAI /chat/completions failed (400): bad request") &&
        !error.message.includes("secret-key"),
    );
  });

  it("maps 401 auth errors from token endpoint shape in chat errors", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () => new Response("unauthorized", { status: 401 }));
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    await expect(client.chat([{ role: "user", content: "hi" }])).rejects.toThrow(/401/);
  });

  it("listModels parses /v1/models", async () => {
    const fetchFn = vi.fn<typeof fetch>(async (input) => {
      expect(String(input)).toBe("http://127.0.0.1:1234/v1/models");
      return jsonResponse({ data: [{ id: "local-model" }, { id: "other" }] });
    });
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    await expect(client.listModels()).resolves.toEqual(["local-model", "other"]);
  });

  it("retries without response_format when schema request fails", async () => {
    let callCount = 0;
    const fetchFn = vi.fn<typeof fetch>(async () => {
      callCount += 1;
      if (callCount === 1) {
        return new Response("unsupported response_format", { status: 400 });
      }
      return jsonResponse({
        choices: [{ message: { role: "assistant", content: '{"name":"Test"}' } }],
      });
    });
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    const response = await client.chat(
      [{ role: "user", content: "compose" }],
      { format: { type: "object" } },
    );
    expect(fetchFn).toHaveBeenCalledTimes(2);
    expect(response.message.content).toContain("Test");
    const secondBody = JSON.parse(String(fetchFn.mock.calls[1]?.[1]?.body)) as Record<string, unknown>;
    expect(secondBody.response_format).toBeUndefined();
  });

  it("aborts chat when signal is aborted", async () => {
    const controller = new AbortController();
    controller.abort();
    const fetchFn = vi.fn<typeof fetch>(async (_url, init) => {
      if (init?.signal?.aborted) {
        throw new DOMException("The operation was aborted.", "AbortError");
      }
      return jsonResponse({ choices: [{ message: { role: "assistant", content: "ok" } }] });
    });
    const client = new OpenAiCompatibleClient({
      baseUrl: "http://127.0.0.1:1234/v1",
      model: "test",
      fetchFn,
    });

    await expect(
      client.chat([{ role: "user", content: "hi" }], { signal: controller.signal }),
    ).rejects.toMatchObject({ name: "AbortError" });
    expect(fetchFn).toHaveBeenCalledWith(
      "http://127.0.0.1:1234/v1/chat/completions",
      expect.objectContaining({ signal: controller.signal }),
    );
  });
});
