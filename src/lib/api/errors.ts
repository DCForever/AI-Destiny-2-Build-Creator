export const API_ERROR_CODES = {
  INVALID_TAG: "INVALID_TAG",
  DUPLICATE_SET_NAME: "DUPLICATE_SET_NAME",
  SLOT_OCCUPIED: "SLOT_OCCUPIED",
  SLOT_CONFLICT: "SLOT_CONFLICT",
  SET_IN_USE: "SET_IN_USE",
  INVALID_ITEM: "INVALID_ITEM",
  INVALID_SYNERGY_LINK: "INVALID_SYNERGY_LINK",
  PAIR_ARMOR_MISMATCH: "PAIR_ARMOR_MISMATCH",
} as const;

export type ApiErrorCode = (typeof API_ERROR_CODES)[keyof typeof API_ERROR_CODES];

export class ApiError extends Error {
  constructor(
    public readonly code: ApiErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>,
    public readonly status = 400,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function isApiError(value: unknown): value is ApiError {
  return value instanceof ApiError;
}
