import { NextResponse } from "next/server";

import { isApiError } from "@/lib/api/errors";

export function apiErrorResponse(error: unknown): NextResponse {
  if (isApiError(error)) {
    return NextResponse.json(
      { error: error.message, code: error.code, ...error.details },
      { status: error.status },
    );
  }
  console.error(error);
  return NextResponse.json({ error: "Internal server error" }, { status: 500 });
}

export function unauthorizedResponse(): NextResponse {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}
