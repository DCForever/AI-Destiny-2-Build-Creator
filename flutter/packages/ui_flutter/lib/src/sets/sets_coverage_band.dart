import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../catalog/entity_info_hotspot.dart';
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
    final hardOk = data.hardMet && data.hardGoals.isNotEmpty;
    final hardTone = hardOk
        ? palette.success
        : data.hardGoals.isEmpty
            ? palette.muted
            : palette.warning;
    final hardBg = hardOk
        ? palette.success.withValues(alpha: 0.06)
        : data.hardGoals.isEmpty
            ? palette.background
            : palette.warning.withValues(alpha: 0.06);
    final hardBorder = hardOk
        ? palette.success.withValues(alpha: 0.3)
        : data.hardGoals.isEmpty
            ? palette.line
            : palette.warning.withValues(alpha: 0.3);

    return Column(
      key: const Key('sets_coverage_band'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mockup .hard-band
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hardBg,
            border: Border.all(color: hardBorder, width: kFlapRuleThickness),
            borderRadius: BorderRadius.circular(kFlapRadius),
          ),
          child: data.hardGoals.isEmpty
              ? Text(
                  'No hard set-bonus goals',
                  key: const Key('sets_coverage_hard_none'),
                  style: neonBody(color: palette.muted, fontSize: 11),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Bonus goals',
                      style: neonBody(color: hardTone, fontSize: 11),
                    ),
                    for (final g in data.hardGoals)
                      _goalChip(
                        chipKey: 'sets_coverage_hard_${g.familyKey}_${g.minPieces}',
                        label: g.display,
                        tone: hardTone,
                        entityInfo: g.entityInfo,
                      ),
                  ],
                ),
        ),
        if (data.softTwoPiece.isNotEmpty || data.softFourPiece.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Mockup .soft-band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.05),
              border: Border.all(
                color: Colors.transparent,
                width: kFlapRuleThickness,
              ),
              borderRadius: BorderRadius.circular(kFlapRadius),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Soft detect · ≥2 matching non-exotic family',
                  style: neonBody(
                    color: palette.muted.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
                for (final f in data.softTwoPiece)
                  _goalChip(
                    chipKey: 'sets_coverage_soft_2pc_$f',
                    label: '$f ≥2pc',
                    tone: palette.muted,
                    entityInfo: data.softEntityInfoByFamily[f],
                    mono: true,
                  ),
                for (final f in data.softFourPiece)
                  _goalChip(
                    chipKey: 'sets_coverage_soft_4pc_$f',
                    label: '$f ≥4pc',
                    tone: palette.muted,
                    entityInfo: data.softEntityInfoByFamily[f],
                    mono: true,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Goal / family chip; wraps [EntityInfoHotspot] when [entityInfo] is set.
  Widget _goalChip({
    required String chipKey,
    required String label,
    required Color tone,
    EntityInfoData? entityInfo,
    bool mono = false,
  }) {
    final text = Text(
      label,
      key: Key(chipKey),
      style: mono
          ? neonMono(color: tone, fontSize: 11)
          : neonBody(color: tone, fontSize: 11),
    );
    if (entityInfo == null) return text;
    return EntityInfoHotspot(
      key: Key('${chipKey}_info'),
      data: entityInfo,
      child: text,
    );
  }
}
