// Compare two inventory fidelity snapshots (DART-054 / GAP-INV-05).
//
// Default tolerance is 0 (exact match). Absolute delta ≤ tolerance passes.

import 'snapshot.dart';

/// One mismatched field path.
class InventoryFidelityDiff {
  const InventoryFidelityDiff({
    required this.path,
    required this.nextValue,
    required this.dartValue,
    required this.delta,
  });

  final String path;
  final Object? nextValue;
  final Object? dartValue;
  final int delta;

  @override
  String toString() =>
      '$path: next=$nextValue dart=$dartValue |delta|=$delta';
}

/// Result of comparing Next vs Dart inventory count snapshots.
class InventoryFidelityCompareResult {
  const InventoryFidelityCompareResult({
    required this.ok,
    required this.tolerance,
    required this.diffs,
    this.membershipNote,
  });

  final bool ok;
  final int tolerance;
  final List<InventoryFidelityDiff> diffs;
  final String? membershipNote;

  String report() {
    final buf = StringBuffer();
    buf.writeln(
      ok
          ? 'INVENTORY FIDELITY: PASS (tolerance=$tolerance)'
          : 'INVENTORY FIDELITY: FAIL (tolerance=$tolerance)',
    );
    if (membershipNote != null) {
      buf.writeln(membershipNote);
    }
    if (diffs.isEmpty) {
      buf.writeln('No count diffs.');
    } else {
      buf.writeln('Diffs (${diffs.length}):');
      for (final d in diffs) {
        buf.writeln('  - $d');
      }
    }
    return buf.toString().trimRight();
  }
}

/// Compare [next] vs [dart] snapshots.
///
/// [tolerance] is the maximum allowed absolute delta per scalar field
/// (default 0). Membership identity must match when either side provides an id.
InventoryFidelityCompareResult compareInventoryFidelity({
  required InventoryFidelitySnapshot next,
  required InventoryFidelitySnapshot dart,
  int tolerance = 0,
}) {
  if (tolerance < 0) {
    throw ArgumentError.value(tolerance, 'tolerance', 'must be >= 0');
  }

  final diffs = <InventoryFidelityDiff>[];
  String? membershipNote;

  final mNext = next.membership;
  final mDart = dart.membership;
  if (mNext != null || mDart != null) {
    if (mNext == null || mDart == null) {
      diffs.add(
        InventoryFidelityDiff(
          path: 'membership',
          nextValue: mNext?.identityKey,
          dartValue: mDart?.identityKey,
          delta: 1,
        ),
      );
      membershipNote =
          'Membership present on only one side — same-membership dual-run required.';
    } else if (mNext.identityKey != mDart.identityKey) {
      diffs.add(
        InventoryFidelityDiff(
          path: 'membership.identity',
          nextValue: mNext.identityKey,
          dartValue: mDart.identityKey,
          delta: 1,
        ),
      );
      membershipNote =
          'Membership mismatch: next=${mNext.identityKey} dart=${mDart.identityKey}';
    } else {
      membershipNote = 'Membership OK: ${mNext.identityKey}';
    }
  }

  void scalar(String path, int a, int b) {
    final delta = (a - b).abs();
    if (delta > tolerance) {
      diffs.add(
        InventoryFidelityDiff(
          path: path,
          nextValue: a,
          dartValue: b,
          delta: delta,
        ),
      );
    }
  }

  // Raw
  scalar('raw.total', next.raw.total, dart.raw.total);
  scalar('raw.vault', next.raw.vault, dart.raw.vault);
  scalar(
    'raw.characterInventoriesTotal',
    next.raw.characterInventoriesTotal,
    dart.raw.characterInventoriesTotal,
  );
  scalar(
    'raw.characterEquipmentTotal',
    next.raw.characterEquipmentTotal,
    dart.raw.characterEquipmentTotal,
  );

  // Parsed scalars
  scalar('parsed.total', next.parsed.total, dart.parsed.total);
  scalar(
    'parsed.equipmentTotal',
    next.parsed.equipmentTotal,
    dart.parsed.equipmentTotal,
  );
  scalar(
    'parsed.subclassTotal',
    next.parsed.subclassTotal,
    dart.parsed.subclassTotal,
  );

  // byLocation / byBucket — missing key = 0
  _diffMaps(
    diffs: diffs,
    prefix: 'parsed.byLocation',
    a: next.parsed.byLocation,
    b: dart.parsed.byLocation,
    tolerance: tolerance,
  );
  _diffMaps(
    diffs: diffs,
    prefix: 'parsed.byBucket',
    a: next.parsed.byBucket,
    b: dart.parsed.byBucket,
    tolerance: tolerance,
  );

  // Dropped
  scalar('dropped.total', next.dropped.total, dart.dropped.total);
  scalar(
    'dropped.invalidShape',
    next.dropped.invalidShape,
    dart.dropped.invalidShape,
  );
  scalar(
    'dropped.unknownBucket',
    next.dropped.unknownBucket,
    dart.dropped.unknownBucket,
  );
  scalar(
    'dropped.missingInstanceId',
    next.dropped.missingInstanceId,
    dart.dropped.missingInstanceId,
  );

  // Resolution — both absent OK; one-sided presence is a fail
  final rNext = next.resolution;
  final rDart = dart.resolution;
  if (rNext == null && rDart == null) {
    // ok
  } else if (rNext == null || rDart == null) {
    diffs.add(
      InventoryFidelityDiff(
        path: 'resolution',
        nextValue: rNext == null ? null : 'present',
        dartValue: rDart == null ? null : 'present',
        delta: 1,
      ),
    );
  } else {
    scalar(
      'resolution.resolvedFromTransfer',
      rNext.resolvedFromTransfer,
      rDart.resolvedFromTransfer,
    );
    scalar(
      'resolution.droppedNonEquipment',
      rNext.droppedNonEquipment,
      rDart.droppedNonEquipment,
    );
    scalar(
      'resolution.storedTotal',
      rNext.storedTotal,
      rDart.storedTotal,
    );
    scalar(
      'resolution.storedEquipment',
      rNext.storedEquipment,
      rDart.storedEquipment,
    );
  }

  return InventoryFidelityCompareResult(
    ok: diffs.isEmpty,
    tolerance: tolerance,
    diffs: List.unmodifiable(diffs),
    membershipNote: membershipNote,
  );
}

void _diffMaps({
  required List<InventoryFidelityDiff> diffs,
  required String prefix,
  required Map<String, int> a,
  required Map<String, int> b,
  required int tolerance,
}) {
  final keys = {...a.keys, ...b.keys}.toList()..sort();
  for (final key in keys) {
    final av = a[key] ?? 0;
    final bv = b[key] ?? 0;
    final delta = (av - bv).abs();
    if (delta > tolerance) {
      diffs.add(
        InventoryFidelityDiff(
          path: '$prefix.$key',
          nextValue: av,
          dartValue: bv,
          delta: delta,
        ),
      );
    }
  }
}
