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

const CHAT_PATH = "/chat/completions";
const MODELS_PATH = "/models";

function toResponseFormat(schema: Record<string, unknown>): Record<string, unknown> {
  return {
    type: "json_schema",
    json_schema: {
      name: "response",
      strict: true,
      schema,
    },
  };
}

function toOpenAiMessages(messages: ChatMessage[]): Record<string, unknown>[] {
  return messages.map((message) => {
    if (message.role === "tool") {
      if (!message.tool_call_id) {
        throw new Error("OpenAI tool message missing tool_call_id");
      }
      return {
        role: "tool",
        tool_call_id: message.tool_call_id,
        content: message.content,
      };
    }

    if (message.role === "assistant" && message.tool_calls?.length) {
      return {
        role: "assistant",
        content: message.content || null,
        tool_calls: message.tool_calls.map((call, index) => ({
          id: call.id ?? `call_${index}`,
          type: "function",
          function: {
            name: call.function.name,
            arguments: JSON.stringify(call.function.arguments),
          },
        })),
      };
    }

    return { role: message.role, content: message.content };
  });
}

function parseAssistantMessage(raw: unknown): ChatMessage {
  if (!isRecord(raw) || typeof raw.role !== "string") {
    throw new Error("OpenAI chat response missing message.role");
  }
  const content = typeof raw.content === "string" ? raw.content : "";
  const message: ChatMessage = { role: "assistant", content };
  const toolCalls = parseToolCalls(raw.tool_calls);
  if (toolCalls) message.tool_calls = toolCalls;
  return message;
}

function parseChatResponse(body: unknown): ChatResponse {
  if (!isRecord(body) || !Array.isArray(body.choices) || body.choices.length === 0) {
    throw new Error("OpenAI chat response has unexpected shape");
  }
  const choice = body.choices[0];
  if (!isRecord(choice) || !isRecord(choice.message)) {
    throw new Error("OpenAI chat response missing choices[0].message");
  }
  return { message: parseAssistantMessage(choice.message), done: true };
}

function parseModelsResponse(body: unknown): string[] {
  if (!isRecord(body) || !Array.isArray(body.data)) {
    throw new Error("OpenAI models response has unexpected shape");
  }
  const names: string[] = [];
  for (const entry of body.data) {
    if (isRecord(entry) && typeof entry.id === "string") {
      names.push(entry.id);
    }
  }
  return names;
}

export class OpenAiCompatibleClient implements LlmClient {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly apiKey: string | null;
  private readonly fetchFn: LlmFetchFn;

  constructor(options: {
    baseUrl: string;
    model: string;
    apiKey?: string | null;
    fetchFn?: LlmFetchFn;
  }) {
    this.baseUrl = options.baseUrl.replace(/\/$/, "");
    this.model = options.model;
    this.apiKey = options.apiKey ?? null;
    this.fetchFn = options.fetchFn ?? llmFetch;
  }

  async chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse> {
    const body: Record<string, unknown> = {
      model: this.model,
      messages: toOpenAiMessages(messages),
      stream: false,
      temperature: options?.temperature ?? 0.2,
    };
    if (options?.tools?.length) {
      body.tools = options.tools;
      body.tool_choice = "auto";
    }
    if (options?.format) {
      body.response_format = toResponseFormat(options.format);
    }

    try {
      return await this.postChat(body, options?.signal);
    } catch (error) {
      if (options?.format && this.isResponseFormatError(error)) {
        const retryBody = { ...body };
        delete retryBody.response_format;
        return this.postChat(retryBody, options?.signal);
      }
      throw error;
    }
  }

  async listModels(): Promise<string[]> {
    const response = await this.request(MODELS_PATH, { method: "GET" });
    const parsed: unknown = await response.json();
    return parseModelsResponse(parsed);
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

  private isResponseFormatError(error: unknown): boolean {
    return error instanceof Error && /response_format|json_schema|400/.test(error.message);
  }

  private async postChat(body: Record<string, unknown>, signal?: AbortSignal): Promise<ChatResponse> {
    const response = await this.request(CHAT_PATH, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal,
    });
    const parsed: unknown = await response.json();
    return parseChatResponse(parsed);
  }

  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    if (this.apiKey) {
      headers.Authorization = `Bearer ${this.apiKey}`;
    }
    return headers;
  }

  private async request(path: string, init: RequestInit): Promise<Response> {
    const label = `OpenAI ${path}`;
    const url = `${this.baseUrl}${path}`;
    // #region agent log
    fetch('http://127.0.0.1:7497/ingest/c1e77a25-b3cb-458d-a22e-6f4c8c0c4060',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'7c9b57'},body:JSON.stringify({sessionId:'7c9b57',location:'openAiClient.ts:request',message:'llm fetch start',data:{url,signalAborted:init.signal?.aborted??false},timestamp:Date.now(),hypothesisId:'A,C'})}).catch(()=>{});
    // #endregion
    try {
      const response = await this.fetchFn(url, {
        ...init,
        headers: { ...this.buildHeaders(), ...(init.headers as Record<string, string> | undefined) },
      });
      if (!response.ok) {
        const bodyText = await readErrorBody(response);
        throw new Error(`${label} failed (${response.status}): ${bodyText}`);
      }
      return response;
    } catch (error) {
      // #region agent log
      fetch('http://127.0.0.1:7497/ingest/c1e77a25-b3cb-458d-a22e-6f4c8c0c4060',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'7c9b57'},body:JSON.stringify({sessionId:'7c9b57',location:'openAiClient.ts:request:catch',message:'llm fetch failed',data:{url,message:error instanceof Error?error.message:'unknown',name:error instanceof Error?error.name:'unknown',cause:error instanceof Error&&'cause' in error?String((error as Error&{cause?:unknown}).cause):undefined,signalAborted:init.signal?.aborted??false},timestamp:Date.now(),hypothesisId:'A,C'})}).catch(()=>{});
      // #endregion
      throw formatLlmFetchError(url, error);
    }
  }
}