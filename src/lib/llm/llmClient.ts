import type { ToolDefinition } from "./toolTypes";

export interface ToolCall {
  id?: string;
  function: { name: string; arguments: Record<string, unknown> };
}

export interface ChatMessage {
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  tool_calls?: ToolCall[];
  /** Ollama tool result field. */
  tool_name?: string;
  /** OpenAI tool result field. */
  tool_call_id?: string;
}

export interface ChatOptions {
  tools?: ToolDefinition[];
  format?: Record<string, unknown>;
  temperature?: number;
  signal?: AbortSignal;
}

export interface ChatResponse {
  message: ChatMessage;
  done: boolean;
}

export interface LlmClient {
  chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse>;
  listModels(): Promise<string[]>;
  healthCheck(): Promise<{ healthy: boolean; detail: string }>;
}

export type LlmFetchFn = (input: string, init?: RequestInit) => Promise<Response>;

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseToolArguments(raw: unknown): Record<string, unknown> {
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

export function parseToolCalls(raw: unknown): ToolCall[] | undefined {
  if (!Array.isArray(raw)) return undefined;
  const calls: ToolCall[] = [];
  for (const entry of raw) {
    if (!isRecord(entry) || !isRecord(entry.function)) continue;
    const fn = entry.function;
    if (typeof fn.name !== "string") continue;
    const call: ToolCall = {
      function: { name: fn.name, arguments: parseToolArguments(fn.arguments) },
    };
    if (typeof entry.id === "string") call.id = entry.id;
    calls.push(call);
  }
  return calls.length > 0 ? calls : undefined;
}

export const BODY_TRUNCATE = 200;

export function truncateText(text: string, max = BODY_TRUNCATE): string {
  if (text.length <= max) return text;
  return `${text.slice(0, max)}…`;
}

export async function readErrorBody(response: Response): Promise<string> {
  try {
    return truncateText(await response.text());
  } catch {
    return "(unable to read response body)";
  }
}

export function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) {
    throw signal.reason ?? new DOMException("Aborted", "AbortError");
  }
}

export function isAbortError(error: unknown): boolean {
  if (error instanceof DOMException && error.name === "AbortError") return true;
  return error instanceof Error && error.name === "AbortError";
}

function fetchErrorCause(error: unknown): string | undefined {
  if (!(error instanceof Error) || !("cause" in error)) return undefined;
  const cause = (error as Error & { cause?: unknown }).cause;
  if (cause instanceof Error) return cause.message;
  if (typeof cause === "object" && cause !== null && "code" in cause) {
    return String((cause as { code: unknown }).code);
  }
  return cause !== undefined ? String(cause) : undefined;
}

/** Turn opaque Node fetch errors into actionable LLM connection messages. */
export function formatLlmFetchError(url: string, error: unknown): Error {
  if (isAbortError(error)) return error instanceof Error ? error : new DOMException("Aborted", "AbortError");
  const cause = fetchErrorCause(error);
  const base = error instanceof Error ? error.message : String(error);
  if (base === "fetch failed") {
    if (cause?.includes("Headers Timeout")) {
      return new Error(
        `LLM at ${url} is still generating but the HTTP client timed out waiting for a response. Retry after updating, or use a faster/smaller model.`,
      );
    }
    const hint = cause === "ECONNREFUSED"
      ? "Is LM Studio or Ollama running?"
      : "Check that the LLM server is running and LLM_URL in .env.local is correct.";
    return new Error(`Cannot reach LLM at ${url} (${cause ?? "network error"}). ${hint}`);
  }
  return error instanceof Error ? error : new Error(base);
}
