import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../inventory_fidelity/compare.dart';
import '../inventory_fidelity/markers.dart';
import '../inventory_fidelity/snapshot.dart';
import '../inventory_fidelity_compare.dart';
import '../inventory_fidelity_gate.dart' show findWorkspaceRoot;

const _defaultResolution = FidelityResolutionCounts(
  resolvedFromTransfer: 380,
  droppedNonEquipment: 40,
  storedTotal: 1140,
  storedEquipment: 1100,
);

InventoryFidelitySnapshot _base({
  FidelityMembership? membership,
  int vaultLocation = 380,
  int kineticBucket = 120,
  FidelityResolutionCounts? resolution = _defaultResolution,
}) {
  return InventoryFidelitySnapshot(
    source: 'test',
    membership: membership ??
        const FidelityMembership(
          membershipType: 3,
          membershipId: 'fixture-membership-001',
          displayName: 'FixtureGuardian',
        ),
    raw: const FidelityRawCounts(
      total: 1250,
      vault: 420,
      characterInventoriesTotal: 530,
      characterEquipmentTotal: 300,
    ),
    parsed: FidelityParsedCounts(
      total: 1180,
      equipmentTotal: 1100,
      subclassTotal: 3,
      byLocation: {
        'vault': vaultLocation,
        'character': 500,
        'equipped': 300,
      },
      byBucket: {
        '1498876634': kineticBucket,
        '2465295065': 95,
      },
    ),
    dropped: const FidelityDroppedCounts(
      total: 70,
      invalidShape: 20,
      unknownBucket: 40,
      missingInstanceId: 10,
    ),
    resolution: resolution,
  );
}

