import 'dart:isolate';

import 'package:destiny2_domain/destiny2_domain.dart';

/// Run pure optimize on the **current** isolate (tests / tooling).
ArmorOptimizeResponse optimizeArmorLocal(ArmorOptimizeRequest request) {
  return optimizeArmorCore(request);
}

/// Run pure optimize **off the UI isolate** via [Isolate.run].
///
/// Transfer uses map serialization so messages stay sendable. Domain stays
/// free of Flutter; hosts await this from the UI isolate safely (DART-035).
Future<ArmorOptimizeResponse> optimizeArmorInIsolate(
  ArmorOptimizeRequest request,
) {
  final payload = encodeArmorOptimizeRequest(request);
  return Isolate.run(() {
    final decoded = decodeArmorOptimizeRequest(payload);
    final response = optimizeArmorCore(decoded);
    return encodeArmorOptimizeResponse(response);
  }).then(decodeArmorOptimizeResponse);
}

// --- Transfer maps (primitives / nested maps only) ---

Map<String, Object?> encodeArmorOptimizeRequest(ArmorOptimizeRequest r) {
  return {
    'candidates': r.candidates.map(_encodeCandidate).toList(),
    'constraints': _encodeConstraints(r.constraints),
    'statPriorities': r.statPriorities.map((s) => s.wireName).toList(),
    'statThresholds': r.statThresholds == null
        ? null
        : {
            for (final e in r.statThresholds!.entries) e.key.wireName: e.value,
          },
    'requireThresholds': r.requireThresholds,
    'preferReuse': r.preferReuse,
    'maxResults': r.maxResults,
    'maxCombinations': r.maxCombinations,
    'classType': r.classType,
    'hasInventory': r.hasInventory,
  };
}

ArmorOptimizeRequest decodeArmorOptimizeRequest(Map<String, Object?> m) {
  final thresholdsRaw = m['statThresholds'];
  Map<ArmorStatName, int>? thresholds;
  if (thresholdsRaw is Map) {
    thresholds = {};
    for (final e in thresholdsRaw.entries) {
      final name = ArmorStatName.tryParse(e.key.toString());
      if (name != null && e.value is int) thresholds[name] = e.value as int;
    }
  }

  final priorities = <ArmorStatName>[];
  final priRaw = m['statPriorities'];
  if (priRaw is List) {
    for (final p in priRaw) {
      final name = ArmorStatName.tryParse(p.toString());
      if (name != null) priorities.add(name);
    }
  }

  final candRaw = m['candidates'];
  final candidates = <CandidatePiece>[];
  if (candRaw is List) {
    for (final c in candRaw) {
      if (c is Map) {
        candidates.add(_decodeCandidate(Map<String, Object?>.from(c)));
      }
    }
  }

  final consRaw = m['constraints'];
  final constraints = consRaw is Map
      ? _decodeConstraints(Map<String, Object?>.from(consRaw))
      : const KitConstraints();

  return ArmorOptimizeRequest(
    candidates: candidates,
    constraints: constraints,
    statPriorities: priorities,
    statThresholds: thresholds,
    requireThresholds: m['requireThresholds'] == true,
    preferReuse: m['preferReuse'] == true,
    maxResults: (m['maxResults'] as int?) ?? 25,
    maxCombinations: m['maxCombinations'] as int?,
    classType: m['classType'] as String?,
    hasInventory: m['hasInventory'] != false,
  );
}

Map<String, Object?> encodeArmorOptimizeResponse(ArmorOptimizeResponse r) {
  return {
    'combinations': r.combinations.map(_encodeCombination).toList(),
    'truncated': r.truncated,
    'evaluatedCount': r.evaluatedCount,
    'emptyReason': r.emptyReason == null
        ? null
        : {
            'code': r.emptyReason!.code.wireName,
            'message': r.emptyReason!.message,
            'details': r.emptyReason!.details,
          },
    'seed': r.seed == null
        ? null
        : {
            'classType': r.seed!.classType,
            'lockedExoticItemHash': r.seed!.lockedExoticItemHash,
            'statThresholds': r.seed!.statThresholds == null
                ? null
                : {
                    for (final e in r.seed!.statThresholds!.entries)
                      e.key.wireName: e.value,
                  },
            'statPriorities':
                r.seed!.statPriorities?.map((s) => s.wireName).toList(),
            'preferReuse': r.seed!.preferReuse,
          },
  };
}

