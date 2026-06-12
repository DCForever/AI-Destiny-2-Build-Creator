import { describe, expect, it, vi } from "vitest";

import { HttpOllamaClient } from "./ollamaClient";
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

describe("HttpOllamaClient", () => {
  it("posts to /api/chat with model, stream false, and default temperature", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({ message: { role: "assistant", content: "ok" }, done: true }),
    );
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434",
      model: "gemma4",
      fetchFn,
    });

    await client.chat([{ role: "user", content: "hi" }]);

    expect(fetchFn).toHaveBeenCalledOnce();
    const { url, init } = firstFetchCall(fetchFn);
    expect(url).toBe("http://localhost:11434/api/chat");
    const body = JSON.parse(String(init.body)) as Record<string, unknown>;
    expect(body.model).toBe("gemma4");
    expect(body.stream).toBe(false);
    expect(body.options).toEqual({ temperature: 0.2 });
    expect(body.tools).toBeUndefined();
    expect(body.format).toBeUndefined();
  });

  it("includes tools and format only when provided", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({ message: { role: "assistant", content: "ok" }, done: true }),
    );
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434/",
      model: "test",
      fetchFn,
    });
    const tools = [{ type: "function", function: { name: "search_items", description: "x", parameters: {} } }] as ToolDefinition[];
    const format = { type: "object" };

    await client.chat([{ role: "user", content: "hi" }], { tools, format, temperature: 0.5 });

    const { init } = firstFetchCall(fetchFn);
    const body = JSON.parse(String(init.body)) as Record<string, unknown>;
    expect(body.tools).toEqual(tools);
    expect(body.format).toEqual(format);
    expect(body.options).toEqual({ temperature: 0.5 });
  });

  it("throws on non-OK chat responses with status and body", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () => new Response("model missing", { status: 404 }));
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434",
      model: "bad",
      fetchFn,
    });

    await expect(client.chat([{ role: "user", content: "hi" }])).rejects.toThrow(
      "Ollama /api/chat failed (404): model missing",
    );
  });

  it("parses tool_calls and stringified arguments from chat responses", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () =>
      jsonResponse({
        message: {
          role: "assistant",
          content: "",
          tool_calls: [
            {
              function: {
                name: "search_items",
                arguments: JSON.stringify({ query: "fatebringer" }),
              },
            },
          ],
        },
        done: true,
      }),
    );
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434",
      model: "test",
      fetchFn,
    });

    const response = await client.chat([{ role: "user", content: "find weapon" }]);
    expect(response.message.tool_calls?.[0]?.function.arguments).toEqual({ query: "fatebringer" });
  });

  it("listModels parses /api/tags", async () => {
    const fetchFn = vi.fn<typeof fetch>(async (input) => {
      expect(String(input)).toBe("http://localhost:11434/api/tags");
      return jsonResponse({ models: [{ name: "gemma4" }, { name: "llama3" }] });
    });
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434",
      model: "test",
      fetchFn,
    });

    await expect(client.listModels()).resolves.toEqual(["gemma4", "llama3"]);
  });

  it("healthCheck reports unhealthy when listModels rejects", async () => {
    const fetchFn = vi.fn<typeof fetch>(async () => new Response("down", { status: 503 }));
    const client = new HttpOllamaClient({
      baseUrl: "http://localhost:11434",
      model: "test",
      fetchFn,
    });

    const result = await client.healthCheck();
    expect(result.healthy).toBe(false);
    expect(result.detail).toContain("503");
  });
});
