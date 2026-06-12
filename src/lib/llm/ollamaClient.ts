import { getOllamaConfig } from "@/lib/config/env";

import type { ToolDefinition } from "./toolTypes";

export interface ChatMessage {
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  tool_calls?: { function: { name: string; arguments: Record<string, unknown> } }[];
  tool_name?: string;
}

export interface ChatOptions {
  tools?: ToolDefinition[];
  format?: Record<string, unknown>;
  temperature?: number;
}

export interface ChatResponse {
  message: ChatMessage;
  done: boolean;
}

export interface OllamaClient {
  chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse>;
  listModels(): Promise<string[]>;
  healthCheck(): Promise<{ healthy: boolean; detail: string }>;
}

const DEFAULT_TIMEOUT_MS = 120_000;
const BODY_TRUNCATE = 200;

function truncateText(text: string, max = BODY_TRUNCATE): string {
  if (text.length <= max) return text;
  return `${text.slice(0, max)}…`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseToolArguments(raw: unknown): Record<string, unknown> {
  if (isRecord(raw)) return raw;
  if (typeof raw === "string") {
    try {
      const parsed: unknown = JSON.parse(raw);
      return isRecord(parsed) ? parsed : {};
    } catch {
      return {};
    }
  }
  return {};
}

function parseToolCalls(raw: unknown): ChatMessage["tool_calls"] {
  if (!Array.isArray(raw)) return undefined;
  const calls: NonNullable<ChatMessage["tool_calls"]> = [];
  for (const entry of raw) {
    if (!isRecord(entry) || !isRecord(entry.function)) continue;
    const fn = entry.function;
    if (typeof fn.name !== "string") continue;
    calls.push({
      function: { name: fn.name, arguments: parseToolArguments(fn.arguments) },
    });
  }
  return calls.length > 0 ? calls : undefined;
}

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

async function readErrorBody(response: Response): Promise<string> {
  try {
    return truncateText(await response.text());
  } catch {
    return "(unable to read response body)";
  }
}

export class HttpOllamaClient implements OllamaClient {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly fetchFn: typeof fetch;
  private readonly timeoutMs: number;

  constructor(options: {
    baseUrl: string;
    model: string;
    fetchFn?: typeof fetch;
    timeoutMs?: number;
  }) {
    this.baseUrl = options.baseUrl.replace(/\/$/, "");
    this.model = options.model;
    this.fetchFn = options.fetchFn ?? fetch;
    this.timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  }

  async chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse> {
    const body: Record<string, unknown> = {
      model: this.model,
      messages,
      stream: false,
      options: { temperature: options?.temperature ?? 0.2 },
    };
    if (options?.tools) body.tools = options.tools;
    if (options?.format) body.format = options.format;

    const response = await this.request("/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
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
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await this.fetchFn(`${this.baseUrl}${path}`, {
        ...init,
        signal: controller.signal,
      });
      if (!response.ok) {
        const bodyText = await readErrorBody(response);
        throw new Error(`Ollama ${path} failed (${response.status}): ${bodyText}`);
      }
      return response;
    } catch (error) {
      if (error instanceof Error && error.name === "AbortError") {
        throw new Error(`Ollama ${path} timed out after ${this.timeoutMs}ms`);
      }
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }
}

export function createOllamaClient(): OllamaClient {
  const { url, model } = getOllamaConfig();
  return new HttpOllamaClient({ baseUrl: url, model });
}
