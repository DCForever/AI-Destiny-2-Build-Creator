import '../bungie_http_client.dart';
import '../platform_error_codes.dart';

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

/// Arguments for Destiny2 EquipItems (bulk).
class EquipItemsArgs {
  const EquipItemsArgs({
    required this.characterId,
    required this.itemIds,
  });

  final String characterId;

  /// Instance ids to equip (caller sorts exotics last).
  final List<String> itemIds;
}

/// Per-item result from [BungieWriteClient.equipItems].
class EquipItemResultEntry {
  const EquipItemResultEntry({
    required this.instanceId,
    required this.equipStatus,
    this.errorStatus,
  });

  final String instanceId;

  /// Bungie PlatformErrorCodes value (`1` = Success).
  final int equipStatus;

  /// ErrorStatus-style name when known (e.g. `DestinyItemNotFound`).
  final String? errorStatus;

  bool get ok => equipStatus == kPlatformErrorSuccess;

  String get statusText =>
      errorStatusName(equipStatus, errorStatus: errorStatus);
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
///
/// Allowed write endpoints: TransferItem, EquipItem, EquipItems only for apply
/// inventory moves — never dismantle / delete / insert-plug / postmaster pull.
abstract class BungieWriteClient {
  Future<void> transferItem(WriteClientContext ctx, TransferItemArgs args);

  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args);

  /// Bulk equip; returns per-instance status (partial success is normal).
  Future<List<EquipItemResultEntry>> equipItems(
    WriteClientContext ctx,
    EquipItemsArgs args,
  );

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
  Future<List<EquipItemResultEntry>> equipItems(
    WriteClientContext ctx,
    EquipItemsArgs args,
  ) async {
    final response = await _http.postJson(
      '/Destiny2/Actions/Items/EquipItems/',
      accessToken: ctx.accessToken,
      body: {
        'itemIds': args.itemIds,
        'characterId': args.characterId,
        'membershipType': ctx.membershipType,
      },
    );
    return parseEquipItemsResponse(response, requestedIds: args.itemIds);
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
typedef EquipItemsHandler = Future<List<EquipItemResultEntry>> Function(
  WriteClientContext ctx,
  EquipItemsArgs args,
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
    this.onEquipItems,
    this.onApplyArtifactConfig,
    this.onApplyFashionSlot,
  });

  final TransferItemHandler? onTransferItem;
  final EquipItemHandler? onEquipItem;
  final EquipItemsHandler? onEquipItems;
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
  Future<List<EquipItemResultEntry>> equipItems(
    WriteClientContext ctx,
    EquipItemsArgs args,
  ) async {
    final handler = onEquipItems;
    if (handler != null) {
      return handler(ctx, args);
    }
    return [
      for (final id in args.itemIds)
        EquipItemResultEntry(
          instanceId: id,
          equipStatus: kPlatformErrorSuccess,
          errorStatus: 'Success',
        ),
    ];
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
  EquipItemsHandler? equipItems,
  ApplyArtifactHandler? applyArtifactConfig,
  ApplyFashionHandler? applyFashionSlot,
}) {
  return MockBungieWriteClient(
    onTransferItem: transferItem,
    onEquipItem: equipItem,
    onEquipItems: equipItems,
    onApplyArtifactConfig: applyArtifactConfig,
    onApplyFashionSlot: applyFashionSlot,
  );
}

/// Parse EquipItems `Response` into per-item entries.
///
/// Missing requested ids are marked [kDestinyItemNotFound].
List<EquipItemResultEntry> parseEquipItemsResponse(
  Object? response, {
  required List<String> requestedIds,
}) {
  final byId = <String, EquipItemResultEntry>{};
  if (response is Map) {
    final rawResults = response['equipResults'];
    if (rawResults is List) {
      for (final row in rawResults) {
        if (row is! Map) continue;
        final id = '${row['itemInstanceId'] ?? ''}';
        if (id.isEmpty) continue;
        final statusRaw = row['equipStatus'];
        final status = statusRaw is int
            ? statusRaw
            : statusRaw is num
                ? statusRaw.toInt()
                : kDestinyItemNotFound;
        byId[id] = EquipItemResultEntry(
          instanceId: id,
          equipStatus: status,
          errorStatus: errorStatusName(status),
        );
      }
    }
  }
  return [
    for (final id in requestedIds)
      byId[id] ??
          EquipItemResultEntry(
            instanceId: id,
            equipStatus: kDestinyItemNotFound,
            errorStatus: errorStatusName(kDestinyItemNotFound),
          ),
  ];
}
