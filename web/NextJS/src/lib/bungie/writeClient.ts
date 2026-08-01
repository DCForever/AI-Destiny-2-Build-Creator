import { getBungieOAuthConfig } from "@/lib/config/env";

const BUNGIE_BASE = "https://www.bungie.net/Platform";

export type WriteClientContext = {
  accessToken: string;
  membershipType: number;
};

export type TransferItemArgs = {
  itemHash: number;
  instanceId: string;
  characterId: string;
  transferToVault: boolean;
  stackSize?: number;
};

export type EquipItemArgs = {
  itemHash: number;
  instanceId: string;
  characterId: string;
};

export type ApplyArtifactArgs = {
  characterId: string;
  artifactHash: number;
  config: number[];
};

export type ApplyFashionArgs = {
  characterId: string;
  slot: string;
  itemHash: number;
  instanceId?: string;
};

export interface BungieWriteClient {
  transferItem(ctx: WriteClientContext, args: TransferItemArgs): Promise<void>;
  equipItem(ctx: WriteClientContext, args: EquipItemArgs): Promise<void>;
  applyArtifactConfig(ctx: WriteClientContext, args: ApplyArtifactArgs): Promise<void>;
  applyFashionSlot(ctx: WriteClientContext, args: ApplyFashionArgs): Promise<void>;
}

function assertBungieEnvelope(data: unknown): void {
  if (typeof data !== "object" || data === null) {
    throw new Error("Bungie response is not a JSON object");
  }
  const env = data as Record<string, unknown>;
  if (env.ErrorCode !== 1) {
    const msg = typeof env.Message === "string" ? env.Message : "Bungie API error";
    throw new Error(`Bungie API error: ${msg}`);
  }
}

export interface HttpBungieWriteClientOptions {
  apiKey: string;
  fetchFn?: typeof fetch;
}

export class HttpBungieWriteClient implements BungieWriteClient {
  private readonly apiKey: string;
  private readonly fetchFn: typeof fetch;

  constructor(opts: HttpBungieWriteClientOptions) {
    this.apiKey = opts.apiKey;
    this.fetchFn = opts.fetchFn ?? fetch;
  }

  private async bungiePost(path: string, accessToken: string, body: unknown): Promise<void> {
    const response = await this.fetchFn(`${BUNGIE_BASE}${path}`, {
      method: "POST",
      headers: {
        "X-API-Key": this.apiKey,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new Error(`Bungie Platform returned ${response.status}: ${response.statusText}`);
    }
    assertBungieEnvelope(await response.json());
  }

  async transferItem(ctx: WriteClientContext, args: TransferItemArgs): Promise<void> {
    await this.bungiePost("/Destiny2/Actions/Items/TransferItem/", ctx.accessToken, {
      itemReferenceHash: args.itemHash,
      itemId: args.instanceId,
      characterId: args.characterId,
      membershipType: ctx.membershipType,
      transferToVault: args.transferToVault,
      stackSize: args.stackSize ?? 1,
    });
  }

  async equipItem(ctx: WriteClientContext, args: EquipItemArgs): Promise<void> {
    await this.bungiePost("/Destiny2/Actions/Items/EquipItem/", ctx.accessToken, {
      itemId: args.instanceId,
      characterId: args.characterId,
      membershipType: ctx.membershipType,
    });
  }

  async applyArtifactConfig(ctx: WriteClientContext, args: ApplyArtifactArgs): Promise<void> {
    // Seasonal artifact unlocks are socket inserts; surface explicit failure until wired per-season.
    void ctx;
    throw new Error(
      `Artifact apply not fully wired for hash ${args.artifactHash} (config length ${args.config.length})`,
    );
  }

  async applyFashionSlot(ctx: WriteClientContext, args: ApplyFashionArgs): Promise<void> {
    if (!args.instanceId) {
      throw new Error(`Fashion slot ${args.slot}: no owned instance for hash ${args.itemHash}`);
    }
    await this.equipItem(ctx, {
      itemHash: args.itemHash,
      instanceId: args.instanceId,
      characterId: args.characterId,
    });
  }
}

export type MockWriteClientHandlers = Partial<{
  transferItem: BungieWriteClient["transferItem"];
  equipItem: BungieWriteClient["equipItem"];
  applyArtifactConfig: BungieWriteClient["applyArtifactConfig"];
  applyFashionSlot: BungieWriteClient["applyFashionSlot"];
}>;

/** Test double: succeeds by default; override per-method handlers. */
export function createMockWriteClient(handlers: MockWriteClientHandlers = {}): BungieWriteClient {
  const noop = async () => undefined;
  return {
    transferItem: handlers.transferItem ?? noop,
    equipItem: handlers.equipItem ?? noop,
    applyArtifactConfig: handlers.applyArtifactConfig ?? noop,
    applyFashionSlot: handlers.applyFashionSlot ?? noop,
  };
}

export function createBungieWriteClient(): BungieWriteClient | null {
  const config = getBungieOAuthConfig();
  if (!config) return null;
  return new HttpBungieWriteClient({ apiKey: config.apiKey });
}
