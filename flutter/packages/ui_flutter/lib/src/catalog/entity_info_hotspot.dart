import 'dart:async';

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bungie_content_icon.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';

// ---------------------------------------------------------------------------
// Presentation DTO (host maps domain EntityPresentation; no domain dep here)
// ---------------------------------------------------------------------------

/// Fixed empty body when description is missing (DBR-UI-005 — never invent).
const String kEntityInfoNoDescription = 'No catalog description';

/// Chrome-facing entity info (mirrors pure [EntityPresentation] fields).
///
/// Host builds this from `resolveEntityPresentation` / maps. Never invent body.
@immutable
class EntityInfoData {
  const EntityInfoData({
    required this.id,
    required this.name,
    this.kind,
    this.iconPath,
    this.description = '',
    this.metaLines = const [],
    this.nameUnknown = false,
    this.hashFooter,
    this.baseDescription,
    this.enhancedDescription,
    this.accentColor,
  });

  /// Stable open-stack id (usually plug hash as string).
  final String id;

  /// Primary label — never a bare numeric hash (DBR-UI-006).
  final String name;

  final String? kind;
  final String? iconPath;

  /// Definition text; empty when absent.
  final String description;

  final List<String> metaLines;
  final bool nameUnknown;

  /// Optional support footer e.g. `#123` — never primary label.
  final String? hashFooter;

  /// When both non-empty, L2 shows base vs enhanced compare.
  final String? baseDescription;
  final String? enhancedDescription;

  final Color? accentColor;

  bool get hasDescription => description.trim().isNotEmpty;

  bool get hasCompare {
    final b = baseDescription?.trim() ?? '';
    final e = enhancedDescription?.trim() ?? '';
    return b.isNotEmpty && e.isNotEmpty;
  }

  /// Body for non-compare path: description or honest empty string.
  String get displayBody =>
      hasDescription ? description.trim() : kEntityInfoNoDescription;

  EntityInfoData copyWith({
    String? id,
    String? name,
    String? kind,
    String? iconPath,
    String? description,
    List<String>? metaLines,
    bool? nameUnknown,
    String? hashFooter,
    String? baseDescription,
    String? enhancedDescription,
    Color? accentColor,
  }) {
    return EntityInfoData(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconPath: iconPath ?? this.iconPath,
      description: description ?? this.description,
      metaLines: metaLines ?? this.metaLines,
      nameUnknown: nameUnknown ?? this.nameUnknown,
      hashFooter: hashFooter ?? this.hashFooter,
      baseDescription: baseDescription ?? this.baseDescription,
      enhancedDescription: enhancedDescription ?? this.enhancedDescription,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EntityInfoData) return false;
    if (other.id != id ||
        other.name != name ||
        other.kind != kind ||
        other.iconPath != iconPath ||
        other.description != description ||
        other.nameUnknown != nameUnknown ||
        other.hashFooter != hashFooter ||
        other.baseDescription != baseDescription ||
        other.enhancedDescription != enhancedDescription ||
        other.accentColor != accentColor) {
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
        id,
        name,
        kind,
        iconPath,
        description,
        nameUnknown,
        hashFooter,
        baseDescription,
        enhancedDescription,
        accentColor,
        Object.hashAll(metaLines),
      );
}

// ---------------------------------------------------------------------------
// Single-open portal (desktop Overlay) + mobile sheet
// ---------------------------------------------------------------------------

const double kEntityInfoPopoverWidth = 280;
const Duration kEntityInfoLongPress = Duration(milliseconds: 450);

/// Global single-open registry for entity info (scoped by Overlay tree).
class EntityInfoPortal {
  EntityInfoPortal._();

  static OverlayEntry? _entry;
  static String? _activeId;
  static bool _pointerOverPopover = false;

  static String? get activeId => _activeId;
  static bool get isOpen => _activeId != null;

  static void close() {
    _entry?.remove();
    _entry = null;
    _activeId = null;
    _pointerOverPopover = false;
  }

