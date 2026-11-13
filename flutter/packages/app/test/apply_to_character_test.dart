import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  const ctx = WriteClientContext(accessToken: 'test-token', membershipType: 3);

  test('applies items sequentially with progress waiting→applying→done',
      () async {
    final calls = <String>[];
    final phases = <String>[];
    final client = createMockWriteClient(
      equipItem: (c, a) async {
        calls.add(a.instanceId);
      },
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: 'char-1',
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Helmet A',
          itemHash: 1,
          instanceId: 'i1',
          slot: 'helmet',
        ),
        ApplyToCharacterItem(
          id: 'arms',
          label: 'Arms B',
          itemHash: 2,
          instanceId: 'i2',
          slot: 'arms',
        ),
      ],
      onProgress: (p) {
        for (final item in p.items) {
          phases.add('${item.id}:${item.state.name}');
        }
        phases.add('---${p.applyingLine}');
      },
    );

    expect(calls, ['i1', 'i2']);
    expect(result.appliedCount, 2);
    expect(result.failedCount, 0);
    expect(result.summary, '2 applied, 0 failed');
    expect(result.running, isFalse);
    expect(
      result.items.map((i) => i.state).toList(),
      [ApplyItemState.done, ApplyItemState.done],
    );
    // First item goes waiting → applying before second starts.
    expect(phases.any((p) => p.contains('helmet:applying')), isTrue);
    expect(phases.any((p) => p.contains('Applying 1 of 2')), isTrue);
  });

  test('continues after failure and records reason', () async {
    final calls = <String>[];
    final client = createMockWriteClient(
      equipItem: (c, a) async {
        calls.add(a.instanceId);
        if (a.instanceId == 'missing') {
          throw Exception('not in inventory');
        }
      },
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: 'char-1',
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'Item A',
          itemHash: 1,
          instanceId: 'ok1',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'Item B',
          itemHash: 2,
          instanceId: 'missing',
        ),
        ApplyToCharacterItem(
          id: 'c',
          label: 'Item C',
          itemHash: 3,
          instanceId: 'ok2',
        ),
      ],
    );

    expect(calls, ['ok1', 'missing', 'ok2']);
    expect(result.appliedCount, 2);
    expect(result.failedCount, 1);
    expect(result.summary, '2 applied, 1 failed');
    expect(result.items[1].state, ApplyItemState.failed);
    expect(result.items[1].reason, contains('not in inventory'));
    expect(result.items[2].state, ApplyItemState.done);
  });

  test('never invokes dismantle/delete on the write client', () async {
    final client = _RecordingWriteClient();
    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: 'char-1',
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'Item A',
          itemHash: 1,
          instanceId: 'i1',
        ),
      ],
    );
    expect(client.equipCalls, 1);
    expect(client.transferCalls, 0);
    expect(client.dismantleCalls, 0);
    expect(client.deleteCalls, 0);
  });
}

/// Fake write client that also exposes dismantle/delete counters for the
/// safety assertion (those methods are NOT on [BungieWriteClient]).
class _RecordingWriteClient implements BungieWriteClient {
  int equipCalls = 0;
  int transferCalls = 0;
  int dismantleCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args) async {
    equipCalls += 1;
  }

  @override
  Future<void> transferItem(
    WriteClientContext ctx,
    TransferItemArgs args,
  ) async {
    transferCalls += 1;
  }

  @override
  Future<void> applyArtifactConfig(
    WriteClientContext ctx,
    ApplyArtifactArgs args,
  ) async {}

  @override
  Future<void> applyFashionSlot(
    WriteClientContext ctx,
    ApplyFashionArgs args,
  ) async {}

  // Intentionally not part of BungieWriteClient — if apply path ever called
  // these via dynamic/noSuchMethod, the counters stay at 0 and the interface
  // still has no dismantle surface.
  Future<void> dismantleItem() async => dismantleCalls += 1;
  Future<void> deleteItem() async => deleteCalls += 1;
}
