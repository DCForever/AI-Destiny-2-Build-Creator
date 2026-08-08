import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Soft max named collections per browse mode (presentation mirror of domain).
const int kCatalogFilterCollectionsCapUi = 20;

/// Presentation row for a saved filter collection (host maps domain → this).
///
/// No domain/IO deps — soft apply is host-owned.
class CatalogFilterCollectionItem {
  const CatalogFilterCollectionItem({
    required this.id,
    required this.name,
    required this.summary,
  });

  final String id;
  final String name;

  /// Short criteria summary (e.g. `owned · slot:kinetic · element:void`).
  final String summary;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogFilterCollectionItem &&
        other.id == id &&
        other.name == name &&
        other.summary == summary;
  }

  @override
  int get hashCode => Object.hash(id, name, summary);
}

/// Whether live criteria are worth saving (not empty defaults alone).
///
/// Host computes from session filters — sort defaults alone are not savable.
bool catalogFilterCollectionsCanSave({
  required bool hasNonDefaultScope,
  required bool hasQuery,
  required bool hasExoticConstraint,
  required bool hasFacetCriteria,
  required bool hasGroupBy,
  bool hasCustomSort = false,
}) {
  return hasNonDefaultScope ||
      hasQuery ||
      hasExoticConstraint ||
      hasFacetCriteria ||
      hasGroupBy ||
      hasCustomSort;
}

/// Saved-filter trigger + menu/sheet + name dialogs (004 mock).
///
/// Presentation only: host owns list load, soft apply bind, and persist.
class CatalogFilterCollectionsControl extends StatefulWidget {
  const CatalogFilterCollectionsControl({
    super.key,
    required this.items,
    required this.browseModeLabel,
    this.activeId,
    this.activeName,
    this.dirty = false,
    this.signedIn = true,
    this.canSave = false,
    this.atCap = false,
    this.preferSheet = false,
    this.onApply,
    this.onSave,
    this.onRename,
    this.onDelete,
  });

  final List<CatalogFilterCollectionItem> items;
  final String browseModeLabel;
  final String? activeId;
  final String? activeName;
  final bool dirty;
  final bool signedIn;

  /// Host: live criteria savable (not empty defaults).
  final bool canSave;

  /// Host: count >= cap for current mode (new names blocked; replace OK).
  final bool atCap;

  /// When true (narrow / mobile), open bottom sheet instead of dropdown.
  final bool preferSheet;

  /// Soft apply by collection id — host binds criteria only.
  final ValueChanged<String>? onApply;

  /// Persist new/replace-by-name. Return error message or null on success.
  final Future<String?> Function(String name)? onSave;

  /// Rename. Return error message or null on success.
  final Future<String?> Function(String id, String name)? onRename;

  /// Delete. Return error message or null on success.
  final Future<String?> Function(String id)? onDelete;

  @override
  State<CatalogFilterCollectionsControl> createState() =>
      _CatalogFilterCollectionsControlState();
}

