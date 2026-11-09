import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';
import 'sets_neon_chrome.dart';

/// Delete confirm content: always confirm; SET_IN_USE + used-by when attached.
class SetsDeleteConfirm extends StatelessWidget {
  const SetsDeleteConfirm({
    super.key,
    required this.setName,
    this.usedBy = const [],
    this.onConfirm,
    this.onCancel,
  });

  final String setName;
  final List<SetsUsedByData> usedBy;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  bool get isInUse => usedBy.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final dangerStyle = setsNeonGhostStyle(palette).copyWith(
      foregroundColor: WidgetStatePropertyAll(palette.danger),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: palette.danger.withValues(alpha: 0.4),
          width: kFlapRuleThickness,
        ),
      ),
    );
    return AlertDialog(
      key: const Key('sets_delete_confirm_dialog'),
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
        side: BorderSide(color: palette.lineStrong, width: kFlapRuleThickness),
      ),
      title: Text(
        (isInUse ? 'Set in use' : 'Delete set?').toUpperCase(),
        style: neonDisplay(
          color: palette.foreground,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isInUse
                ? 'Cannot delete "$setName" — attached to builds.'
                : 'Delete "$setName"? This cannot be undone.',
            key: const Key('sets_delete_confirm_message'),
            style: neonBody(color: palette.foreground, fontSize: 14),
          ),
          if (isInUse) ...[
            const SizedBox(height: kSpace12),
            Text(
              'SET_IN_USE',
              key: const Key('sets_delete_set_in_use'),
              style: neonMono(
                color: palette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kSpace8),
            for (final u in usedBy)
              Text(
                u.label,
                key: Key('sets_delete_used_by_${u.buildId}_${u.variantId}'),
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('sets_delete_cancel'),
          style: setsNeonGhostStyle(palette),
          onPressed: onCancel,
          child: Text('Cancel', style: setsNeonBtnLabel(palette.muted)),
        ),
        if (!isInUse)
          FilledButton(
            key: const Key('sets_delete_confirm'),
            style: dangerStyle,
            onPressed: onConfirm,
            child: Text(
              'Delete'.toUpperCase(),
              style: setsNeonBtnLabel(palette.danger),
            ),
          ),
      ],
    );
  }
}

/// Show [SetsDeleteConfirm] as a dialog; returns true only when confirmed.
Future<bool> showSetsDeleteConfirm({
  required BuildContext context,
  required String setName,
  List<SetsUsedByData> usedBy = const [],
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => SetsDeleteConfirm(
      setName: setName,
      usedBy: usedBy,
      onCancel: () => Navigator.of(ctx).pop(false),
      onConfirm: () => Navigator.of(ctx).pop(true),
    ),
  );
  return result == true;
}
