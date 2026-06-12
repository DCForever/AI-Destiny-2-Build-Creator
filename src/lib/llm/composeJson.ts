/**
 * Shared Phase B helper: schema-constrained chat completion parsed by a
 * caller-supplied zod schema, with one corrective retry on rejection.
 */

import type { ZodType } from "zod";

import type { ChatMessage, OllamaClient } from "./ollamaClient";

export function parseStructuredJson<T>(content: string, schema: ZodType<T>): T {
  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error("Model output was not valid JSON");
  }
  const result = schema.safeParse(parsed);
  if (!result.success) {
    const issues = result.error.issues
      .slice(0, 8)
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Output failed schema validation: ${issues}`);
  }
  return result.data;
}

export async function composeJsonWithRetry<T>(
  client: OllamaClient,
  messages: ChatMessage[],
  format: Record<string, unknown>,
  schema: ZodType<T>,
): Promise<T> {
  const first = await client.chat(messages, { format });
  try {
    return parseStructuredJson(first.message.content, schema);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    const retryMessages: ChatMessage[] = [
      ...messages,
      first.message,
      {
        role: "user",
        content: `That output was rejected: ${reason}. Output the corrected JSON now.`,
      },
    ];
    const second = await client.chat(retryMessages, { format });
    return parseStructuredJson(second.message.content, schema);
  }
}
