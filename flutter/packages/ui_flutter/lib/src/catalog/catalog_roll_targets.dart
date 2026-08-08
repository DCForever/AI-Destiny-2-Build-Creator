import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

// ---------------------------------------------------------------------------
// Presentation models (host maps domain; ui_flutter stays free of domain deps)
// ---------------------------------------------------------------------------

/// Named roll-target profile for the switcher (no bare hash/id primary label).
class CatalogRollTargetOption {
  const CatalogRollTargetOption({
    required this.id,
    required this.name,
  });

  final String id;

  /// User-facing name (e.g. "PvE", "PvP") — never a raw hash as primary.
  final String name;
}

/// Soft dual score for one owned instance (maps domain [RollTargetMatchResult]).
class CatalogInstanceRollScore {
  const CatalogInstanceRollScore({
    required this.preferredMatched,
    required this.preferredScored,
    required this.avoidHits,
    required this.avoidScored,
    this.allPreferredColumnsMatched,
  });

  final int preferredMatched;
  final int preferredScored;
  final int avoidHits;
  final int avoidScored;

  /// Host sets from domain column-level perfect (all preferred sockets hit).
  /// When null, falls back to N==M (widget-only fixtures without column state).
  final bool? allPreferredColumnsMatched;

  double get preferredRatio =>
      preferredScored == 0 ? 0.0 : preferredMatched / preferredScored;

  /// Green dual-seg tint: preferred columns all matched when host provided;
  /// else N==M for pure presentation fixtures.
  bool get isPerfectPreferred =>
      allPreferredColumnsMatched ??
      (preferredScored > 0 && preferredMatched == preferredScored);

  bool get isCleanAvoid => avoidHits == 0;

  bool get hasAnyScoreDimension => preferredScored > 0 || avoidScored > 0;

  /// Chip preferred segment text `N/M`.
  String get preferredSegLabel => '$preferredMatched/$preferredScored';

  /// Chip avoid segment text `Av k`.
  String get avoidSegLabel => 'Av $avoidHits';

  /// A11y: "N of M preferred, k avoid hits".
  String get semanticsScoreLabel {
    final parts = <String>[];
    if (preferredScored > 0) {
      parts.add(
        '$preferredMatched of $preferredScored preferred',
      );
    }
    if (avoidScored > 0) {
      parts.add(
        avoidHits == 1 ? '1 avoid hit' : '$avoidHits avoid hits',
      );
    }
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogInstanceRollScore &&
        other.preferredMatched == preferredMatched &&
        other.preferredScored == preferredScored &&
        other.avoidHits == avoidHits &&
        other.avoidScored == avoidScored &&
        other.allPreferredColumnsMatched == allPreferredColumnsMatched;
  }

  @override
  int get hashCode => Object.hash(
        preferredMatched,
        preferredScored,
        avoidHits,
        avoidScored,
        allPreferredColumnsMatched,
      );
}

/// Tri-state plug mode in the roll-target editor (Want | Avoid | Off).
enum CatalogRollPlugTargetMode {
  off,
  want,
  avoid,
}

/// Cycle Want → Avoid → Off → Want (editor multi-pick).
CatalogRollPlugTargetMode nextCatalogRollPlugMode(
  CatalogRollPlugTargetMode current,
) {
  switch (current) {
    case CatalogRollPlugTargetMode.off:
      return CatalogRollPlugTargetMode.want;
    case CatalogRollPlugTargetMode.want:
      return CatalogRollPlugTargetMode.avoid;
    case CatalogRollPlugTargetMode.avoid:
      return CatalogRollPlugTargetMode.off;
  }
}

/// Resolve mode for a plug in a column draft.
CatalogRollPlugTargetMode catalogRollPlugModeFor({
  required String columnKey,
  required int plugHash,
  required Map<String, Set<int>> preferredByColumn,
  required Map<String, Set<int>> avoidByColumn,
}) {
  final pref = preferredByColumn[columnKey] ?? const <int>{};
  final avoid = avoidByColumn[columnKey] ?? const <int>{};
  if (pref.contains(plugHash)) return CatalogRollPlugTargetMode.want;
  if (avoid.contains(plugHash)) return CatalogRollPlugTargetMode.avoid;
  return CatalogRollPlugTargetMode.off;
}

