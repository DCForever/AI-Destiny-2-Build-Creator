import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// Hard goals + soft ≥2pc muted coverage band (layout A).
class SetsCoverageBand extends StatelessWidget {
  const SetsCoverageBand({
    super.key,
    required this.data,
  });

  final SetsCoverageBandData data;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('sets_coverage_band'),
      padding: const EdgeInsets.all(kSpace8),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.hardGoals.isEmpty)
            Text(
              'No hard set-bonus goals',
              key: const Key('sets_coverage_hard_none'),
              style: neonBody(color: palette.muted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final g in data.hardGoals)
                  Chip(
                    key: Key(
                      'sets_coverage_hard_${g.familyKey}_${g.minPieces}',
                    ),
                    label: Text(g.display),
                    backgroundColor: data.hardMet
                        ? scheme.primaryContainer
                        : scheme.errorContainer,
                  ),
              ],
            ),
          if (data.softTwoPiece.isNotEmpty || data.softFourPiece.isNotEmpty) ...[
            const SizedBox(height: kSpace8),
            Text(
              'Soft coverage',
              style: neonBody(color: palette.muted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final f in data.softTwoPiece)
                  Chip(
                    key: Key('sets_coverage_soft_2pc_$f'),
                    label: Text(
                      '$f ≥2pc',
                      style: neonBody(color: palette.muted, fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                for (final f in data.softFourPiece)
                  Chip(
                    key: Key('sets_coverage_soft_4pc_$f'),
                    label: Text(
                      '$f ≥4pc',
                      style: neonBody(color: palette.muted, fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
