import type { AppDatabase } from "@/lib/db/client";
import { findDuplicateName } from "@/lib/db/repositories/setRepository";
import type { SetType } from "@/lib/sets/schemas";

/** Allocate a unique set name within user+type, suffixing ` (2)`, ` (3)`, … */
export function allocateUniqueSetName(
  db: AppDatabase,
  userId: number,
  type: SetType,
  baseName: string,
): string {
  const trimmed = baseName.trim() || "Set";
  if (!findDuplicateName(db, userId, type, trimmed)) return trimmed;
  for (let n = 2; n < 10_000; n += 1) {
    const candidate = `${trimmed} (${n})`;
    if (!findDuplicateName(db, userId, type, candidate)) return candidate;
  }
  throw new Error(`Could not allocate unique set name for ${type}`);
}
