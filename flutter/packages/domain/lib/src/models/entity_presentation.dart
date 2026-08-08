/// Pure entity presentation model + resolve helpers (DART-071 / GAP-UI-DESC-01 Track A).
///
/// Hosts supply definition maps (name / icon / description / kind / meta). This
/// package never invents Destiny text and never uses a bare hash as the primary
/// label (DBR-UI-006).
///
/// ## Host map contract
///
/// Pass only values already known from entity stores / inventory enrichment:
///
/// | Map | Key | Value | When missing |
/// | --- | --- | ----- | ------------ |
/// | [EntityPresentationMaps.nameByHash] | definition hash | Readable display name | Primary becomes kind-specific "Unknown …"; hash only in [EntityPresentation.hashFooter] |
/// | [EntityPresentationMaps.iconByHash] | definition hash | Icon path or CDN relative path | [EntityPresentation.iconPath] is null |
/// | [EntityPresentationMaps.descriptionByHash] | definition hash | Definition / perk / intrinsic text | [EntityPresentation.description] is `''` (honest empty) |
/// | [EntityPresentationMaps.kindByHash] | definition hash | Kind label e.g. `Weapon perk` | [EntityPresentation.kind] is null |
/// | [EntityPresentationMaps.metaLinesByHash] | definition hash | Secondary lines (element, slot, …) | [EntityPresentation.metaLines] is empty |
///
/// Residual when maps omit a hash: empty description / null icon / unknown name
/// placeholder — never throw, never fabricate copy.

/// Kind used when choosing an "Unknown …" primary label (DBR-UI-006).
enum EntityLabelKind {
  item,
  plug,
  entity,
}

/// Primary label vs optional hash footer (DBR-UI-006 / DAC-DST-015).
class EntityLabelParts {
  const EntityLabelParts({
    required this.primary,
    this.footer,
    required this.unknown,
  });

  /// Headline / chip / row title — never a bare numeric hash.
  final String primary;

  /// Footer addendum e.g. `#1234567890`. Null when no usable hash.
  final String? footer;

  /// True when primary is a generic unknown placeholder (no real name).
  final bool unknown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityLabelParts &&
        other.primary == primary &&
        other.footer == footer &&
        other.unknown == unknown;
  }

  @override
  int get hashCode => Object.hash(primary, footer, unknown);

  @override
  String toString() =>
      'EntityLabelParts(primary: $primary, footer: $footer, unknown: $unknown)';
}

/// Resolved presentation for one Destiny entity (item, plug, ability, …).
///
/// Chrome (hotspot / popover) lives in UI packages; this type is host-neutral.
class EntityPresentation {
  const EntityPresentation({
    this.hash,
    required this.name,
    this.kind,
    this.iconPath,
    this.description = '',
    this.metaLines = const [],
    this.nameUnknown = false,
  });

  /// Definition / plug hash when known. Null only for name-only miss paths.
  final int? hash;

  /// Primary label — never a bare hash (DBR-UI-006).
  final String name;

  /// Optional kind label (e.g. `Weapon perk`, `Mod`) from host maps.
  final String? kind;

  /// Icon path when host supplied one; null when missing.
  final String? iconPath;

  /// Definition text when host supplied it; empty string when absent.
  ///
  /// Never invent description copy. UI must treat empty as "no description".
  final String description;

  /// Secondary meta lines supplied by host (element, slot, ammo, …).
  final List<String> metaLines;

  /// True when [name] is an unknown placeholder rather than a real display name.
  final bool nameUnknown;

  /// Whether a non-empty description was resolved.
  bool get hasDescription => description.trim().isNotEmpty;

