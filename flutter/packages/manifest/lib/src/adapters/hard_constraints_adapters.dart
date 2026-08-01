import 'package:destiny2_domain/destiny2_domain.dart';

import '../entity_cache.dart';
import '../types/records.dart';
import '../types/stores.dart';
import 'mod_energy.dart';

class FragmentCapacityResult {
  const FragmentCapacityResult({
    required this.capacity,
    required this.resolvedCount,
  });

  final int capacity;
  final int resolvedCount;
}

class ModEnergyConfig {
  const ModEnergyConfig({
    required this.slot,
    required this.modHashes,
    this.tier,
  });

  final String slot;
  final List<int> modHashes;
  final int? tier;
}

class HardConstraintAdapterResult {
  const HardConstraintAdapterResult({
    required this.evaluation,
    this.fragmentCapacity,
    this.aspectCount,
    this.illegalModMessages = const [],
  });

  final ConstraintEvaluation evaluation;
  final int? fragmentCapacity;
  final int? aspectCount;
  final List<String> illegalModMessages;

  bool get hasHardBlocks =>
      evaluation.hardBlocks.isNotEmpty || illegalModMessages.isNotEmpty;
}

/// Resolve total fragment capacity from aspect display names (product parity).
Future<FragmentCapacityResult> resolveFragmentCapacity(
  FileEntityCache cache,
  List<String> aspectNames,
) async {
  if (aspectNames.isEmpty) {
    return const FragmentCapacityResult(capacity: 0, resolvedCount: 0);
  }
  final aspects = await cache.getStore<AspectRecord>(MvpStoreName.aspects);
  final byName = <String, AspectRecord>{
    for (final a in aspects) a.name.trim().toLowerCase(): a,
  };

  var capacity = 0;
  var resolvedCount = 0;
  for (final name in aspectNames) {
    final rec = byName[name.trim().toLowerCase()];
    if (rec != null) {
      capacity += rec.fragmentCapacity;
      resolvedCount += 1;
    }
  }
  return FragmentCapacityResult(
    capacity: capacity,
    resolvedCount: resolvedCount,
  );
}

/// Load aspects from entity cache and run pure [evaluateSubclassKit].
Future<HardConstraintAdapterResult> evaluateSubclassKitFromEntityCache({
  required FileEntityCache cache,
  required List<String> aspectNames,
  required List<String> fragmentNames,
  int maxAspects = maxSubclassAspects,
}) async {
  final filteredAspects =
      aspectNames.where((a) => a.trim().isNotEmpty).toList();
  final filteredFragments =
      fragmentNames.where((f) => f.trim().isNotEmpty).toList();

  final resolved = await resolveFragmentCapacity(cache, filteredAspects);
  final capacityResolved = filteredAspects.isEmpty ||
      resolved.resolvedCount == filteredAspects.length;

  final evaluation = evaluateSubclassKit(
    SubclassKitEvalInput(
      aspectCount: filteredAspects.length,
      fragmentCount: filteredFragments.length,
      fragmentCapacity: resolved.capacity,
      maxAspects: maxAspects,
      capacityResolved: capacityResolved,
    ),
  );

  return HardConstraintAdapterResult(
    evaluation: evaluation,
    fragmentCapacity: resolved.capacity,
    aspectCount: filteredAspects.length,
  );
}

/// Load mods from entity cache and run pure [evaluateModEnergy] (+ slot legality).
Future<HardConstraintAdapterResult> evaluateModEnergyFromEntityCache({
  required FileEntityCache cache,
  required List<ModEnergyConfig> configs,
}) async {
  if (configs.isEmpty) {
    return const HardConstraintAdapterResult(
      evaluation: ConstraintEvaluation.empty,
    );
  }

  final mods = await cache.getStore<ModRecord>(MvpStoreName.mods);
  final byHash = {for (final m in mods) m.hash: m};

  final pieces = <ModEnergyPiece>[];
  final illegal = <String>[];

  for (final cfg in configs) {
    final costs = <int?>[];
    for (final hash in cfg.modHashes) {
      final mod = byHash[hash];
      if (mod == null) continue;
      if (!isModLegalForArmorSlot(cfg.slot, mod.slotCategory)) {
        illegal.add(
          '${cfg.slot}: mod "${mod.name}" is not legal for this piece (${mod.slotCategory.json})',
        );
      }
      costs.add(mod.energyCost);
    }
    pieces.add(
      ModEnergyPiece(
        slot: cfg.slot,
        energyUsed: sumEnergyCosts(costs),
        energyCapacity: armorEnergyCapacity(cfg.tier),
      ),
    );
  }

  if (illegal.isNotEmpty) {
    return HardConstraintAdapterResult(
      evaluation: ConstraintEvaluation(
        hardBlocks: [
          HardBlock(
            code: DomainFailureCodes.modEnergyExceeded,
            message: illegal.first,
          ),
        ],
      ),
      illegalModMessages: illegal,
    );
  }

  final evaluation = evaluateModEnergy(pieces);
  return HardConstraintAdapterResult(evaluation: evaluation);
}
