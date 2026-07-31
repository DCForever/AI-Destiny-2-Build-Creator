/// Shared compose surface CSS for Builds/Sets/Synergies (DART-046).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../theme/theme.dart';

/// Shared styles for compose spine pages.
List<StyleRule> get composePageStyles => [
      css('.compose-page', [
        css('&').styles(
          display: .flex,
          width: 100.percent,
          padding: .all(1.5.rem),
          flexDirection: .column,
          gap: Gap(row: 0.85.rem),
          maxWidth: 52.rem,
        ),
        css('.compose-sub').styles(
          color: flapMutedColor,
          fontSize: 0.9.rem,
        ),
        css('.compose-blocked').styles(
          padding: .all(1.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          color: flapForegroundColor,
          backgroundColor: flapSurfaceColor,
        ),
        css('.compose-card').styles(
          display: .flex,
          padding: .all(1.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          flexDirection: .column,
          gap: Gap(row: 0.6.rem),
          backgroundColor: flapSurfaceColor,
        ),
        css('.compose-card h2').styles(
          margin: .zero,
          color: flapMutedColor,
          fontSize: 0.8.rem,
          fontWeight: .w600,
          letterSpacing: 0.06.em,
          textTransform: .upperCase,
        ),
        css('.compose-card label').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap(row: 0.25.rem),
          color: flapForegroundColor,
          fontSize: 0.85.rem,
        ),
        css('.compose-card input, .compose-card select').styles(
          padding: .symmetric(horizontal: 0.5.rem, vertical: 0.35.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          color: flapForegroundColor,
          backgroundColor: flapBackgroundColor,
        ),
        css('.compose-btn').styles(
          alignSelf: .start,
          padding: .symmetric(horizontal: 0.9.rem, vertical: 0.45.rem),
          border: .all(style: .solid, color: flapAccentColor, width: 1.px),
          color: flapBackgroundColor,
          fontWeight: .w600,
          cursor: .pointer,
          backgroundColor: flapAccentColor,
        ),
        // Primary progression CTA (create / save / finish create).
        css('.compose-btn-primary').styles(
          alignSelf: .stretch,
          padding: .symmetric(horizontal: 1.rem, vertical: 0.55.rem),
          fontSize: 0.95.rem,
        ),
        css('.compose-step-hint').styles(
          margin: .zero,
          color: flapMutedColor,
          fontSize: 0.8.rem,
        ),
        css('.compose-create-card').styles(
          gap: Gap(row: 0.75.rem),
        ),
        css('.compose-btn-ghost').styles(
          padding: .symmetric(horizontal: 0.6.rem, vertical: 0.3.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          color: flapForegroundColor,
          cursor: .pointer,
          backgroundColor: Color('transparent'),
        ),
        css('.compose-error').styles(
          color: Color('#e85d4c'),
          fontSize: 0.85.rem,
        ),
        css('.compose-list').styles(
          margin: .zero,
          padding: .zero,
          listStyle: .none,
        ),
        css('.compose-list-item').styles(
          padding: .symmetric(vertical: 0.45.rem),
          border: .only(bottom: .solid(color: flapLineColor, width: 1.px)),
        ),
        css('.compose-section').styles(
          display: .flex,
          padding: .all(1.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          flexDirection: .column,
          gap: Gap(row: 0.5.rem),
          backgroundColor: flapSurfaceColor,
        ),
        css('.compose-section h2').styles(
          margin: .zero,
          color: flapMutedColor,
          fontSize: 0.8.rem,
          fontWeight: .w600,
          letterSpacing: 0.06.em,
          textTransform: .upperCase,
        ),
        css('.soft-chip').styles(
          display: .inlineBlock,
          margin: .only(right: 0.35.rem, bottom: 0.35.rem),
          padding: .symmetric(horizontal: 0.45.rem, vertical: 0.2.rem),
          border: .all(style: .solid, color: flapLineColor, width: 1.px),
          fontSize: 0.8.rem,
        ),
        css('.soft-chip.success').styles(color: Color('#6bcb77')),
        css('.soft-chip.warning').styles(color: Color('#e8c547')),
        css('.soft-chip.danger').styles(color: Color('#e85d4c')),
        css('.soft-advisory').styles(
          color: flapMutedColor,
          fontSize: 0.8.rem,
          fontStyle: .italic,
        ),
      ]),
    ];
