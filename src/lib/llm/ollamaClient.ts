import type {
  ChatMessage,
  ChatOptions,
  ChatResponse,
  LlmClient,
  LlmFetchFn,
} from "./llmClient";
import {
  formatLlmFetchError,
  isRecord,
  parseToolCalls,
  readErrorBody,
} from "./llmClient";
import { llmFetch } from "./llmFetch";

function parseChatMessage(raw: unknown): ChatMessage {
  if (!isRecord(raw) || typeof raw.role !== "string") {
    throw new Error("Ollama chat response missing message.role");
  }
  const role = raw.role;
  if (role !== "system" && role !== "user" && role !== "assistant" && role !== "tool") {
    throw new Error(`Ollama chat response has unexpected role: ${role}`);
  }
  const content = typeof raw.content === "string" ? raw.content : "";
  const message: ChatMessage = { role, content };
  const toolCalls = parseToolCalls(raw.tool_calls);
  if (toolCalls) message.tool_calls = toolCalls;
  if (typeof raw.tool_name === "string") message.tool_name = raw.tool_name;
  return message;
}

function parseChatResponse(body: unknown): ChatResponse {
  if (!isRecord(body) || !isRecord(body.message)) {
    throw new Error("Ollama chat response has unexpected shape");
  }
  const done = body.done === true;
  return { message: parseChatMessage(body.message), done };
}

function parseTagsResponse(body: unknown): string[] {
  if (!isRecord(body) || !Array.isArray(body.models)) {
    throw new Error("Ollama tags response has unexpected shape");
  }
  const names: string[] = [];
  for (const model of body.models) {
    if (isRecord(model) && typeof model.name === "string") {
      names.push(model.name);
    }
  }
  return names;
}

function toOllamaMessages(messages: ChatMessage[]): ChatMessage[] {
  return messages.map((message) => {
    if (message.role !== "tool") return message;
    return {
      role: "tool" as const,
      content: message.content,
      tool_name: message.tool_name,
    };
  });
}

export class HttpOllamaClient implements LlmClient {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly fetchFn: LlmFetchFn;

  constructor(options: {
    baseUrl: string;
    model: string;
    fetchFn?: LlmFetchFn;
  }) {
    this.baseUrl = options.baseUrl.replace(/\/$/, "");
    this.model = options.model;
    this.fetchFn = options.fetchFn ?? llmFetch;
  }

  async chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse> {
    const body: Record<string, unknown> = {
      model: this.model,
      messages: toOllamaMessages(messages),
      stream: false,
      options: { temperature: options?.temperature ?? 0.2 },
    };
    if (options?.tools) body.tools = options.tools;
    if (options?.format) body.format = options.format;

    const response = await this.request("/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: options?.signal,
    });
    const parsed: unknown = await response.json();
    return parseChatResponse(parsed);
  }

  async listModels(): Promise<string[]> {
    const response = await this.request("/api/tags", { method: "GET" });
    const parsed: unknown = await response.json();
    return parseTagsResponse(parsed);
  }

  async healthCheck(): Promise<{ healthy: boolean; detail: string }> {
    try {
      const models = await this.listModels();
      return {
        healthy: true,
        detail: models.length > 0 ? `${models.length} model(s) available` : "no models listed",
      };
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      return { healthy: false, detail };
    }
  }

  private async request(path: string, init: RequestInit): Promise<Response> {
    const url = `${this.baseUrl}${path}`;
    try {
      const response = await this.fetchFn(url, init);
      if (!response.ok) {
        const bodyText = await readErrorBody(response);
        throw new Error(`Ollama ${path} failed (${response.status}): ${bodyText}`);
      }
      return response;
    } catch (error) {
      throw formatLlmFetchError(url, error);
    }
  }
}

/** @deprecated Use createLlmClient() from createLlmClient.ts */
export type OllamaClient = LlmClient;
