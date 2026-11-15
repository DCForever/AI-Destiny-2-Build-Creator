import 'package:destiny2_app/destiny2_app.dart';
import 'package:flutter/material.dart';

/// Dry-run title before any TransferItem / dequip write.
const String kApplyMoveConfirmTitle = 'Move items to character';

const String kApplyMoveConfirmBody =
    'These items are not on this character yet. '
    'Review the moves, then confirm to transfer and equip.';

const String kApplyMoveConfirmAccept = 'Move and equip';

const String kApplyMoveConfirmCancel = 'Cancel';

/// Result of the apply move dry-run dialog.
enum ApplyMoveConfirmResult {
  accepted,
  cancelled,
}

/// Shows the DIM-style dry-run list (item · from → to).
///
/// Returns [ApplyMoveConfirmResult.accepted] only when the user presses
/// [kApplyMoveConfirmAccept]. Cancel / dismiss → no writes.
Future<ApplyMoveConfirmResult> showApplyMoveConfirmDialog({
  required BuildContext context,
  required List<ApplyMovePreview> moves,
  String? targetLabel,
}) async {
  final result = await showDialog<ApplyMoveConfirmResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ApplyMoveConfirmDialog(
        moves: moves,
        targetLabel: targetLabel,
      );
    },
  );
  return result ?? ApplyMoveConfirmResult.cancelled;
}

/// Modal: dry-run move list with Move and equip / Cancel.
class ApplyMoveConfirmDialog extends StatelessWidget {
  const ApplyMoveConfirmDialog({
    super.key,
    required this.moves,
    this.targetLabel,
  });

  final List<ApplyMovePreview> moves;
  final String? targetLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = targetLabel == null || targetLabel!.trim().isEmpty
        ? null
        : 'Target: $targetLabel';
    return Dialog(
      key: const Key('apply_move_confirm_dialog'),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kApplyMoveConfirmTitle,
                key: const Key('apply_move_confirm_title'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                kApplyMoveConfirmBody,
                key: const Key('apply_move_confirm_body'),
                style: theme.textTheme.bodyMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  key: const Key('apply_move_confirm_target'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  key: const Key('apply_move_confirm_list'),
                  shrinkWrap: true,
                  itemCount: moves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final move = moves[index];
                    return Text(
                      key: Key('apply_move_row_$index'),
                      '${move.itemLabel}  ·  ${move.fromLabel} → ${move.toLabel}',
                      style: theme.textTheme.bodySmall,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('apply_move_confirm_cancel'),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(ApplyMoveConfirmResult.cancelled);
                    },
                    child: const Text(kApplyMoveConfirmCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('apply_move_confirm_accept'),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(ApplyMoveConfirmResult.accepted);
                    },
                    child: const Text(kApplyMoveConfirmAccept),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
