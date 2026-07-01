import { instanceFilterQuerySchema } from "./schemas";
import type { InstanceFilterCriteria } from "./types";
import { kindFromQuery } from "./filterInstances";

export class InvalidInstanceFilterError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidInstanceFilterError";
  }
}

export function parseInstanceFilterQuery(params: URLSearchParams): InstanceFilterCriteria {
  const raw = {
    itemHash: params.get("itemHash") ?? undefined,
    bucket: params.get("bucket") ?? undefined,
    kind: params.get("kind") ?? undefined,
    q: params.get("q") ?? undefined,
    sortBy: params.get("sortBy") ?? undefined,
  };

  const parsed = instanceFilterQuerySchema.safeParse(raw);
  if (!parsed.success) {
    throw new InvalidInstanceFilterError("INVALID_FILTER");
  }

  return {
    itemHash: parsed.data.itemHash,
    bucket: parsed.data.bucket,
    kind: kindFromQuery(parsed.data.kind),
    q: parsed.data.q,
    sortBy: parsed.data.sortBy,
  };
}
