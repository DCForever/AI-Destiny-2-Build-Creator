import { describe, expect, it, vi } from "vitest";

import { HttpBungieWriteClient, createMockWriteClient } from "@/lib/bungie/writeClient";

describe("BungieWriteClient", () => {
  it("mock succeeds by default", async () => {
    const client = createMockWriteClient();
    const ctx = { accessToken: "t", membershipType: 3 };
    await expect(
      client.transferItem(ctx, {
        itemHash: 1,
        instanceId: "i",
        characterId: "c",
        transferToVault: false,
      }),
    ).resolves.toBeUndefined();
  });

  it("HTTP transfer posts TransferItem body", async () => {
    const fetchFn = vi.fn(async () =>
      Response.json({ ErrorCode: 1, Response: 0, Message: "Ok" }),
    );
    const client = new HttpBungieWriteClient({ apiKey: "key", fetchFn: fetchFn as typeof fetch });
    await client.transferItem(
      { accessToken: "tok", membershipType: 3 },
      {
        itemHash: 42,
        instanceId: "inst",
        characterId: "char",
        transferToVault: true,
      },
    );
    expect(fetchFn).toHaveBeenCalledOnce();
    const call = fetchFn.mock.calls[0] as unknown as [string, RequestInit];
    const [url, init] = call;
    expect(String(url)).toContain("/Destiny2/Actions/Items/TransferItem/");
    expect(init.method).toBe("POST");
    expect(JSON.parse(String(init.body))).toMatchObject({
      itemReferenceHash: 42,
      itemId: "inst",
      characterId: "char",
      transferToVault: true,
      membershipType: 3,
    });
  });
});
