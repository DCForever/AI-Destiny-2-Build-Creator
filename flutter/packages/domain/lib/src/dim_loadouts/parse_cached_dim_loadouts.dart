import 'dart:convert';

import 'cached_dim_loadout.dart';

/// Supported compiled DIM loadouts schema.
const int kCachedDimLoadoutsSchemaVersion = 1;

/// Soft upper bound for pure parse of UTF-8 JSON text (50 MiB).
///
/// Storage readers should enforce the same cap on file length before reading.
const int kCachedDimLoadoutsMaxBytes = 50 * 1024 * 1024;

/// Fail-closed parse outcome for the compiled DIM loadouts catalog.
///
/// On any failure [catalog] is null and [loadouts] is empty — never a partial
/// list after corrupt / wrong-version / oversized input.
class CachedDimLoadoutsParseResult {
  CachedDimLoadoutsParseResult._({
    this.catalog,
    required this.status,
    this.detail,
  });

  factory CachedDimLoadoutsParseResult.ok(CachedDimLoadoutCatalog catalog) {
    return CachedDimLoadoutsParseResult._(
      catalog: catalog,
      status: CachedDimLoadoutsParseStatus.ok,
    );
  }

  factory CachedDimLoadoutsParseResult.unreadable(String detail) {
    return CachedDimLoadoutsParseResult._(
      status: CachedDimLoadoutsParseStatus.unreadable,
      detail: detail,
    );
  }

  final CachedDimLoadoutCatalog? catalog;
  final CachedDimLoadoutsParseStatus status;
  final String? detail;

  bool get isOk =>
      status == CachedDimLoadoutsParseStatus.ok && catalog != null;

  /// Empty on failure (fail closed).
  List<CachedDimLoadout> get loadouts =>
      catalog?.loadouts ?? const <CachedDimLoadout>[];
}

enum CachedDimLoadoutsParseStatus { ok, unreadable }

/// Parse compiled DIM loadouts JSON [text] into a catalog.
///
/// Pure: no filesystem or network. Fail closed on wrong [schemaVersion],
/// truncated JSON, oversized payload, or missing required fields.
CachedDimLoadoutsParseResult parseCachedDimLoadouts(
  String text, {
  int maxBytes = kCachedDimLoadoutsMaxBytes,
}) {
  if (maxBytes < 1) {
    return CachedDimLoadoutsParseResult.unreadable('invalid size cap');
  }
  final byteLength = utf8.encode(text).length;
  if (byteLength > maxBytes) {
    return CachedDimLoadoutsParseResult.unreadable(
      'file exceeds size limit ($byteLength > $maxBytes bytes)',
    );
  }
  if (text.trim().isEmpty) {
    return CachedDimLoadoutsParseResult.unreadable('file is empty');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    return CachedDimLoadoutsParseResult.unreadable(
      'invalid JSON (${e.message})',
    );
  }

  if (decoded is! Map) {
    return CachedDimLoadoutsParseResult.unreadable(
      'root must be a JSON object',
    );
  }
  final root = Map<String, Object?>.from(decoded);

  final version = root['schemaVersion'];
  if (version is! int) {
    return CachedDimLoadoutsParseResult.unreadable(
      'schemaVersion must be an integer',
    );
  }
  if (version != kCachedDimLoadoutsSchemaVersion) {
    return CachedDimLoadoutsParseResult.unreadable(
      'unsupported schemaVersion $version '
      '(expected $kCachedDimLoadoutsSchemaVersion)',
    );
  }

  final generatedAtPt = _requireString(root, 'generatedAtPt');
  if (generatedAtPt == null) {
    return CachedDimLoadoutsParseResult.unreadable(
      'generatedAtPt must be a string',
    );
  }
  final manifestVersion = _requireString(root, 'manifestVersion');
  if (manifestVersion == null) {
    return CachedDimLoadoutsParseResult.unreadable(
      'manifestVersion must be a string',
    );
  }

  final rawLoadouts = root['loadouts'];
  if (rawLoadouts is! List) {
    return CachedDimLoadoutsParseResult.unreadable(
      'loadouts must be an array',
    );
  }

  final loadouts = <CachedDimLoadout>[];
  final seenShareIds = <String>{};
  for (var i = 0; i < rawLoadouts.length; i++) {
    final row = rawLoadouts[i];
    if (row is! Map) {
      return CachedDimLoadoutsParseResult.unreadable(
        'loadouts[$i] must be an object',
      );
    }
    final parsed = _parseLoadout(Map<String, Object?>.from(row), i);
    if (parsed.error != null) {
      return CachedDimLoadoutsParseResult.unreadable(parsed.error!);
    }
    final loadout = parsed.loadout!;
    if (!seenShareIds.add(loadout.shareId)) {
      return CachedDimLoadoutsParseResult.unreadable(
        'duplicate shareId "${loadout.shareId}"',
      );
    }
    loadouts.add(loadout);
  }

  return CachedDimLoadoutsParseResult.ok(
    CachedDimLoadoutCatalog(
      schemaVersion: version,
      generatedAtPt: generatedAtPt,
      manifestVersion: manifestVersion,
      loadouts: List<CachedDimLoadout>.unmodifiable(loadouts),
    ),
  );
}

