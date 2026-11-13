import 'builds_mock_models.dart';

/// Pure helpers for the Builds mock-up (testable without widgets).

bool heldExceedsCap(int held, int cap) => held > cap;

String moreThanCapLabel(int cap) => 'More than $cap held';

bool isZeroHeldWarning(int held) => held <= 0;

MockSetReadiness computeSetReadiness({
  required MockArmorSet set,
  required List<MockBuild> builds,
}) {
  final using = builds.where((b) => b.setIds.contains(set.id)).toList();
  final slotUses = <String, int>{
    for (final slot in kMockArmorSlots) slot: 0,
  };
  for (final build in using) {
    for (final assignment in build.slots) {
      if (assignment.setId != set.id) continue;
      slotUses[assignment.slot] = (slotUses[assignment.slot] ?? 0) + 1;
    }
  }
  final enoughBuilds = using.length >= kMockReadyBuildCount;
  final everySlot = kMockArmorSlots.every(
    (slot) => (slotUses[slot] ?? 0) >= kMockReadySlotUses,
  );
  return MockSetReadiness(
    setId: set.id,
    setName: set.name,
    buildCount: using.length,
    slotUses: slotUses,
    status: enoughBuilds && everySlot
        ? MockReadiness.ready
        : MockReadiness.notReady,
  );
}

List<MockSetReadiness> computeAllReadiness(BuildsMockFixture fixture) {
  return [
    for (final set in fixture.sets)
      computeSetReadiness(set: set, builds: fixture.builds),
  ];
}

/// Read [MockBuild.isOptimized]. No Optimize producer yet → always false.
bool isMockBuildOptimized(MockBuild build) => build.isOptimized;

/// Whether [build] counts as Fill In "Filled In" for the readiness filter.
///
/// Includes `proposed` rows (via [filledInBuildIds] from [buildsMockHasFillIn])
/// and any slot with [MockSlotAssignment.filledIn], matching the card badge.
bool buildMatchesFilledInReadiness(
  MockBuild build, {
  Set<String> filledInBuildIds = const {},
}) {
  if (filledInBuildIds.contains(build.id)) return true;
  return build.slots.any((s) => s.filledIn);
}

List<MockBuild> filterMockBuilds({
  required List<MockBuild> builds,
  String query = '',
  String? exoticArmor,
  String? exoticWeapon,
  String? subclass,
  String? setId,
  MockReadiness? readiness,
  List<MockSetReadiness> readinessRows = const [],
  Set<String> filledInBuildIds = const {},
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final b in builds)
      if (_matches(
        b,
        q: q,
        exoticArmor: exoticArmor,
        exoticWeapon: exoticWeapon,
        subclass: subclass,
        setId: setId,
        readiness: readiness,
        readinessRows: readinessRows,
        filledInBuildIds: filledInBuildIds,
      ))
        b,
  ];
}

bool _matches(
  MockBuild b, {
  required String q,
  String? exoticArmor,
  String? exoticWeapon,
  String? subclass,
  String? setId,
  MockReadiness? readiness,
  required List<MockSetReadiness> readinessRows,
  required Set<String> filledInBuildIds,
}) {
  if (q.isNotEmpty) {
    final hay = '${b.name} ${b.exoticArmor} ${b.exoticWeapon} ${b.subclass}'
        .toLowerCase();
    if (!hay.contains(q)) return false;
  }
  if (exoticArmor != null &&
      exoticArmor.isNotEmpty &&
      b.exoticArmor != exoticArmor) {
    return false;
  }
  if (exoticWeapon != null &&
      exoticWeapon.isNotEmpty &&
      b.exoticWeapon != exoticWeapon) {
    return false;
  }
  if (subclass != null && subclass.isNotEmpty && b.subclass != subclass) {
    return false;
  }
  if (setId != null && setId.isNotEmpty && !b.setIds.contains(setId)) {
    return false;
  }
  if (readiness != null) {
    switch (readiness) {
      case MockReadiness.filledIn:
        return buildMatchesFilledInReadiness(
          b,
          filledInBuildIds: filledInBuildIds,
        );
      case MockReadiness.optimized:
        return isMockBuildOptimized(b);
      case MockReadiness.ready:
      case MockReadiness.notReady:
        final rows = readinessRows.where((r) => b.setIds.contains(r.setId));
        if (rows.isEmpty) return readiness == MockReadiness.notReady;
        if (readiness == MockReadiness.ready) {
          return rows.any((r) => r.status == MockReadiness.ready);
        }
        return rows.every((r) => r.status == MockReadiness.notReady);
    }
  }
  return true;
}

int clampInventoryCap(int value) {
  if (value < kMockMinInventoryCap) return kMockMinInventoryCap;
  if (value > kMockMaxInventoryCap) return kMockMaxInventoryCap;
  return value;
}
