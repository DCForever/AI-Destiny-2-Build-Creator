import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';

/// Status tone keys used by soft coverage chips and badges.
///
/// **One Lamp:** never map `success` / supported to [ColorScheme.primary] (amber).
const String kFlapToneSuccess = 'success';
const String kFlapToneWarning = 'warning';
const String kFlapToneDanger = 'danger';
const String kFlapToneMuted = 'muted';
const String kFlapToneAccent = 'accent';

/// Resolves a tone key to a solid lamp color from [FlapPalette].
Color flapToneColor(BuildContext context, String toneKey) {
  final p = FlapPalette.of(context);
  switch (toneKey) {
    case kFlapToneSuccess:
      return p.success;
    case kFlapToneWarning:
      return p.warning;
    case kFlapToneDanger:
      return p.danger;
    case kFlapToneAccent:
      return p.accent;
    case kFlapToneMuted:
    default:
      return p.muted;
  }
}

/// Status wash fill (~[kFlapBadgeWashAlpha]) for chips / badges.
Color flapToneWash(BuildContext context, String toneKey, {double? alpha}) {
  final a = alpha ?? kFlapBadgeWashAlpha;
  return flapToneColor(context, toneKey).withValues(alpha: a);
}
