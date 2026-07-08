import { beforeEach, describe, expect, it, vi } from "vitest";

import { getServices } from "@/lib/services";

import { GET } from "./route";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(),
}));

describe("manifest search route", () => {
  beforeEach(() => {
    vi.mocked(getServices).mockReset();
  });

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

  it("browses empty ability searches within class and element scope", async () => {
    const search = vi.fn();
    const getStore = vi.fn(async () => [
      {
        name: "Stormtrance",
        hash: 2001,
        icon: "/storm.png",
        kind: "super",
        classType: "Warlock",
        element: "Arc",
      },
      {
        name: "Fists of Havoc",
        hash: 2002,
        icon: "/fists.png",
        kind: "super",
        classType: "Titan",
        element: "Arc",
      },
      {
        name: "Daybreak",
        hash: 2003,
        icon: "/daybreak.png",
        kind: "super",
        classType: "Warlock",
        element: "Solar",
      },
      {
        name: "Arcbolt Grenade",
        hash: 2004,
        icon: "/arcbolt.png",
        kind: "grenade",
        classType: null,
        element: "Arc",
      },
    ]);

    vi.mocked(getServices).mockResolvedValue({
      resolver: { search },
      entityCache: { getStore },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request(
        "http://localhost/api/manifest/search?q=&category=abilities&kind=super&classType=Warlock&element=Arc",
      ),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(getStore).toHaveBeenCalledWith("abilities");
    expect(search).not.toHaveBeenCalled();
    expect(body.results).toEqual([
      {
        name: "Stormtrance",
        hash: 2001,
        icon: "/storm.png",
        kind: "super",
        slot: undefined,
        classType: "Warlock",
        element: "Arc",
        confidence: 1,
        isExotic: false,
      },
    ]);
  });

  it("does not mix Prismatic empty ability browse with other elements", async () => {
    const getStore = vi.fn(async () => [
      {
        name: "Song of Flame",
        hash: 2101,
        icon: "/solar.png",
        kind: "super",
        classType: "Warlock",
        element: "Solar",
      },
      {
        name: "Storm's Edge",
        hash: 2102,
        icon: "/prismatic.png",
        kind: "super",
        classType: "Warlock",
        element: "Prismatic",
      },
      {
        name: "Stormtrance",
        hash: 2103,
        icon: "/arc.png",
        kind: "super",
        classType: "Warlock",
        element: "Arc",
      },
    ]);

    vi.mocked(getServices).mockResolvedValue({
      resolver: { search: vi.fn() },
      entityCache: { getStore },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request(
        "http://localhost/api/manifest/search?category=abilities&kind=super&classType=Warlock&element=Prismatic",
      ),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.results.map((result: { name: string }) => result.name)).toEqual(["Storm's Edge"]);
  });

  it("browses empty exotic armor searches within class scope", async () => {
    const getStore = vi.fn(async () => [
      {
        name: "Cuirass of the Falling Star",
        hash: 3001,
        icon: "/cuirass.png",
        classType: "Titan",
        slot: "Chest",
      },
      {
        name: "Crown of Tempests",
        hash: 3002,
        icon: "/crown.png",
        classType: "Warlock",
        slot: "Helmet",
      },
    ]);

    vi.mocked(getServices).mockResolvedValue({
      resolver: { search: vi.fn() },
      entityCache: { getStore },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request("http://localhost/api/manifest/search?category=exotic-armor&classType=Titan"),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.results).toEqual([
      {
        name: "Cuirass of the Falling Star",
        hash: 3001,
        icon: "/cuirass.png",
        slot: "Chest",
        kind: undefined,
        classType: "Titan",
        element: undefined,
        confidence: 1,
        isExotic: false,
      },
    ]);
  });

  it("uses resolver search for non-empty queries and applies scope filters", async () => {
    const search = vi.fn(async () => [
      {
        record: {
          name: "Stormtrance",
          hash: 4001,
          icon: "/storm.png",
          kind: "super",
          classType: "Warlock",
          element: "Arc",
        },
        confidence: 0.91,
      },
      {
        record: {
          name: "Storm Grenade",
          hash: 4002,
          icon: "/grenade.png",
          kind: "grenade",
          classType: "Titan",
          element: "Arc",
        },
        confidence: 0.89,
      },
    ]);
    const getStore = vi.fn();

    vi.mocked(getServices).mockResolvedValue({
      resolver: { search },
      entityCache: { getStore },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request("http://localhost/api/manifest/search?q=storm&category=abilities&classType=Warlock&element=Arc"),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(search).toHaveBeenCalledWith("abilities", "storm", 16);
    expect(getStore).not.toHaveBeenCalled();
    expect(body.results.map((result: { name: string }) => result.name)).toEqual(["Stormtrance"]);
  });

  it("rejects empty browse for non-browse categories", async () => {
    vi.mocked(getServices).mockResolvedValue({
      resolver: { search: vi.fn() },
      entityCache: { getStore: vi.fn() },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(new Request("http://localhost/api/manifest/search?category=weapons"));
    const body = await response.json();

    expect(response.status).toBe(400);
    expect(body.error).toMatch(/empty search/i);
  });
});
