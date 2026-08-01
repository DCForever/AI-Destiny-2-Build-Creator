import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@/lib/api/requireUser", () => ({
  requireAuthenticatedUser: vi.fn(async () => ({ user: { id: 1 } })),
}));

vi.mock("@/lib/db/client", () => ({
  getDb: vi.fn(),
}));

vi.mock("@/lib/builds/createSetAndAttach", () => ({
  createSetAndAttachBodySchema: {
    safeParse: (v: unknown) => ({ success: true as const, data: v }),
  },
  createSetAndAttach: vi.fn(async () => ({
    set: { id: "s1", name: "X Armor", type: "armor" },
    attachment: { setId: "s1", mode: "live", variantId: "v1", replacedSetIds: [] },
  })),
}));

import { POST } from "@/app/api/user/builds/[id]/create-set-attach/route";
import { createSetAndAttach } from "@/lib/builds/createSetAndAttach";

describe("POST create-set-attach", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns created set + attachment", async () => {
    const req = new Request("http://local/api", {
      method: "POST",
      body: JSON.stringify({ variantId: "v1", type: "armor" }),
    });
    const res = await POST(req, { params: Promise.resolve({ id: "b1" }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.set.id).toBe("s1");
    expect(createSetAndAttach).toHaveBeenCalled();
  });
});
