import { describe, expect, it, vi } from "vitest";

import { getServices } from "@/lib/services";

import { GET } from "./route";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(),
}));

describe("manifest search route", () => {
  it("accepts abilities category and filters by ability kind", async () => {
    const search = vi.fn(async () => [
      {
        record: {
          name: "Marksman Golden Gun",
          hash: 1001,
          icon: "/super.png",
          kind: "super",
        },
        confidence: 0.95,
      },
      {
        record: {
          name: "Swarm Grenade",
          hash: 1002,
          icon: "/grenade.png",
          kind: "grenade",
        },
        confidence: 0.85,
      },
    ]);

    vi.mocked(getServices).mockResolvedValue({
      resolver: { search },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request("http://localhost/api/manifest/search?q=golden&category=abilities&kind=super"),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(search).toHaveBeenCalledWith("abilities", "golden", 16);
    expect(body.results).toEqual([
      {
        name: "Marksman Golden Gun",
        hash: 1001,
        icon: "/super.png",
        kind: "super",
        slot: undefined,
        confidence: 0.95,
        isExotic: false,
      },
    ]);
  });
});