/// Apply a mode to draft maps (mutates copies; returns new maps).
({
  Map<String, Set<int>> preferredByColumn,
  Map<String, Set<int>> avoidByColumn,
}) applyCatalogRollPlugMode({
  required String columnKey,
  required int plugHash,
  required CatalogRollPlugTargetMode mode,
  required Map<String, Set<int>> preferredByColumn,
  required Map<String, Set<int>> avoidByColumn,
}) {
  final pref = {
    for (final e in preferredByColumn.entries)
      e.key: Set<int>.from(e.value),
  };
  final avoid = {
    for (final e in avoidByColumn.entries) e.key: Set<int>.from(e.value),
  };
  pref.putIfAbsent(columnKey, () => <int>{});
  avoid.putIfAbsent(columnKey, () => <int>{});
  pref[columnKey]!.remove(plugHash);
  avoid[columnKey]!.remove(plugHash);
  switch (mode) {
    case CatalogRollPlugTargetMode.want:
      pref[columnKey]!.add(plugHash);
      break;
    case CatalogRollPlugTargetMode.avoid:
      avoid[columnKey]!.add(plugHash);
      break;
    case CatalogRollPlugTargetMode.off:
      break;
  }
  // Drop empty columns for cleaner equality / persist.
  pref.removeWhere((_, v) => v.isEmpty);
  avoid.removeWhere((_, v) => v.isEmpty);
  return (preferredByColumn: pref, avoidByColumn: avoid);
}

/// True when any column has preferred ∩ avoid non-empty (DBR-IDL-004 soft).
bool catalogRollTargetHasOverlap({
  required Map<String, Set<int>> preferredByColumn,
  required Map<String, Set<int>> avoidByColumn,
}) {
  final keys = {...preferredByColumn.keys, ...avoidByColumn.keys};
  for (final k in keys) {
    final p = preferredByColumn[k] ?? const <int>{};
    final a = avoidByColumn[k] ?? const <int>{};
    if (p.intersection(a).isNotEmpty) return true;
  }
  return false;
}

/// Stable **socket** key for roll targets — shared by editor + score.
///
/// **SSoT:** Bungie `socketIndex` on the weapon item definition / instance
/// capture → `socket_{n}`. Plug picks themselves are always **manifest item
/// hashes** (`equippedPlugHash` / preferred / avoid sets).
///
/// Labels (`columnLabel`) are display-only and must not be used as keys.
/// Fallback `kind_{index}` / `col_{index}` only when socketIndex is missing
/// (incomplete capture); production inventory should always write socketIndex
/// via [buildStoredSocketPlugs].
String catalogRollColumnKey(
  Map<String, Object?> raw, {
  int index = 0,
}) {
  final socket = raw['socketIndex'];
  if (socket is int) return 'socket_$socket';
  if (socket is num) return 'socket_${socket.toInt()}';
  if (socket != null) {
    final parsed = int.tryParse('$socket');
    if (parsed != null) return 'socket_$parsed';
  }
  // Incomplete capture — keep unique, never bare label (collides Trait/Trait).
  final kind = (raw['columnKind'] as String?)?.trim();
  if (kind != null && kind.isNotEmpty) return '${kind}_$index';
  return 'col_$index';
}

int? _parsePlugHash(Object? raw) {
  if (raw is int) return raw == 0 ? null : raw;
  if (raw is num) {
    final v = raw.toInt();
    return v == 0 ? null : v;
  }
  final h = int.tryParse('$raw');
  if (h == null || h == 0) return null;
  return h;
}

/// Equipped-only plug map: columnKey → equipped hash.
Map<String, int> catalogRollPlugsByColumnFromSockets(
  List<Map<String, Object?>>? sockets,
) {
  final out = <String, int>{};
  if (sockets == null) return out;
  for (var i = 0; i < sockets.length; i++) {
    final raw = sockets[i];
    final key = catalogRollColumnKey(raw, index: i);
    final h = _parsePlugHash(raw['equippedPlugHash']);
    if (h != null) out[key] = h;
  }
  return out;
}

/// All plugs on the instance per column (equipped + reusables) for plug-level
/// preferred/avoid scoring — "on this copy" counts, not equipped-only.
Map<String, Set<int>> catalogRollAllPlugsByColumnFromSockets(
  List<Map<String, Object?>>? sockets,
) {
  final out = <String, Set<int>>{};
  if (sockets == null) return out;
  for (var i = 0; i < sockets.length; i++) {
    final raw = sockets[i];
    final key = catalogRollColumnKey(raw, index: i);
    final plugs = <int>{};
    final equipped = _parsePlugHash(raw['equippedPlugHash']);
    if (equipped != null) plugs.add(equipped);
    final reusable = raw['reusablePlugHashes'];
    if (reusable is List) {
      for (final e in reusable) {
        final h = _parsePlugHash(e);
        if (h != null) plugs.add(h);
      }
    }
    if (plugs.isNotEmpty) out[key] = plugs;
  }
  return out;
}

