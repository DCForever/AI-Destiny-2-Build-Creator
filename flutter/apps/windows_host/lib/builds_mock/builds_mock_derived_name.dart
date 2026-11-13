import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

import 'builds_mock_models.dart';

/// Joiner for default loadout name segments (015 contract).
const String kBuildsMockNameJoiner = ' · ';

/// Segments for a derived Builds mock title (Class · Element · Super · …).
class BuildsMockDerivedName {
  const BuildsMockDerivedName({
    required this.classLabel,
    required this.elementLabel,
    required this.superLabel,
    required this.exoticArmor,
    required this.exoticWeapon,
    required this.synergy,
    required this.duplicateSuffix,
    required this.sourceName,
  });

  final String? classLabel;
  final String? elementLabel;
  final String? superLabel;
  final String? exoticArmor;
  final String? exoticWeapon;
  final String? synergy;
  final int? duplicateSuffix;

  /// Original matrix / DIM loadout name (muted subtitle).
  final String sourceName;

  /// Spoken / searchable form — never includes `None`, omits missing segments.
  String get text {
    final parts = <String>[
      if (_present(classLabel)) classLabel!.trim(),
      if (_present(elementLabel)) elementLabel!.trim(),
      if (_present(superLabel)) superLabel!.trim(),
      if (_present(exoticArmor)) exoticArmor!.trim(),
      if (_present(exoticWeapon)) exoticWeapon!.trim(),
      if (_present(synergy)) synergy!.trim(),
    ];
    if (duplicateSuffix != null && duplicateSuffix! >= 2) {
      parts.add('${duplicateSuffix!}');
    }
    return parts.join(kBuildsMockNameJoiner);
  }

  bool get hasIcons =>
      _present(classLabel) || _present(elementLabel) || _present(superLabel);
}

bool _present(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return false;
  if (t.toLowerCase() == 'none') return false;
  if (t == '—') return false;
  return true;
}

/// Super ability from cached DIM subclass data when present; otherwise omit.
String? dimLoadoutSuperName(CachedDimLoadout? loadout) {
  if (loadout == null) return null;
  final fromSubclass = loadout.subclass?.superName?.trim();
  if (fromSubclass != null &&
      fromSubclass.isNotEmpty &&
      fromSubclass.toLowerCase() != 'none') {
    return fromSubclass;
  }
  // DIM ability socket order is typically class / jump / super / melee / grenade.
  final plugs = loadout.subclassPlugs;
  if (plugs.length >= 3) {
    final candidate = plugs[2].name.trim();
    if (candidate.isNotEmpty && candidate.toLowerCase() != 'none') {
      return candidate;
    }
  }
  return null;
}

String? dimLoadoutSuperIconPath(CachedDimLoadout? loadout) {
  final path = loadout?.subclass?.superIconPath?.trim();
  if (path == null || path.isEmpty) return null;
  return path;
}

String? dimLoadoutClassLabel(CachedDimLoadout? loadout) {
  return guardianClassLabelForClassType(loadout?.classType);
}

String? dimLoadoutElementLabel({
  required MockBuild build,
  CachedDimLoadout? loadout,
}) {
  final fromLoadout = loadout?.subclass?.name.trim();
  if (fromLoadout != null &&
      fromLoadout.isNotEmpty &&
      fromLoadout.toLowerCase() != 'none') {
    return fromLoadout;
  }
  final fromBuild = build.subclass.trim();
  if (fromBuild.isEmpty || fromBuild.toLowerCase() == 'none') return null;
  return fromBuild;
}

/// Derive the default loadout name for one build.
///
/// [duplicateIndexWithinClass] is 1-based among builds that share the same
/// base derived text within a guardian class; values ≥2 append ` · N`.
BuildsMockDerivedName deriveBuildsMockName({
  required MockBuild build,
  CachedDimLoadout? loadout,
  int duplicateIndexWithinClass = 1,
  String? synergy,
}) {
  final classLabel = dimLoadoutClassLabel(loadout);
  final element = dimLoadoutElementLabel(build: build, loadout: loadout);
  final superName = dimLoadoutSuperName(loadout);
  final armor = _clean(build.exoticArmor);
  final weapon = _clean(build.exoticWeapon);
  final source = _clean(build.name) ??
      _clean(loadout?.name) ??
      'Build';
  return BuildsMockDerivedName(
    classLabel: classLabel,
    elementLabel: element,
    superLabel: superName,
    exoticArmor: armor,
    exoticWeapon: weapon,
    synergy: _clean(synergy),
    duplicateSuffix:
        duplicateIndexWithinClass >= 2 ? duplicateIndexWithinClass : null,
    sourceName: source,
  );
}

String? _clean(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  if (t.toLowerCase() == 'none') return null;
  if (t == '—') return null;
  return t;
}

/// Assign 1-based duplicate indices for derived names within each class.
///
/// Builds are considered in [builds] order. Index keys are [MockBuild.id].
Map<String, int> buildsMockDerivedNameDuplicateIndices({
  required List<MockBuild> builds,
  required MockBuild Function(MockBuild) enrich,
  CachedDimLoadout? Function(MockBuild)? loadoutFor,
  String? Function(MockBuild)? synergyFor,
}) {
  final counts = <String, int>{};
  final out = <String, int>{};
  for (final build in builds) {
    final loadout = loadoutFor?.call(build);
    final enriched = enrich(build);
    final classKey = dimLoadoutClassLabel(loadout) ?? '';
    final base = deriveBuildsMockName(
      build: enriched,
      loadout: loadout,
      synergy: synergyFor?.call(build),
    );
    // Duplicate key ignores the numeric suffix itself.
    final key = '$classKey\u0000${[
      if (_present(base.classLabel)) base.classLabel,
      if (_present(base.elementLabel)) base.elementLabel,
      if (_present(base.superLabel)) base.superLabel,
      if (_present(base.exoticArmor)) base.exoticArmor,
      if (_present(base.exoticWeapon)) base.exoticWeapon,
      if (_present(base.synergy)) base.synergy,
    ].join(kBuildsMockNameJoiner)}';
    final next = (counts[key] ?? 0) + 1;
    counts[key] = next;
    out[build.id] = next;
  }
  return out;
}

/// Combine set-bonus rows: one box for an active 4pc (2pc+4pc text), else
/// separate boxes only for distinct 2pc sets.
List<MockSetBonus> combineBuildsMockSetBonuses(List<MockSetBonus> raw) {
  if (raw.isEmpty) return const [];
  final bySet = <String, List<MockSetBonus>>{};
  for (final b in raw) {
    bySet.putIfAbsent(b.setId, () => <MockSetBonus>[]).add(b);
  }
  final out = <MockSetBonus>[];
  for (final entry in bySet.entries) {
    final rows = entry.value;
    final has4 = rows.any((r) => r.pieces >= 4 || r.tier == '4pc');
    if (has4) {
      final two = rows.where((r) => r.pieces == 2 || r.tier == '2pc').toList();
      final four = rows.where((r) => r.pieces >= 4 || r.tier == '4pc').toList();
      final effects = <String>[
        for (final r in [...two, ...four])
          if (r.text.trim().isNotEmpty) r.text.trim(),
      ];
      final name = (four.isNotEmpty ? four.first : rows.first).setName;
      out.add(
        MockSetBonus(
          setId: entry.key,
          setName: name,
          pieces: 4,
          tier: '4pc',
          text: effects.join('\n'),
        ),
      );
    } else {
      for (final r in rows) {
        if (r.text.trim().isEmpty) continue;
        out.add(r);
      }
    }
  }
  return List<MockSetBonus>.unmodifiable(out);
}