class _LoadoutParse {
  const _LoadoutParse({this.loadout, this.error});
  final CachedDimLoadout? loadout;
  final String? error;
}

_LoadoutParse _parseLoadout(Map<String, Object?> map, int index) {
  final shareId = _requireString(map, 'shareId');
  if (shareId == null || shareId.isEmpty) {
    return _LoadoutParse(error: 'loadouts[$index].shareId must be a string');
  }
  final name = _requireString(map, 'name');
  if (name == null) {
    return _LoadoutParse(error: 'loadouts[$index].name must be a string');
  }
  final classType = map['classType'];
  if (classType is! int) {
    return _LoadoutParse(
      error: 'loadouts[$index].classType must be an integer',
    );
  }

  final subclass = _parseSubclass(map['subclass'], index);
  if (subclass.error != null) {
    return _LoadoutParse(error: subclass.error);
  }
  final exotic = _parseExotic(map['exotic'], index);
  if (exotic.error != null) {
    return _LoadoutParse(error: exotic.error);
  }

  final items = _parseItems(map['items'], index);
  if (items.error != null) return _LoadoutParse(error: items.error);
  final plugs = _parseNamedList(map['subclassPlugs'], 'subclassPlugs', index);
  if (plugs.error != null) return _LoadoutParse(error: plugs.error);
  final mods = _parseNamedList(map['mods'], 'mods', index);
  if (mods.error != null) return _LoadoutParse(error: mods.error);
  final perks = _parseNamedList(map['artifactPerks'], 'artifactPerks', index);
  if (perks.error != null) return _LoadoutParse(error: perks.error);

  final season = map['artifactSeason'];
  if (season != null && season is! int) {
    return _LoadoutParse(
      error: 'loadouts[$index].artifactSeason must be int or null',
    );
  }

  final constraints = _parseConstraints(map['statConstraints'], index);
  if (constraints.error != null) {
    return _LoadoutParse(error: constraints.error);
  }

  final notes = map['notes'];
  if (notes != null && notes is! String) {
    return _LoadoutParse(
      error: 'loadouts[$index].notes must be string or null',
    );
  }

  return _LoadoutParse(
    loadout: CachedDimLoadout(
      shareId: shareId,
      name: name,
      classType: classType,
      subclass: subclass.value,
      exotic: exotic.value,
      items: items.values!,
      subclassPlugs: plugs.values!,
      mods: mods.values!,
      artifactSeason: season as int?,
      artifactPerks: perks.values!,
      statConstraints: constraints.values,
      notes: notes as String?,
    ),
  );
}

class _OptSubclass {
  const _OptSubclass({this.value, this.error});
  final CachedDimSubclass? value;
  final String? error;
}

_OptSubclass _parseSubclass(Object? raw, int index) {
  if (raw == null) return const _OptSubclass();
  if (raw is! Map) {
    return _OptSubclass(
      error: 'loadouts[$index].subclass must be object or null',
    );
  }
  final map = Map<String, Object?>.from(raw);
  final hash = map['hash'];
  final name = map['name'];
  if (hash is! int || name is! String) {
    return _OptSubclass(
      error: 'loadouts[$index].subclass needs hash:int and name:string',
    );
  }
  return _OptSubclass(value: CachedDimSubclass(hash: hash, name: name));
}

class _OptExotic {
  const _OptExotic({this.value, this.error});
  final CachedDimExotic? value;
  final String? error;
}

_OptExotic _parseExotic(Object? raw, int index) {
  if (raw == null) return const _OptExotic();
  if (raw is! Map) {
    return _OptExotic(
      error: 'loadouts[$index].exotic must be object or null',
    );
  }
  final map = Map<String, Object?>.from(raw);
  final hash = map['hash'];
  final name = map['name'];
  final description = map['description'];
  if (hash is! int || name is! String || description is! String) {
    return _OptExotic(
      error:
          'loadouts[$index].exotic needs hash:int, name:string, description:string',
    );
  }
  return _OptExotic(
    value: CachedDimExotic(hash: hash, name: name, description: description),
  );
}

class _ListParse<T> {
  const _ListParse({this.values, this.error});
  final List<T>? values;
  final String? error;
}

