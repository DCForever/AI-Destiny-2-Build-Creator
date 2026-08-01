import { NextResponse } from "next/server";
import { z } from "zod";

import { generatedBuildSchema } from "@/lib/llm/buildSchema";
import { isAbortError } from "@/lib/llm/llmClient";
import { ManifestNotReadyError, resolveBuildSlot, reResolveBuild } from "@/lib/services";

export const runtime = "nodejs";
export const maxDuration = 60;

const weaponSection = z.object({
  slot: z.enum(["Kinetic", "Energy", "Power"]),
  name: z.string().trim().min(1),
  isExotic: z.boolean(),
  perks: z.array(z.object({
    name: z.string().trim().min(1),
    rationale: z.string().trim().optional(),
  })).max(5),
  rationale: z.string().trim().min(1),
});

const resolveSlotSchema = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("weapon"),
    build: generatedBuildSchema,
    activity: z.string().trim().min(1),
    slot: z.enum(["Kinetic", "Energy", "Power"]),
    weapon: weaponSection,
  }),
  z.object({
    kind: z.literal("full"),
    build: generatedBuildSchema,
    activity: z.string().trim().min(1),
  }),
]);

function errorStatus(error: unknown): number {
  if (error instanceof ManifestNotReadyError) return 503;
  return 500;
}

export async function POST(request: Request): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = resolveSlotSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid resolve request: ${issues}` }, { status: 400 });
  }

  try {
    if (parsed.data.kind === "full") {
      const outcome = await reResolveBuild(parsed.data.build, parsed.data.activity);
      return NextResponse.json(outcome);
    }

    const outcome = await resolveBuildSlot({
      build: parsed.data.build,
      activity: parsed.data.activity,
      slot: parsed.data.slot,
      weapon: parsed.data.weapon,
    });
    return NextResponse.json(outcome);
  } catch (error) {
    if (isAbortError(error)) {
      return new NextResponse(null, { status: 499 });
    }
    const message = error instanceof Error ? error.message : "Resolve failed";
    return NextResponse.json({ error: message }, { status: errorStatus(error) });
  }
}