ArmorOptimizeResponse decodeArmorOptimizeResponse(Map<String, Object?> m) {
  final combos = <ArmorCombination>[];
  final rawCombos = m['combinations'];
  if (rawCombos is List) {
    for (final c in rawCombos) {
      if (c is Map) {
        combos.add(_decodeCombination(Map<String, Object?>.from(c)));
      }
    }
  }

  ArmorOptimizeEmptyReason? empty;
  final er = m['emptyReason'];
  if (er is Map) {
    final codeWire = er['code']?.toString() ?? '';
    final code = ArmorOptimizeEmptyReasonCode.values.firstWhere(
      (c) => c.wireName == codeWire,
      orElse: () => ArmorOptimizeEmptyReasonCode.noValidKits,
    );
    empty = ArmorOptimizeEmptyReason(
      code: code,
      message: er['message']?.toString() ?? '',
      details: er['details'] is Map
          ? Map<String, Object?>.from(er['details'] as Map)
          : const {},
    );
  }

  ArmorOptimizeSeed? seed;
  final sd = m['seed'];
  if (sd is Map) {
    Map<ArmorStatName, int>? th;
    final thr = sd['statThresholds'];
    if (thr is Map) {
      th = {};
      for (final e in thr.entries) {
        final name = ArmorStatName.tryParse(e.key.toString());
        if (name != null && e.value is int) th[name] = e.value as int;
      }
    }
    List<ArmorStatName>? pri;
    final pr = sd['statPriorities'];
    if (pr is List) {
      pri = [
        for (final p in pr)
          if (ArmorStatName.tryParse(p.toString()) != null)
            ArmorStatName.tryParse(p.toString())!,
      ];
    }
    seed = ArmorOptimizeSeed(
      classType: sd['classType'] as String?,
      lockedExoticItemHash: sd['lockedExoticItemHash'] as int?,
      statThresholds: th,
      statPriorities: pri,
      preferReuse: sd['preferReuse'] as bool?,
    );
  }

  return ArmorOptimizeResponse(
    combinations: combos,
    truncated: m['truncated'] == true,
    evaluatedCount: (m['evaluatedCount'] as int?) ?? 0,
    emptyReason: empty,
    seed: seed,
  );
}

Map<String, Object?> _encodeCandidate(CandidatePiece p) {
  return {
    'slot': p.slot.wireName,
    'itemHash': p.itemHash,
    'instanceId': p.instanceId,
    'itemName': p.itemName,
    'isExotic': p.isExotic,
    'setBonusKey': p.setBonusKey,
    'statValues': {
      for (final e in p.statValues.entries) e.key.wireName: e.value,
    },
    'energyCapacity': p.energyCapacity,
    'usedInSets': p.usedInSets
        .map((s) => {'id': s.id, 'name': s.name})
        .toList(),
  };
}

CandidatePiece _decodeCandidate(Map<String, Object?> m) {
  final slot = EquipmentSlot.tryParse(m['slot']?.toString() ?? '') ??
      EquipmentSlot.helmet;
  final stats = <ArmorStatName, int>{};
  final sv = m['statValues'];
  if (sv is Map) {
    for (final e in sv.entries) {
      final name = ArmorStatName.tryParse(e.key.toString());
      if (name != null && e.value is int) stats[name] = e.value as int;
    }
  }
  final used = <ReuseSetRef>[];
  final u = m['usedInSets'];
  if (u is List) {
    for (final s in u) {
      if (s is Map) {
        used.add(
          ReuseSetRef(
            id: s['id']?.toString() ?? '',
            name: s['name']?.toString() ?? '',
          ),
        );
      }
    }
  }
  return CandidatePiece(
    slot: slot,
    itemHash: (m['itemHash'] as int?) ?? 0,
    instanceId: m['instanceId']?.toString() ?? '',
    itemName: m['itemName'] as String?,
    isExotic: m['isExotic'] == true,
    setBonusKey: m['setBonusKey'] as String?,
    statValues: stats,
    energyCapacity: (m['energyCapacity'] as int?) ?? 10,
    usedInSets: used,
  );
}

Map<String, Object?> _encodeConstraints(KitConstraints c) {
  return {
    'lockedExoticItemHash': c.lockedExoticItemHash,
    'requireExotic': c.requireExotic,
    'setBonusGoals': c.setBonusGoals
        ?.map(
          (g) => {
            'setBonusKey': g.setBonusKey,
            'minPieces': g.minPieces,
          },
        )
        .toList(),
  };
}

