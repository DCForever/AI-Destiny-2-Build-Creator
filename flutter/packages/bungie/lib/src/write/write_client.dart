import '../bungie_http_client.dart';

/// Auth/membership context for Platform write actions.
class WriteClientContext {
  const WriteClientContext({
    required this.accessToken,
    required this.membershipType,
  });

  final String accessToken;
  final int membershipType;
}

/// Arguments for Destiny2 TransferItem.
class TransferItemArgs {
  const TransferItemArgs({
    required this.itemHash,
    required this.instanceId,
    required this.characterId,
    required this.transferToVault,
    this.stackSize = 1,
  });

  final int itemHash;
  final String instanceId;
  final String characterId;
  final bool transferToVault;
  final int stackSize;
}

/// Arguments for Destiny2 EquipItem.
class EquipItemArgs {
  const EquipItemArgs({
    required this.itemHash,
    required this.instanceId,
    required this.characterId,
  });

  final int itemHash;
  final String instanceId;
  final String characterId;
}

/// Arguments for seasonal artifact apply (season wiring may throw).
class ApplyArtifactArgs {
  const ApplyArtifactArgs({
    required this.characterId,
    required this.artifactHash,
    this.config = const [],
  });

  final String characterId;
  final int artifactHash;
  final List<int> config;
}

/// Arguments for fashion slot apply (equip owned cosmetic instance).
class ApplyFashionArgs {
  const ApplyFashionArgs({
    required this.characterId,
    required this.slot,
    required this.itemHash,
    this.instanceId,
  });

  final String characterId;
  final String slot;
  final int itemHash;
  final String? instanceId;
}

/// Bungie Platform write surface used by equip orchestration (DART-037).
///
/// Hosts inject tokens at call time. Implementations MUST NOT accept or store
/// `CLIENT_SECRET` / `client_secret`.
abstract class BungieWriteClient {
  Future<void> transferItem(WriteClientContext ctx, TransferItemArgs args);

  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args);

  Future<void> applyArtifactConfig(
    WriteClientContext ctx,
    ApplyArtifactArgs args,
  );

  Future<void> applyFashionSlot(WriteClientContext ctx, ApplyFashionArgs args);
}

/// HTTP implementation via [BungieHttpClient] (public API key + Bearer only).
class HttpBungieWriteClient implements BungieWriteClient {
  HttpBungieWriteClient({required BungieHttpClient http}) : _http = http;

  final BungieHttpClient _http;

  @override
  Future<void> transferItem(
    WriteClientContext ctx,
    TransferItemArgs args,
  ) async {
    await _http.postJson(
      '/Destiny2/Actions/Items/TransferItem/',
      accessToken: ctx.accessToken,
      body: {
        'itemReferenceHash': args.itemHash,
        'itemId': args.instanceId,
        'characterId': args.characterId,
        'membershipType': ctx.membershipType,
        'transferToVault': args.transferToVault,
        'stackSize': args.stackSize,
      },
    );
  }

  @override
  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args) async {
    await _http.postJson(
      '/Destiny2/Actions/Items/EquipItem/',
      accessToken: ctx.accessToken,
      body: {
        'itemId': args.instanceId,
        'characterId': args.characterId,
        'membershipType': ctx.membershipType,
      },
    );
  }

  @override
  Future<void> applyArtifactConfig(
    WriteClientContext ctx,
    ApplyArtifactArgs args,
  ) async {
    // Seasonal artifact unlocks are socket inserts; surface explicit failure
    // until wired per-season (product writeClient parity).
    throw StateError(
      'Artifact apply not fully wired for hash ${args.artifactHash} '
      '(config length ${args.config.length})',
    );
  }

  @override
  Future<void> applyFashionSlot(
    WriteClientContext ctx,
    ApplyFashionArgs args,
  ) async {
    final instanceId = args.instanceId;
    if (instanceId == null || instanceId.isEmpty) {
      throw StateError(
        'Fashion slot ${args.slot}: no owned instance for hash ${args.itemHash}',
      );
    }
    await equipItem(
      ctx,
      EquipItemArgs(
        itemHash: args.itemHash,
        instanceId: instanceId,
        characterId: args.characterId,
      ),
    );
  }
}

/// Optional per-method overrides for [MockBungieWriteClient].
typedef TransferItemHandler = Future<void> Function(
  WriteClientContext ctx,
  TransferItemArgs args,
);
typedef EquipItemHandler = Future<void> Function(
  WriteClientContext ctx,
  EquipItemArgs args,
);
typedef ApplyArtifactHandler = Future<void> Function(
  WriteClientContext ctx,
  ApplyArtifactArgs args,
);
typedef ApplyFashionHandler = Future<void> Function(
  WriteClientContext ctx,
  ApplyFashionArgs args,
);

/// Test double: succeeds by default; override per-method handlers.
class MockBungieWriteClient implements BungieWriteClient {
  MockBungieWriteClient({
    this.onTransferItem,
    this.onEquipItem,
    this.onApplyArtifactConfig,
    this.onApplyFashionSlot,
  });

  final TransferItemHandler? onTransferItem;
  final EquipItemHandler? onEquipItem;
  final ApplyArtifactHandler? onApplyArtifactConfig;
  final ApplyFashionHandler? onApplyFashionSlot;

  static Future<void> _noop() async {}

  @override
  Future<void> transferItem(
    WriteClientContext ctx,
    TransferItemArgs args,
  ) async {
    final handler = onTransferItem;
    if (handler != null) {
      await handler(ctx, args);
    } else {
      await _noop();
    }
  }

  @override
  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args) async {
    final handler = onEquipItem;
    if (handler != null) {
      await handler(ctx, args);
    } else {
      await _noop();
    }
  }

  @override
  Future<void> applyArtifactConfig(
    WriteClientContext ctx,
    ApplyArtifactArgs args,
  ) async {
    final handler = onApplyArtifactConfig;
    if (handler != null) {
      await handler(ctx, args);
    } else {
      await _noop();
    }
  }

  @override
  Future<void> applyFashionSlot(
    WriteClientContext ctx,
    ApplyFashionArgs args,
  ) async {
    final handler = onApplyFashionSlot;
    if (handler != null) {
      await handler(ctx, args);
    } else {
      await _noop();
    }
  }
}

/// Factory matching TS `createMockWriteClient` (default success).
BungieWriteClient createMockWriteClient({
  TransferItemHandler? transferItem,
  EquipItemHandler? equipItem,
  ApplyArtifactHandler? applyArtifactConfig,
  ApplyFashionHandler? applyFashionSlot,
}) {
  return MockBungieWriteClient(
    onTransferItem: transferItem,
    onEquipItem: equipItem,
    onApplyArtifactConfig: applyArtifactConfig,
    onApplyFashionSlot: applyFashionSlot,
  );
}