class _CatalogFilterCollectionsControlState
    extends State<CatalogFilterCollectionsControl> {
  OverlayEntry? _overlay;
  bool _menuOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (_menuOpen) {
      _menuOpen = false;
    }
  }

  void _closeMenu() {
    _removeOverlay();
    if (mounted) setState(() => _menuOpen = false);
  }

  Future<void> _toggleMenu() async {
    if (_menuOpen) {
      _closeMenu();
      return;
    }
    if (widget.preferSheet) {
      setState(() => _menuOpen = true);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return _CollectionsPanel(
            key: const Key('catalog_filter_collections_sheet'),
            asSheet: true,
            items: widget.items,
            browseModeLabel: widget.browseModeLabel,
            activeId: widget.activeId,
            signedIn: widget.signedIn,
            canSave: widget.canSave,
            atCap: widget.atCap,
            onClose: () => Navigator.of(ctx).maybePop(),
            onApply: (id) {
              Navigator.of(ctx).maybePop();
              widget.onApply?.call(id);
            },
            onRequestSave: () => _runSaveFlow(ctx),
            onRequestRename: (item) => _runRenameFlow(ctx, item),
            onRequestDelete: (item) => _runDeleteFlow(ctx, item),
          );
        },
      );
      if (mounted) setState(() => _menuOpen = false);
      return;
    }

    // Position from the Saved trigger box and clamp to the overlay viewport.
    // Trailing-right control: prefer open leftward so the panel is not clipped
    // off the right edge of the window (bug from Image #1 dual-truth).
    final box = context.findRenderObject() as RenderBox?;
    final overlayState = Overlay.of(context);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || overlayBox == null || !overlayBox.hasSize) {
      return;
    }

    const menuMinW = 280.0;
    const menuMaxW = 340.0;
    const menuMaxH = 420.0;
    const gap = 4.0;
    const pad = 8.0;

    final triggerTopLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final triggerSize = box.size;
    final overlaySize = overlayBox.size;

    final menuW = menuMaxW.clamp(menuMinW, overlaySize.width - pad * 2);
    // Prefer right-align under the trigger (menu right edge ≈ trigger right edge).
    var left = triggerTopLeft.dx + triggerSize.width - menuW;
    // Fall back: left-align under trigger if that keeps more of the panel on-screen.
    if (left < pad) {
      left = triggerTopLeft.dx;
    }
    left = left.clamp(pad, (overlaySize.width - menuW - pad).clamp(pad, overlaySize.width));

    var top = triggerTopLeft.dy + triggerSize.height + gap;
    final spaceBelow = overlaySize.height - top - pad;
    final spaceAbove = triggerTopLeft.dy - pad;
    var maxH = menuMaxH;
    if (spaceBelow < 160 && spaceAbove > spaceBelow) {
      // Open upward when not enough room below.
      maxH = spaceAbove.clamp(120.0, menuMaxH);
      top = (triggerTopLeft.dy - gap - maxH).clamp(pad, overlaySize.height - pad);
    } else {
      maxH = spaceBelow.clamp(120.0, menuMaxH);
    }

    _overlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuW,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: menuMinW,
                    maxWidth: menuW,
                    maxHeight: maxH,
                  ),
                  child: _CollectionsPanel(
                    key: const Key('catalog_filter_collections_menu'),
                    asSheet: false,
                    items: widget.items,
                    browseModeLabel: widget.browseModeLabel,
                    activeId: widget.activeId,
                    signedIn: widget.signedIn,
                    canSave: widget.canSave,
                    atCap: widget.atCap,
                    onClose: _closeMenu,
                    onApply: (id) {
                      _closeMenu();
                      widget.onApply?.call(id);
                    },
                    onRequestSave: () {
                      _closeMenu();
                      _runSaveFlow(context);
                    },
                    onRequestRename: (item) {
                      _closeMenu();
                      _runRenameFlow(context, item);
                    },
                    onRequestDelete: (item) {
                      _closeMenu();
                      _runDeleteFlow(context, item);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlayState.insert(_overlay!);
    setState(() => _menuOpen = true);
  }

  Future<void> _runSaveFlow(BuildContext hostContext) async {
    if (!widget.signedIn || widget.onSave == null) return;
    if (!widget.canSave) return;

    final name = await showCatalogFilterCollectionNameDialog(
      context: hostContext,
      title: 'Save collection',
      confirmLabel: 'Save',
      initialName: '',
    );
    if (name == null || name.trim().isEmpty) return;
    final trimmed = name.trim();

    final existing = widget.items.where(
      (e) => e.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isEmpty && widget.atCap) {
      if (!hostContext.mounted) return;
      await showCatalogFilterCollectionMessageDialog(
        context: hostContext,
        title: 'At limit',
        message:
            'Max $kCatalogFilterCollectionsCapUi saved filters for this mode. '
            'Replace an existing name or delete one first.',
      );
      return;
    }
    if (existing.isNotEmpty) {
      if (!hostContext.mounted) return;
      final ok = await showCatalogFilterCollectionConfirmDialog(
        context: hostContext,
        title: 'Replace collection?',
        message:
            '“${existing.first.name}” already exists for this mode. '
            'Replace its filters?',
        confirmLabel: 'Replace',
        danger: false,
      );
      if (ok != true) return;
    }

    final err = await widget.onSave!(trimmed);
    if (err != null && hostContext.mounted) {
      await showCatalogFilterCollectionMessageDialog(
        context: hostContext,
        title: 'Save failed',
        message: err,
      );
    } else {
      _closeMenu();
    }
  }

  Future<void> _runRenameFlow(
    BuildContext hostContext,
    CatalogFilterCollectionItem item,
  ) async {
    if (!widget.signedIn || widget.onRename == null) return;
    final name = await showCatalogFilterCollectionNameDialog(
      context: hostContext,
      title: 'Rename collection',
      confirmLabel: 'Rename',
      initialName: item.name,
    );
    if (name == null || name.trim().isEmpty) return;
    final err = await widget.onRename!(item.id, name.trim());
    if (err != null && hostContext.mounted) {
      await showCatalogFilterCollectionMessageDialog(
        context: hostContext,
        title: 'Rename failed',
        message: err,
      );
    }
  }

  Future<void> _runDeleteFlow(
    BuildContext hostContext,
    CatalogFilterCollectionItem item,
  ) async {
    if (!widget.signedIn || widget.onDelete == null) return;
    final ok = await showCatalogFilterCollectionConfirmDialog(
      context: hostContext,
      title: 'Delete collection?',
      message: 'Delete “${item.name}”? This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (ok != true) return;
    final err = await widget.onDelete!(item.id);
    if (err != null && hostContext.mounted) {
      await showCatalogFilterCollectionMessageDialog(
        context: hostContext,
        title: 'Delete failed',
        message: err,
      );
    }
  }

  String get _triggerLabel {
    final n = widget.activeName?.trim();
    if (n != null && n.isNotEmpty) {
      return n.length > 14 ? '${n.substring(0, 13)}…' : n;
    }
    return 'Saved';
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final active = widget.activeId != null;
    final label = _triggerLabel;

    return Semantics(
      button: true,
      expanded: _menuOpen,
      label: active
          ? 'Saved filters, active $label${widget.dirty ? ', modified' : ''}'
          : 'Saved filters',
      child: TextButton(
        key: const Key('catalog_filter_collections_saved'),
        onPressed: _toggleMenu,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: active ? palette.accent : palette.muted,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.dirty)
              Container(
                key: const Key('catalog_filter_collections_dirty_dot'),
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label.toUpperCase(),
              style: neonMono(
                color: active ? palette.accent : palette.muted,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              _menuOpen ? Icons.expand_less : Icons.expand_more,
              size: 14,
              color: active ? palette.accent : palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel
// ---------------------------------------------------------------------------

class _CollectionsPanel extends StatelessWidget {
  const _CollectionsPanel({
    super.key,
    required this.asSheet,
    required this.items,
    required this.browseModeLabel,
    required this.activeId,
    required this.signedIn,
    required this.canSave,
    required this.atCap,
    required this.onClose,
    required this.onApply,
    required this.onRequestSave,
    required this.onRequestRename,
    required this.onRequestDelete,
  });

  final bool asSheet;
  final List<CatalogFilterCollectionItem> items;
  final String browseModeLabel;
  final String? activeId;
  final bool signedIn;
  final bool canSave;
  final bool atCap;
  final VoidCallback onClose;
  final ValueChanged<String> onApply;
  final VoidCallback onRequestSave;
  final ValueChanged<CatalogFilterCollectionItem> onRequestRename;
  final ValueChanged<CatalogFilterCollectionItem> onRequestDelete;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asSheet)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: palette.line.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Filter collections',
                style: neonDisplay(
                  color: palette.foreground,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: palette.line.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(kRadiusMax),
              ),
              child: Text(
                browseModeLabel,
                style: neonMono(
                  color: palette.muted,
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (asSheet)
              IconButton(
                key: const Key('catalog_filter_collections_sheet_close'),
                onPressed: onClose,
                icon: Icon(Icons.close, size: 18, color: palette.muted),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: kSpace8),
        if (!signedIn)
          Padding(
            padding: const EdgeInsets.only(bottom: kSpace8),
            child: Text(
              key: const Key('catalog_filter_collections_signed_out'),
              'Sign in to save and restore filter collections.',
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const Key('catalog_filter_collections_save'),
              onPressed: canSave ? onRequestSave : null,
              style: TextButton.styleFrom(
                backgroundColor: palette.accent.withValues(alpha: 0.12),
                foregroundColor: palette.accent,
                disabledForegroundColor: palette.muted.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMax),
                  side: BorderSide(
                    color: palette.accent.withValues(alpha: 0.35),
                    width: kFlapRuleThickness,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Save collection',
                    style: neonMono(
                      color: canSave ? palette.accent : palette.muted,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (!canSave)
                    Text(
                      'Set filters first',
                      style: neonMono(
                        color: palette.muted.withValues(alpha: 0.7),
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (atCap)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                key: const Key('catalog_filter_collections_cap_hint'),
                'Max $kCatalogFilterCollectionsCapUi saved filters for this mode',
                style: neonMono(
                  color: palette.warning,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
        const SizedBox(height: kSpace8),
        Text(
          'Saved · this mode',
          style: neonMono(
            color: palette.muted,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              key: const Key('catalog_filter_collections_empty'),
              signedIn
                  ? 'No saved filters for this mode yet.'
                  : 'No collections while signed out.',
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: asSheet ? 360 : 280),
            child: ListView.builder(
              key: const Key('catalog_filter_collections_list'),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isActive = item.id == activeId;
                return _CollectionRow(
                  item: item,
                  active: isActive,
                  signedIn: signedIn,
                  onApply: () => onApply(item.id),
                  onRename: () => onRequestRename(item),
                  onDelete: () => onRequestDelete(item),
                );
              },
            ),
          ),
      ],
    );

    final panel = Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(kRadiusMax),
        border: Border.all(
          color: palette.line.withValues(alpha: 0.55),
          width: kFlapRuleThickness,
        ),
        boxShadow: asSheet
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: body,
    );

    if (asSheet) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: panel,
        ),
      );
    }
    return panel;
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.item,
    required this.active,
    required this.signedIn,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  });

  final CatalogFilterCollectionItem item;
  final bool active;
  final bool signedIn;
  final VoidCallback onApply;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      color: active
          ? palette.accent.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        key: Key('catalog_filter_collection_row_${item.id}'),
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: neonBody(
                        color: palette.foreground,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.summary.isNotEmpty)
                      Text(
                        item.summary,
                        style: neonMono(
                          color: palette.muted,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (signedIn) ...[
                IconButton(
                  key: Key('catalog_filter_collection_rename_${item.id}'),
                  tooltip: 'Rename',
                  onPressed: onRename,
                  icon: Icon(Icons.edit_outlined, size: 16, color: palette.muted),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  key: Key('catalog_filter_collection_delete_${item.id}'),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 16, color: palette.danger),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

Future<String?> showCatalogFilterCollectionNameDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String initialName = '',
}) async {
  final controller = TextEditingController(text: initialName);
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        final palette = FlapPalette.of(ctx);
        return AlertDialog(
          key: const Key('catalog_filter_collection_name_dialog'),
          backgroundColor: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMax),
            side: BorderSide(
              color: palette.line.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
          ),
          title: Text(
            title,
            style: neonDisplay(color: palette.foreground, fontSize: 14),
          ),
          content: TextField(
            key: const Key('catalog_filter_collection_name_field'),
            controller: controller,
            autofocus: true,
            maxLength: 64,
            style: neonBody(color: palette.foreground, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: neonMono(color: palette.muted, fontSize: 11),
              counterStyle: neonMono(color: palette.muted, fontSize: 9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMax),
                borderSide:
                    BorderSide(color: palette.line.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMax),
                borderSide:
                    BorderSide(color: palette.accent.withValues(alpha: 0.7)),
              ),
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
          ),
          actions: [
            TextButton(
              key: const Key('catalog_filter_collection_name_cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
            ),
            TextButton(
              key: const Key('catalog_filter_collection_name_confirm'),
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.of(ctx).pop(t);
              },
              child: Text(
                confirmLabel,
                style: neonMono(color: palette.accent, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  } finally {
    // After route pop settles; avoid dispose mid-animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }
}

Future<bool?> showCatalogFilterCollectionConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final palette = FlapPalette.of(ctx);
      final accent = danger ? palette.danger : palette.accent;
      return AlertDialog(
        key: const Key('catalog_filter_collection_confirm_dialog'),
        backgroundColor: palette.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMax),
          side: BorderSide(
            color: palette.line.withValues(alpha: 0.55),
            width: kFlapRuleThickness,
          ),
        ),
        title: Text(
          title,
          style: neonDisplay(color: palette.foreground, fontSize: 14),
        ),
        content: Text(
          message,
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
          ),
          TextButton(
            key: const Key('catalog_filter_collection_confirm_ok'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: neonMono(color: accent, fontSize: 11),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showCatalogFilterCollectionMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final palette = FlapPalette.of(ctx);
      return AlertDialog(
        key: const Key('catalog_filter_collection_message_dialog'),
        backgroundColor: palette.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMax),
          side: BorderSide(
            color: palette.line.withValues(alpha: 0.55),
            width: kFlapRuleThickness,
          ),
        ),
        title: Text(
          title,
          style: neonDisplay(color: palette.foreground, fontSize: 14),
        ),
        content: Text(
          message,
          style: neonMono(color: palette.muted, fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: neonMono(color: palette.accent, fontSize: 11),
            ),
          ),
        ],
      );
    },
  );
}