void main() {
  group('InventoryFidelitySnapshot.parse', () {
    test('parses fixture pair from workspace', () {
      final root = findWorkspaceRoot();
      final nextText = File(
        '${root.path}/$kNextMatchFixtureRelativePath',
      ).readAsStringSync();
      final dartText = File(
        '${root.path}/$kDartMatchFixtureRelativePath',
      ).readAsStringSync();
      final next = InventoryFidelitySnapshot.parse(nextText);
      final dart = InventoryFidelitySnapshot.parse(dartText);
      expect(next.raw.total, 1250);
      expect(dart.parsed.byLocation['vault'], 380);
      expect(next.resolution?.resolvedFromTransfer, 380);
      expect(dart.membership?.identityKey, '3:fixture-membership-001');
    });

    test('rejects non-object root', () {
      expect(
        () => InventoryFidelitySnapshot.parse('[]'),
        throwsFormatException,
      );
    });

    test('round-trips toJson', () {
      final s = _base();
      final again = InventoryFidelitySnapshot.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(again.raw.total, s.raw.total);
      expect(again.parsed.byBucket['1498876634'], 120);
      expect(again.resolution?.storedTotal, 1140);
    });
  });

  group('compareInventoryFidelity', () {
    test('matching snapshots pass at tolerance 0', () {
      final result = compareInventoryFidelity(
        next: _base(),
        dart: _base(),
        tolerance: 0,
      );
      expect(result.ok, isTrue);
      expect(result.diffs, isEmpty);
      expect(result.membershipNote, contains('Membership OK'));
    });

    test('workspace fixture pair passes', () {
      final root = findWorkspaceRoot();
      final next = InventoryFidelitySnapshot.parse(
        File('${root.path}/$kNextMatchFixtureRelativePath').readAsStringSync(),
      );
      final dart = InventoryFidelitySnapshot.parse(
        File('${root.path}/$kDartMatchFixtureRelativePath').readAsStringSync(),
      );
      final result = compareInventoryFidelity(next: next, dart: dart);
      expect(result.ok, isTrue, reason: result.report());
    });

    test('byLocation.vault mismatch fails with path', () {
      final result = compareInventoryFidelity(
        next: _base(vaultLocation: 380),
        dart: _base(vaultLocation: 10),
      );
      expect(result.ok, isFalse);
      expect(
        result.diffs.map((d) => d.path),
        contains('parsed.byLocation.vault'),
      );
    });

    test('byBucket mismatch fails with path', () {
      final result = compareInventoryFidelity(
        next: _base(kineticBucket: 120),
        dart: _base(kineticBucket: 99),
      );
      expect(result.ok, isFalse);
      expect(
        result.diffs.map((d) => d.path),
        contains('parsed.byBucket.1498876634'),
      );
    });

    test('resolvedFromTransfer mismatch fails', () {
      final result = compareInventoryFidelity(
        next: _base(
          resolution: const FidelityResolutionCounts(
            resolvedFromTransfer: 380,
            droppedNonEquipment: 40,
            storedTotal: 1140,
            storedEquipment: 1100,
          ),
        ),
        dart: _base(
          resolution: const FidelityResolutionCounts(
            resolvedFromTransfer: 0,
            droppedNonEquipment: 40,
            storedTotal: 760,
            storedEquipment: 720,
          ),
        ),
      );
      expect(result.ok, isFalse);
      final paths = result.diffs.map((d) => d.path).toList();
      expect(paths, contains('resolution.resolvedFromTransfer'));
      expect(paths, contains('resolution.storedTotal'));
    });

    test('membership identity mismatch fails even if counts match', () {
      final result = compareInventoryFidelity(
        next: _base(
          membership: const FidelityMembership(
            membershipType: 3,
            membershipId: 'aaa',
          ),
        ),
        dart: _base(
          membership: const FidelityMembership(
            membershipType: 3,
            membershipId: 'bbb',
          ),
        ),
      );
      expect(result.ok, isFalse);
      expect(
        result.diffs.map((d) => d.path),
        contains('membership.identity'),
      );
    });

    test('one-sided resolution is a fail', () {
      final withRes = _base();
      final withoutRes = InventoryFidelitySnapshot(
        membership: withRes.membership,
        raw: withRes.raw,
        parsed: withRes.parsed,
        dropped: withRes.dropped,
        resolution: null,
      );
      final result = compareInventoryFidelity(next: withRes, dart: withoutRes);
      expect(result.ok, isFalse);
      expect(result.diffs.map((d) => d.path), contains('resolution'));
    });

    test('both missing resolution can pass on other fields', () {
      final a = InventoryFidelitySnapshot(
        raw: const FidelityRawCounts(total: 1),
        parsed: const FidelityParsedCounts(total: 1),
        dropped: const FidelityDroppedCounts(),
      );
      final b = InventoryFidelitySnapshot(
        raw: const FidelityRawCounts(total: 1),
        parsed: const FidelityParsedCounts(total: 1),
        dropped: const FidelityDroppedCounts(),
      );
      expect(compareInventoryFidelity(next: a, dart: b).ok, isTrue);
    });

    test('tolerance allows small absolute delta', () {
      final result = compareInventoryFidelity(
        next: _base(vaultLocation: 380),
        dart: _base(vaultLocation: 382),
        tolerance: 2,
      );
      expect(result.ok, isTrue);
    });

    test('empty inventories match', () {
      final empty = InventoryFidelitySnapshot(
        raw: const FidelityRawCounts(),
        parsed: const FidelityParsedCounts(),
        dropped: const FidelityDroppedCounts(),
        resolution: const FidelityResolutionCounts(),
      );
      expect(compareInventoryFidelity(next: empty, dart: empty).ok, isTrue);
    });

    test('missing byBucket key treated as 0', () {
      final next = _base();
      final dart = InventoryFidelitySnapshot(
        membership: next.membership,
        raw: next.raw,
        parsed: FidelityParsedCounts(
          total: next.parsed.total,
          equipmentTotal: next.parsed.equipmentTotal,
          subclassTotal: next.parsed.subclassTotal,
          byLocation: next.parsed.byLocation,
          byBucket: {
            // kinetic missing → 0 vs 120
            '2465295065': 95,
          },
        ),
        dropped: next.dropped,
        resolution: next.resolution,
      );
      final result = compareInventoryFidelity(next: next, dart: dart);
      expect(result.ok, isFalse);
      expect(
        result.diffs.map((d) => d.path),
        contains('parsed.byBucket.1498876634'),
      );
    });
  });

  group('runInventoryFidelityCompare CLI', () {
    test('matching fixture files exit 0', () {
      final root = findWorkspaceRoot();
      final code = runInventoryFidelityCompare([
        '--next',
        '${root.path}/$kNextMatchFixtureRelativePath',
        '--dart',
        '${root.path}/$kDartMatchFixtureRelativePath',
      ]);
      expect(code, 0);
    });

    test('missing args exit 2', () {
      expect(runInventoryFidelityCompare([]), 2);
    });
  });
}