// ---------------------------------------------------------------------------
// CatalogRollTargets — switcher + editor chrome
// ---------------------------------------------------------------------------

/// Active roll-target switcher + Edit / New / Delete + optional editor footer.
///
/// Default active is Off (`activeTargetId == null`). Names only — never bare
/// hash/id as primary label. Soft overlap disables Save only (DBR-IDL-004).
class CatalogRollTargets extends StatelessWidget {
  const CatalogRollTargets({
    super.key,
    required this.targets,
    required this.activeTargetId,
    required this.onActiveChanged,
    this.activeTargetName,
    this.editing = false,
    this.onEdit,
    this.onNew,
    this.onDelete,
    this.canDelete = false,
    this.draftName = '',
    this.onDraftNameChanged,
    this.hasOverlap = false,
    this.onSave,
    this.onCancel,
    this.canSave = false,
  });

  final List<CatalogRollTargetOption> targets;

  /// Null / empty → Off (default).
  final String? activeTargetId;

  final ValueChanged<String?> onActiveChanged;

  /// Display name of active profile (for Semantics); optional when Off.
  final String? activeTargetName;

  final bool editing;
  final VoidCallback? onEdit;
  final VoidCallback? onNew;
  final VoidCallback? onDelete;
  final bool canDelete;

  final String draftName;
  final ValueChanged<String>? onDraftNameChanged;
  final bool hasOverlap;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool canSave;

  bool get _isOff =>
      activeTargetId == null || activeTargetId!.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final activeName = activeTargetName?.trim();
    final semanticsActive = _isOff
        ? 'Roll targets Off'
        : 'Active roll target ${activeName != null && activeName.isNotEmpty ? activeName : 'selected'}';

    // No parent Semantics(container) — dynamic opt/action buttons already own
    // a11y. A labeled container + child buttons reparents on active-target
    // switches and thrashs Windows accessibility_bridge (AXTree node errors).
    return Column(
      key: const Key('catalog_roll_targets'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header label only (exclude Text). Opts/actions own button a11y.
        Semantics(
          label: semanticsActive,
          excludeSemantics: true,
          child: Text(
            'ROLL TARGET',
            style: neonMono(
              color: palette.muted.withValues(alpha: 0.7),
              fontSize: 8,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // One horizontal row (BUG-20260807-006) — content-sized chips, not
        // full-width stacked bars. Scroll if the rail is too narrow.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const Key('catalog_roll_target_switcher'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _RollTargetOpt(
                key: const Key('roll_target_opt_off'),
                label: 'Off',
                selected: _isOff,
                isOff: true,
                onTap: () => onActiveChanged(null),
              ),
              for (final t in targets) ...[
                const SizedBox(width: 4),
                _RollTargetOpt(
                  key: Key('roll_target_opt_${t.id}'),
                  label: t.name,
                  selected: !_isOff && activeTargetId == t.id,
                  isOff: false,
                  onTap: () => onActiveChanged(t.id),
                ),
              ],
              if (onNew != null || onEdit != null || onDelete != null)
                const SizedBox(width: 8),
              if (onNew != null)
                _RollTargetActionBtn(
                  key: const Key('roll_target_new'),
                  label: 'New',
                  primary: true,
                  onTap: onNew,
                ),
              if (onEdit != null) ...[
                if (onNew != null) const SizedBox(width: 4),
                _RollTargetActionBtn(
                  key: const Key('roll_target_edit'),
                  label: editing ? 'Editing' : 'Edit',
                  primary: editing,
                  pressed: editing,
                  onTap: onEdit,
                ),
              ],
              if (onDelete != null) ...[
                if (onNew != null || onEdit != null) const SizedBox(width: 4),
                _RollTargetActionBtn(
                  key: const Key('roll_target_delete'),
                  label: 'Delete',
                  danger: true,
                  onTap: canDelete ? onDelete : null,
                ),
              ],
            ],
          ),
        ),
        if (editing) ...[
          const SizedBox(height: 10),
          _EditorChrome(
            draftName: draftName,
            onDraftNameChanged: onDraftNameChanged,
            hasOverlap: hasOverlap,
            onSave: canSave ? onSave : null,
            onCancel: onCancel,
          ),
        ],
      ],
    );
  }
}