KitConstraints _decodeConstraints(Map<String, Object?> m) {
  List<SetBonusCoverageGoal>? goals;
  final g = m['setBonusGoals'];
  if (g is List) {
    goals = [];
    for (final item in g) {
      if (item is Map) {
        goals.add(
          SetBonusCoverageGoal(
            setBonusKey: item['setBonusKey']?.toString() ?? '',
            minPieces: (item['minPieces'] as int?) ?? 2,
          ),
        );
      }
    }
  }
  return KitConstraints(
    lockedExoticItemHash: m['lockedExoticItemHash'] as int?,
    requireExotic: m['requireExotic'] as bool?,
    setBonusGoals: goals,
  );
}

Map<String, Object?> _encodeCombination(ArmorCombination c) {
  return {
    'pieces': c.pieces
        .map(
          (p) => {
            'slot': p.slot.wireName,
            'itemHash': p.itemHash,
            'instanceId': p.instanceId,
            'itemName': p.itemName,
            'isExotic': p.isExotic,
            'setBonusKey': p.setBonusKey,
            'statValues': {
              for (final e in p.statValues.entries) e.key.wireName: e.value,
            },
            'usedInOtherSets': p.usedInOtherSets
                .map((s) => {'id': s.id, 'name': s.name})
                .toList(),
          },
        )
        .toList(),
    'estimatedStats': {
      for (final e in c.estimatedStats.entries) e.key.wireName: e.value,
    },
    'incompleteEstimate': c.incompleteEstimate,
    'setBonusSummary': c.setBonusSummary
        .map(
          (s) => {
            'setBonusKey': s.setBonusKey,
            'pieceCount': s.pieceCount,
            'active2pc': s.active2pc,
            'active4pc': s.active4pc,
          },
        )
        .toList(),
    'assumedMods': const <Object?>[],
    'reusePieceCount': c.reusePieceCount,
    'score': c.score,
    'meetsSoftThresholds': c.meetsSoftThresholds,
  };
}

ArmorCombination _decodeCombination(Map<String, Object?> m) {
  final pieces = <ArmorOptimizePiece>[];
  final pr = m['pieces'];
  if (pr is List) {
    for (final p in pr) {
      if (p is! Map) continue;
      final pm = Map<String, Object?>.from(p);
      final stats = <ArmorStatName, int>{};
      final sv = pm['statValues'];
      if (sv is Map) {
        for (final e in sv.entries) {
          final name = ArmorStatName.tryParse(e.key.toString());
          if (name != null && e.value is int) stats[name] = e.value as int;
        }
      }
      final used = <ReuseSetRef>[];
      final u = pm['usedInOtherSets'];
      if (u is List) {
        for (final s in u) {
          if (s is Map) {
            used.add(
              ReuseSetRef(
                id: s['id']?.toString() ?? '',
                name: s['name']?.toString() ?? '',
              ),
            );
          }
        }
      }
      pieces.add(
        ArmorOptimizePiece(
          slot: EquipmentSlot.tryParse(pm['slot']?.toString() ?? '') ??
              EquipmentSlot.helmet,
          itemHash: (pm['itemHash'] as int?) ?? 0,
          instanceId: pm['instanceId']?.toString() ?? '',
          itemName: pm['itemName'] as String?,
          isExotic: pm['isExotic'] == true,
          setBonusKey: pm['setBonusKey'] as String?,
          statValues: stats,
          usedInOtherSets: used,
        ),
      );
    }
  }

  final est = <ArmorStatName, int>{};
  final es = m['estimatedStats'];
  if (es is Map) {
    for (final e in es.entries) {
      final name = ArmorStatName.tryParse(e.key.toString());
      if (name != null && e.value is int) est[name] = e.value as int;
    }
  }

  final summary = <SetBonusSummaryEntry>[];
  final ss = m['setBonusSummary'];
  if (ss is List) {
    for (final s in ss) {
      if (s is Map) {
        summary.add(
          SetBonusSummaryEntry(
            setBonusKey: s['setBonusKey']?.toString() ?? '',
            pieceCount: (s['pieceCount'] as int?) ?? 0,
            active2pc: s['active2pc'] == true,
            active4pc: s['active4pc'] == true,
          ),
        );
      }
    }
  }

  return ArmorCombination(
    pieces: pieces,
    estimatedStats: est,
    incompleteEstimate: m['incompleteEstimate'] == true,
    setBonusSummary: summary,
    assumedMods: const [],
    reusePieceCount: (m['reusePieceCount'] as int?) ?? 0,
    score: (m['score'] as int?) ?? 0,
    meetsSoftThresholds: m['meetsSoftThresholds'] == true,
  );
}
