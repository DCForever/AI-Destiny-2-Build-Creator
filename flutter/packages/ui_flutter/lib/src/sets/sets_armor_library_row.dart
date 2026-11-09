import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../unbroken_label.dart';
import 'sets_models.dart';

/// Armor library flap row: Name · class · pieces · coverage · used-by.
class SetsArmorLibraryRow extends StatelessWidget {
  const SetsArmorLibraryRow({
    super.key,
    required this.data,
    this.onTap,
  });

  final SetsArmorLibraryRowData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final bg = data.selected
        ? palette.accent.withValues(alpha: kFlapChannelWashAlpha)
        : Colors.transparent;
    return Material(
      color: bg,
      child: InkWell(
        key: Key('sets_armor_row_${data.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: kSpace8,
            vertical: kSpace8,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 14,
                child: Text(
                  data.name,
                  key: Key('sets_armor_row_name_${data.id}'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(
                    color: palette.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: UnbrokenLabel(
                  data.classLabel,
                  key: Key('sets_armor_row_class_${data.id}'),
                  style: neonBody(color: palette.muted, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  data.piecesLabel,
                  key: Key('sets_armor_row_pieces_${data.id}'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: neonMono(color: palette.foreground, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 9,
                child: Text(
                  data.coverageLabel,
                  key: Key('sets_armor_row_coverage_${data.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(color: palette.muted, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 8,
                child: Text(
                  data.usedByLabel,
                  key: Key('sets_armor_row_usedby_${data.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(color: palette.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header labels for Armor Sets flap board.
class SetsArmorLibraryHeader extends StatelessWidget {
  const SetsArmorLibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final labels = kFlapColumnsSetsArmor.headerLabels;
    return Container(
      key: const Key('sets_armor_library_header'),
      padding: const EdgeInsets.symmetric(
        horizontal: kSpace8,
        vertical: kSpace4,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: const [14, 7, 4, 9, 8][i],
              child: UnbrokenLabel(
                labels[i].toUpperCase(),
                fit: true,
                style: neonDisplay(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
