import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';

/// Maps a damage-type / element name to Destiny element ink.
///
/// Accepts common wire labels (`arc`, `Solar`, `void`, `stasis`, …).
/// Returns null when unrecognized (caller should keep neutral lettering).
Color? flapElementColor(BuildContext context, String? damageType) {
  if (damageType == null) return null;
  final key = damageType.trim().toLowerCase();
  if (key.isEmpty) return null;
  final p = FlapPalette.of(context);
  switch (key) {
    case 'kinetic':
      return p.elementKinetic;
    case 'arc':
      return p.elementArc;
    case 'solar':
      return p.elementSolar;
    case 'void':
      return p.elementVoid;
    case 'stasis':
      return p.elementStasis;
    case 'strand':
      return p.elementStrand;
    case 'prismatic':
      return p.elementPrismatic;
    default:
      return null;
  }
}

/// First element name found in free text (e.g. identity / synergy summary).
Color? flapElementColorFromText(BuildContext context, String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final lower = text.toLowerCase();
  const names = [
    'prismatic',
    'kinetic',
    'stasis',
    'strand',
    'solar',
    'void',
    'arc',
  ];
  for (final n in names) {
    if (lower.contains(n)) {
      return flapElementColor(context, n);
    }
  }
  return null;
}

/// Channel wash (~[kFlapChannelWashAlpha]) for identity / seal cells.
Color flapChannelWash(BuildContext context, Color channel) {
  return channel.withValues(alpha: kFlapChannelWashAlpha);
}