  /// Hash footer for detail support/debug only — never use as primary label.
  String? get hashFooter => entityHashFooter(hash);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EntityPresentation) return false;
    if (other.hash != hash ||
        other.name != name ||
        other.kind != kind ||
        other.iconPath != iconPath ||
        other.description != description ||
        other.nameUnknown != nameUnknown) {
      return false;
    }
    if (other.metaLines.length != metaLines.length) return false;
    for (var i = 0; i < metaLines.length; i++) {
      if (other.metaLines[i] != metaLines[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        hash,
        name,
        kind,
        iconPath,
        description,
        nameUnknown,
        Object.hashAll(metaLines),
      );

  @override
  String toString() =>
      'EntityPresentation(hash: $hash, name: $name, kind: $kind, '
      'hasDescription: $hasDescription)';
}

/// Host-supplied lookup maps for [resolveEntityPresentation].
///
/// See library doc for the map contract. All maps are optional; missing keys
/// yield empty/null fields rather than errors.
class EntityPresentationMaps {
  const EntityPresentationMaps({
    this.nameByHash = const {},
    this.iconByHash = const {},
    this.descriptionByHash = const {},
    this.kindByHash = const {},
    this.metaLinesByHash = const {},
  });

  /// hash → display name (readable text only; bare digit strings treated as missing).
  final Map<int, String> nameByHash;

  /// hash → icon path.
  final Map<int, String> iconByHash;

  /// hash → definition / intrinsic / perk description text.
  final Map<int, String> descriptionByHash;

  /// hash → kind label for UI chrome (not inventing Destiny copy).
  final Map<int, String> kindByHash;

  /// hash → ordered secondary meta lines.
  final Map<int, List<String>> metaLinesByHash;

  /// Empty maps singleton convenience.
  static const empty = EntityPresentationMaps();
}

// ---------------------------------------------------------------------------
// Label helpers (DBR-UI-006)
// ---------------------------------------------------------------------------

const _unknownByKind = <EntityLabelKind, String>{
  EntityLabelKind.item: 'Unknown item',
  EntityLabelKind.plug: 'Unknown plug',
  EntityLabelKind.entity: 'Unknown',
};

/// True when [name] is null, blank, or only digits (bare hash string).
bool isBareHashLabel(String? name) {
  if (name == null) return true;
  final t = name.trim();
  if (t.isEmpty) return true;
  return RegExp(r'^\d+$').hasMatch(t);
}

/// Footer form for a hash. Never use as a primary label.
String? entityHashFooter(int? hash) {
  if (hash == null || hash <= 0) return null;
  return '#$hash';
}

/// Split display name + optional hash into primary label and hash footer.
///
/// If name is missing or is itself a bare hash, primary becomes a readable
/// unknown placeholder for [kind].
EntityLabelParts entityLabelParts({
  String? name,
  int? hash,
  EntityLabelKind kind = EntityLabelKind.entity,
}) {
  final raw = name?.trim() ?? '';
  final footer = entityHashFooter(hash);

  if (raw.isEmpty || isBareHashLabel(raw)) {
    final fromName = (isBareHashLabel(raw) && raw.isNotEmpty)
        ? entityHashFooter(int.tryParse(raw))
        : null;
    return EntityLabelParts(
      primary: _unknownByKind[kind]!,
      footer: footer ?? fromName,
      unknown: true,
    );
  }

  return EntityLabelParts(
    primary: raw,
    footer: footer,
    unknown: false,
  );
}

/// Convenience: primary label only (never bare hash).
String primaryEntityLabel(
  String? name, {
  int? hash,
  EntityLabelKind kind = EntityLabelKind.entity,
}) {
  return entityLabelParts(name: name, hash: hash, kind: kind).primary;
}

// ---------------------------------------------------------------------------
// Resolve
// ---------------------------------------------------------------------------

String _trimOrEmpty(String? value) {
  if (value == null) return '';
  return value.trim();
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}

List<String> _cleanMetaLines(Iterable<String>? lines) {
  if (lines == null) return const [];
  final out = <String>[];
  for (final line in lines) {
    final t = line.trim();
    if (t.isNotEmpty) out.add(t);
  }
  return out.isEmpty ? const [] : List<String>.unmodifiable(out);
}

/// Resolve presentation from explicit fields (e.g. a [CatalogItem]-shaped row).
///
/// Does not invent name/description/icon; bare-hash names become unknown
/// placeholders with hash retained for footer only.
EntityPresentation resolveEntityPresentationFields({
  int? hash,
  String? name,
  String? iconPath,
  String? description,
  String? kind,
  List<String> metaLines = const [],
  EntityLabelKind labelKind = EntityLabelKind.item,
}) {
  final labels = entityLabelParts(name: name, hash: hash, kind: labelKind);
  return EntityPresentation(
    hash: hash,
    name: labels.primary,
    kind: _trimOrNull(kind),
    iconPath: _trimOrNull(iconPath),
    description: _trimOrEmpty(description),
    metaLines: _cleanMetaLines(metaLines),
    nameUnknown: labels.unknown,
  );
}

/// Resolve presentation for [hash] from host-supplied [maps].
///
/// Missing map entries yield empty description / null icon / unknown name —
/// never throws and never invents Destiny text.
EntityPresentation resolveEntityPresentation(
  int hash, {
  EntityPresentationMaps maps = EntityPresentationMaps.empty,
  EntityLabelKind labelKind = EntityLabelKind.item,
}) {
  return resolveEntityPresentationFields(
    hash: hash,
    name: maps.nameByHash[hash],
    iconPath: maps.iconByHash[hash],
    description: maps.descriptionByHash[hash],
    kind: maps.kindByHash[hash],
    metaLines: maps.metaLinesByHash[hash] ?? const [],
    labelKind: labelKind,
  );
}

/// Batch resolve hashes against the same [maps].
///
/// Returns a map for every input hash (including misses with empty fields).
Map<int, EntityPresentation> resolveEntityPresentations(
  Iterable<int> hashes, {
  EntityPresentationMaps maps = EntityPresentationMaps.empty,
  EntityLabelKind labelKind = EntityLabelKind.item,
}) {
  final out = <int, EntityPresentation>{};
  for (final h in hashes) {
    out.putIfAbsent(
      h,
      () => resolveEntityPresentation(h, maps: maps, labelKind: labelKind),
    );
  }
  return out;
}
