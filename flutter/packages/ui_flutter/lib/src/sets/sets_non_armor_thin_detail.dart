import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// Non-Armor: shell list + thin detail only (no full board).
class SetsNonArmorThinDetail extends StatelessWidget {
  const SetsNonArmorThinDetail({
    super.key,
    required this.data,
    this.onOpenLegacy,
    this.onDelete,
  });

  final SetsNonArmorThinData data;
  final VoidCallback? onOpenLegacy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Padding(
      key: const Key('sets_non_armor_thin_detail'),
      padding: const EdgeInsets.all(kSpace16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.name,
            key: const Key('sets_non_armor_name'),
            style: neonBody(
              color: palette.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpace8),
          Text(
            data.typeLabel,
            key: const Key('sets_non_armor_type'),
            style: neonBody(color: palette.muted, fontSize: 13),
          ),
          const SizedBox(height: kSpace8),
          Text(
            data.pieceSummary,
            key: const Key('sets_non_armor_pieces'),
            style: neonBody(color: palette.muted, fontSize: 13),
          ),
          if (data.tags.isNotEmpty) ...[
            const SizedBox(height: kSpace8),
            Wrap(
              spacing: 6,
              children: [
                for (final t in data.tags)
                  Chip(label: Text(t)),
              ],
            ),
          ],
          const SizedBox(height: kSpace16),
          Text(
            'Full board for this type is out of Armor MVP scope.',
            key: const Key('sets_non_armor_scope_note'),
            style: neonBody(color: palette.muted, fontSize: 12),
          ),
          const Spacer(),
          if (onOpenLegacy != null)
            OutlinedButton(
              key: const Key('sets_non_armor_open_legacy'),
              onPressed: onOpenLegacy,
              child: const Text('Open legacy detail'),
            ),
          if (onDelete != null)
            TextButton(
              key: const Key('sets_non_armor_delete'),
              onPressed: onDelete,
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }
}
