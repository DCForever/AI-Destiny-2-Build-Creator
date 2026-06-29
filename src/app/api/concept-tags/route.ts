import { NextResponse } from "next/server";

import { conceptTagsByFacet } from "@/data/conceptTags";

export const runtime = "nodejs";

export async function GET(): Promise<NextResponse> {
  return NextResponse.json({ facets: conceptTagsByFacet() });
}