class _RollTargetOpt extends StatelessWidget {
  const _RollTargetOpt({
    super.key,
    required this.label,
    required this.selected,
    required this.isOff,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isOff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected
        ? (isOff
            ? palette.lineStrong
            : palette.accent.withValues(alpha: 0.5))
        : palette.line;
    final bg = selected
        ? (isOff
            ? palette.muted.withValues(alpha: 0.08)
            : palette.accent.withValues(alpha: 0.14))
        : palette.surfaceRaised;
    final fg = selected ? palette.foreground : palette.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMax),
          child: Container(
            height: 26,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 26),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(kRadiusMax),
              border: Border.all(color: borderColor, width: kFlapRuleThickness),
            ),
            foregroundDecoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusMax),
                    border: Border(
                      bottom: BorderSide(
                        color: isOff
                            ? palette.muted.withValues(alpha: 0.45)
                            : palette.accent,
                        width: 2,
                      ),
                    ),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: neonMono(
                color: fg,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RollTargetActionBtn extends StatelessWidget {
  const _RollTargetActionBtn({
    super.key,
    required this.label,
    this.primary = false,
    this.danger = false,
    this.pressed = false,
    this.onTap,
  });

  final String label;
  final bool primary;
  final bool danger;
  final bool pressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final enabled = onTap != null;
    final Color borderColor;
    final Color fg;
    final Color bg;
    if (!enabled) {
      borderColor = palette.line;
      fg = palette.muted.withValues(alpha: 0.45);
      bg = palette.surface;
    } else if (primary || pressed) {
      borderColor = palette.accent.withValues(alpha: 0.4);
      fg = pressed ? palette.foreground : palette.accent;
      bg = palette.accent.withValues(alpha: 0.12);
    } else if (danger) {
      borderColor = palette.line;
      fg = palette.muted;
      bg = palette.surface;
    } else {
      borderColor = palette.line;
      fg = palette.muted;
      bg = palette.surface;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMax),
          child: Container(
            height: 26,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 26),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(kRadiusMax),
              border: Border.all(color: borderColor, width: kFlapRuleThickness),
            ),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: neonMono(
                color: fg,
                fontSize: 8,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorChrome extends StatelessWidget {
  const _EditorChrome({
    required this.draftName,
    required this.onDraftNameChanged,
    required this.hasOverlap,
    required this.onSave,
    required this.onCancel,
  });

  final String draftName;
  final ValueChanged<String>? onDraftNameChanged;
  final bool hasOverlap;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('catalog_roll_target_editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'EDIT TARGET',
              style: neonMono(
                color: palette.accent,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Want · Avoid · Off on instance and can-roll plugs',
                style: neonMono(
                  color: palette.muted.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: _RollTargetNameField(
            key: const Key('roll_target_name_field'),
            value: draftName,
            onChanged: onDraftNameChanged,
          ),
        ),
        if (hasOverlap) ...[
          const SizedBox(height: 8),
          _SoftOverlapError(),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RollTargetActionBtn(
              key: const Key('roll_target_save'),
              label: 'Save',
              primary: true,
              onTap: onSave,
            ),
            _RollTargetActionBtn(
              key: const Key('roll_target_cancel'),
              label: 'Cancel',
              onTap: onCancel,
            ),
          ],
        ),
      ],
    );
  }
}

class _SoftOverlapError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      key: const Key('roll_target_overlap_error'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kRadiusMax),
        border: Border.all(
          color: palette.danger.withValues(alpha: 0.4),
          width: kFlapRuleThickness,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOFT',
            style: neonMono(
              color: palette.danger,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: neonMono(
                  color: const Color(0xFFFFB3C0),
                  fontSize: 11,
                ),
                children: [
                  const TextSpan(
                    text: 'Preferred and avoid overlap on a column. ',
                  ),
                  TextSpan(
                    text: 'Save disabled',
                    style: neonMono(
                      color: palette.foreground,
                      fontSize: 11,
                    ),
                  ),
                  const TextSpan(
                    text: ' until disjoint — equip/export still open.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps a stable [TextEditingController] while the editor is open.
class _RollTargetNameField extends StatefulWidget {
  const _RollTargetNameField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  State<_RollTargetNameField> createState() => _RollTargetNameFieldState();
}

class _RollTargetNameFieldState extends State<_RollTargetNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _RollTargetNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: neonMono(color: palette.foreground, fontSize: 12),
      inputFormatters: [
        LengthLimitingTextInputFormatter(40),
      ],
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Name (e.g. PvE)',
        hintStyle: neonMono(
          color: palette.muted.withValues(alpha: 0.5),
          fontSize: 11,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMax),
          borderSide: BorderSide(color: palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMax),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMax),
          borderSide: BorderSide(color: palette.accent),
        ),
        filled: true,
        fillColor: palette.background,
      ),
    );
  }
}