_ListParse<CachedDimItem> _parseItems(Object? raw, int index) {
  if (raw is! List) {
    return _ListParse(error: 'loadouts[$index].items must be an array');
  }
  final out = <CachedDimItem>[];
  for (var i = 0; i < raw.length; i++) {
    final row = raw[i];
    if (row is! Map) {
      return _ListParse(
        error: 'loadouts[$index].items[$i] must be an object',
      );
    }
    final map = Map<String, Object?>.from(row);
    final hash = map['hash'];
    final name = map['name'];
    final itemType = map['itemType'];
    final tier = map['tier'];
    if (hash is! int ||
        name is! String ||
        itemType is! String ||
        tier is! String) {
      return _ListParse(
        error: 'loadouts[$index].items[$i] has invalid fields',
      );
    }
    out.add(
      CachedDimItem(
        hash: hash,
        name: name,
        itemType: itemType,
        tier: tier,
      ),
    );
  }
  return _ListParse(values: List<CachedDimItem>.unmodifiable(out));
}

_ListParse<CachedDimNamedHash> _parseNamedList(
  Object? raw,
  String field,
  int index,
) {
  if (raw is! List) {
    return _ListParse(error: 'loadouts[$index].$field must be an array');
  }
  final out = <CachedDimNamedHash>[];
  for (var i = 0; i < raw.length; i++) {
    final row = raw[i];
    if (row is! Map) {
      return _ListParse(
        error: 'loadouts[$index].$field[$i] must be an object',
      );
    }
    final map = Map<String, Object?>.from(row);
    final hash = map['hash'];
    final name = map['name'];
    final description = map['description'];
    if (hash is! int || name is! String) {
      return _ListParse(
        error: 'loadouts[$index].$field[$i] needs hash:int and name:string',
      );
    }
    if (description != null && description is! String) {
      return _ListParse(
        error: 'loadouts[$index].$field[$i].description must be string',
      );
    }
    out.add(
      CachedDimNamedHash(
        hash: hash,
        name: name,
        description: description is String ? description : '',
      ),
    );
  }
  return _ListParse(values: List<CachedDimNamedHash>.unmodifiable(out));
}

class _ConstraintsParse {
  const _ConstraintsParse({this.values, this.error});
  final List<CachedDimStatConstraint>? values;
  final String? error;
}

_ConstraintsParse _parseConstraints(Object? raw, int index) {
  if (raw == null) return const _ConstraintsParse();
  if (raw is! List) {
    return _ConstraintsParse(
      error: 'loadouts[$index].statConstraints must be array or null',
    );
  }
  final out = <CachedDimStatConstraint>[];
  for (var i = 0; i < raw.length; i++) {
    final row = raw[i];
    if (row is! Map) {
      return _ConstraintsParse(
        error: 'loadouts[$index].statConstraints[$i] must be an object',
      );
    }
    final map = Map<String, Object?>.from(row);
    final hash = map['statHash'];
    final name = map['name'];
    if (hash is! int || name is! String) {
      return _ConstraintsParse(
        error:
            'loadouts[$index].statConstraints[$i] needs statHash:int and name:string',
      );
    }
    final minTier = _optIntField(map['minTier'], 'minTier', index, i);
    if (minTier.error != null) {
      return _ConstraintsParse(error: minTier.error);
    }
    final maxTier = _optIntField(map['maxTier'], 'maxTier', index, i);
    if (maxTier.error != null) {
      return _ConstraintsParse(error: maxTier.error);
    }
    final minStat = _optIntField(map['minStat'], 'minStat', index, i);
    if (minStat.error != null) {
      return _ConstraintsParse(error: minStat.error);
    }
    final maxStat = _optIntField(map['maxStat'], 'maxStat', index, i);
    if (maxStat.error != null) {
      return _ConstraintsParse(error: maxStat.error);
    }
    out.add(
      CachedDimStatConstraint(
        statHash: hash,
        name: name,
        minTier: minTier.value,
        maxTier: maxTier.value,
        minStat: minStat.value,
        maxStat: maxStat.value,
      ),
    );
  }
  return _ConstraintsParse(
    values: List<CachedDimStatConstraint>.unmodifiable(out),
  );
}

class _OptInt {
  const _OptInt({this.value, this.error});
  final int? value;
  final String? error;
}

_OptInt _optIntField(
  Object? value,
  String field,
  int loadoutIndex,
  int rowIndex,
) {
  if (value == null) return const _OptInt();
  if (value is int) return _OptInt(value: value);
  return _OptInt(
    error:
        'loadouts[$loadoutIndex].statConstraints[$rowIndex].$field must be int or null',
  );
}

String? _requireString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) return null;
  return value;
}
