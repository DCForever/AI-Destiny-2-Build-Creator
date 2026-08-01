import { NextResponse } from "next/server";

import { getServices } from "@/lib/services";

export const runtime = "nodejs";

export async function GET(): Promise<NextResponse> {
  const { searxng } = await getServices();
  const health = await searxng.healthCheck();
  return NextResponse.json(health);
}