  /// Desktop hover/focus popover near [anchor].
  static void showPopover(
    BuildContext context, {
    required EntityInfoData data,
    required Rect anchor,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    if (_activeId == data.id && _entry != null) {
      // Reposition only.
      _entry!.markNeedsBuild();
      return;
    }

    close();
    _activeId = data.id;
    _entry = OverlayEntry(
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        const pad = 8.0;
        var left = anchor.left;
        if (left + kEntityInfoPopoverWidth > size.width - pad) {
          left = (size.width - kEntityInfoPopoverWidth - pad).clamp(pad, size.width);
        }
        var top = anchor.bottom + 6;
        // Prefer flip above if near bottom (approx height).
        if (top + 160 > size.height - pad && anchor.top > 180) {
          top = (anchor.top - 166).clamp(pad, size.height);
        }

        return Stack(
          children: [
            // Capture outside to allow leave-dismiss without eating primary taps
            // on other widgets (transparent, ignore pointer for pass-through
            // except we track leave via MouseRegion on the card only).
            Positioned(
              left: left,
              top: top,
              width: kEntityInfoPopoverWidth,
              child: MouseRegion(
                onEnter: (_) => _pointerOverPopover = true,
                onExit: (_) {
                  _pointerOverPopover = false;
                  // Defer so trigger onExit can re-enter.
                  Future<void>.delayed(const Duration(milliseconds: 40), () {
                    if (!_pointerOverPopover) close();
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  child: EntityInfoCard(
                    key: Key('entity_info_popover_${data.id}'),
                    data: data,
                    compact: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
  }

  static bool get pointerOverPopover => _pointerOverPopover;

  /// Mobile modal sheet (same content model).
  static Future<void> showSheet(
    BuildContext context, {
    required EntityInfoData data,
  }) async {
    close();
    _activeId = data.id;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (ctx) {
          final palette = FlapPalette.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Material(
                color: palette.surfaceRaised,
                borderRadius: BorderRadius.circular(kRadiusMax),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: palette.lineStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    EntityInfoCard(
                      key: Key('entity_info_sheet_${data.id}'),
                      data: data,
                      compact: false,
                      trailing: IconButton(
                        key: const Key('entity_info_sheet_close'),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        icon: Icon(Icons.close, size: 18, color: palette.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (_activeId == data.id) {
        _activeId = null;
      }
    }
  }
}

/// Visual body for popover / sheet.
class EntityInfoCard extends StatelessWidget {
  const EntityInfoCard({
    super.key,
    required this.data,
    this.compact = true,
    this.trailing,
  });

  final EntityInfoData data;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final letter = data.name.isNotEmpty ? data.name[0].toUpperCase() : '?';

    final icon = data.iconPath != null && data.iconPath!.isNotEmpty
        ? BungieContentIcon(
            pathOrUrl: data.iconPath,
            size: 28,
            fallback: _letterBox(palette, letter),
          )
        : _letterBox(palette, letter);

    final meta = <String>[
      ...data.metaLines.where((m) => m.trim().isNotEmpty),
    ];

    return Semantics(
      namesRoute: true,
      label: data.name,
      child: Container(
        key: const Key('entity_info_card'),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          border: Border.all(color: palette.lineStrong, width: kFlapRuleThickness),
          borderRadius: BorderRadius.circular(kRadiusMax),
          boxShadow: compact
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border.all(
                      color: data.accentColor ?? palette.line,
                      width: kFlapRuleThickness,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.kind != null && data.kind!.trim().isNotEmpty)
                        Text(
                          data.kind!.toUpperCase(),
                          style: neonMono(
                            color: palette.muted,
                            fontSize: 9,
                            letterSpacing: 0.08 * 9,
                          ),
                        ),
                      Text(
                        data.name,
                        key: const Key('entity_info_title'),
                        style: neonBody(
                          color: palette.foreground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final m in meta)
                    Text(
                      m,
                      style: neonMono(color: palette.muted, fontSize: 10),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (data.hasCompare)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _compareCol(
                      palette,
                      'Base',
                      data.baseDescription!.trim(),
                      enhanced: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compareCol(
                      palette,
                      'Enhanced',
                      data.enhancedDescription!.trim(),
                      enhanced: true,
                    ),
                  ),
                ],
              )
            else
              Text(
                data.displayBody,
                key: Key(
                  data.hasDescription
                      ? 'entity_info_body'
                      : 'entity_info_body_empty',
                ),
                style: neonBody(
                  color: data.hasDescription
                      ? palette.foreground.withValues(alpha: 0.92)
                      : palette.muted,
                  fontSize: 12,
                ),
              ),
            if (data.hashFooter != null && data.hashFooter!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.hashFooter!,
                key: const Key('entity_info_hash_footer'),
                style: neonMono(
                  color: palette.muted.withValues(alpha: 0.55),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _letterBox(FlapPalette palette, String letter) {
    return Text(
      letter,
      style: neonMono(color: palette.muted, fontSize: 14),
    );
  }

  Widget _compareCol(
    FlapPalette palette,
    String tag,
    String text, {
    required bool enhanced,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(
          color: enhanced
              ? const Color(0xFFCEAE33).withValues(alpha: 0.45)
              : palette.line,
          width: kFlapRuleThickness,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.toUpperCase(),
            style: neonMono(
              color: enhanced ? const Color(0xFFCEAE33) : palette.muted,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: neonBody(color: palette.foreground, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trigger: hover/focus = info; click/tap = primary; long-press/Alt = info
// ---------------------------------------------------------------------------

/// Wraps a control so entity info is secondary and [onPrimary] stays primary.
///
/// - Desktop: hover/focus opens popover; click runs [onPrimary].
/// - Narrow / touch: long-press or Alt+tap opens sheet; tap runs [onPrimary].
class EntityInfoHotspot extends StatefulWidget {
  const EntityInfoHotspot({
    super.key,
    required this.data,
    required this.child,
    this.onPrimary,
    this.enabled = true,
    this.forceSheet,
    this.longPressDuration = kEntityInfoLongPress,
  });

  final EntityInfoData data;
  final Widget child;

  /// Primary action (select / cycle). Never opens info.
  final VoidCallback? onPrimary;

  final bool enabled;

  /// When non-null, forces sheet (true) or popover (false).
  /// Null → sheet when shortest side &lt; 600.
  final bool? forceSheet;

  final Duration longPressDuration;

  @override
  State<EntityInfoHotspot> createState() => _EntityInfoHotspotState();
}

class _EntityInfoHotspotState extends State<EntityInfoHotspot> {
  final FocusNode _focus = FocusNode(debugLabel: 'EntityInfoHotspot');
  bool _longPressFired = false;
  bool _hovering = false;
  Timer? _lpTimer;

  @override
  void dispose() {
    _lpTimer?.cancel();
    if (EntityInfoPortal.activeId == widget.data.id) {
      EntityInfoPortal.close();
    }
    _focus.dispose();
    super.dispose();
  }

  bool get _useSheet {
    if (widget.forceSheet != null) return widget.forceSheet!;
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide < 600;
  }

  void _openInfo() {
    if (!widget.enabled) return;
    if (_useSheet) {
      EntityInfoPortal.showSheet(context, data: widget.data);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    EntityInfoPortal.showPopover(
      context,
      data: widget.data,
      anchor: rect,
    );
  }

  void _maybeCloseOnLeave() {
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (_hovering || EntityInfoPortal.pointerOverPopover) return;
      if (EntityInfoPortal.activeId == widget.data.id) {
        EntityInfoPortal.close();
      }
    });
  }

  void _onPrimary() {
    widget.onPrimary?.call();
  }

  void _clearLp() {
    _lpTimer?.cancel();
    _lpTimer = null;
  }

  void _armLongPress() {
    _clearLp();
    _longPressFired = false;
    _lpTimer = Timer(widget.longPressDuration, () {
      if (!mounted) return;
      _longPressFired = true;
      _openInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onFocusChange: (has) {
        if (!widget.enabled) return;
        if (has && !_useSheet) {
          _openInfo();
        } else if (!has && EntityInfoPortal.activeId == widget.data.id) {
          if (!_hovering && !EntityInfoPortal.pointerOverPopover) {
            EntityInfoPortal.close();
          }
        }
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (EntityInfoPortal.activeId == widget.data.id) {
            EntityInfoPortal.close();
            return KeyEventResult.handled;
          }
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          final alt = HardwareKeyboard.instance.isAltPressed;
          if (alt) {
            _openInfo();
          } else {
            _onPrimary();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) {
          _hovering = true;
          if (!widget.enabled || _useSheet) return;
          _openInfo();
        },
        onExit: (_) {
          _hovering = false;
          _maybeCloseOnLeave();
        },
        child: Listener(
          onPointerDown: (e) {
            if (e.buttons != kPrimaryButton && e.buttons != 0) return;
            _armLongPress();
          },
          onPointerUp: (_) => _clearLp(),
          onPointerCancel: (_) => _clearLp(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _clearLp();
              if (_longPressFired) {
                _longPressFired = false;
                return;
              }
              final alt = HardwareKeyboard.instance.isAltPressed;
              if (alt) {
                _openInfo();
                return;
              }
              _onPrimary();
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Build [EntityInfoData] from cell chrome fields + optional host presentation.
EntityInfoData entityInfoFromPerkCell({
  required int hash,
  required String displayName,
  String? iconPath,
  bool unknown = false,
  EntityInfoData? host,
  List<String> tierMeta = const [],
  String? kind,
}) {
  if (host != null) {
    final mergedMeta = <String>[
      ...tierMeta,
      ...host.metaLines,
    ];
    return host.copyWith(
      id: host.id.isNotEmpty ? host.id : '$hash',
      name: host.name.isNotEmpty ? host.name : displayName,
      metaLines: mergedMeta,
      iconPath: host.iconPath ?? iconPath,
      kind: host.kind ?? kind,
    );
  }
  return EntityInfoData(
    id: '$hash',
    name: displayName,
    iconPath: iconPath,
    description: '',
    metaLines: tierMeta,
    nameUnknown: unknown,
    kind: kind,
    hashFooter: unknown ? '#$hash' : null,
  );
}
