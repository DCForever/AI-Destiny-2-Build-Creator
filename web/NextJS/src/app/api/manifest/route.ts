import { NextResponse } from "next/server";

import { getManifestStatus, refreshManifest } from "@/lib/services";

export const runtime = "nodejs";
/** Raw table downloads are large; allow up to 5 minutes. */
export const maxDuration = 300;

export async function GET(): Promise<NextResponse> {
  try {
    const status = await getManifestStatus();
    return NextResponse.json(status);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Manifest status failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(): Promise<NextResponse> {
  try {
    const status = await refreshManifest();
    return NextResponse.json(status);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Manifest refresh failed";
    const status = /BUNGIE_API_KEY/.test(message) ? 400 : 502;
    return NextResponse.json({ error: message }, { status });
  }
}
