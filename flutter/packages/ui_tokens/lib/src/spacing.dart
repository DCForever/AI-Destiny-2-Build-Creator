/// Density spacing scale (logical px) — Neon Network.
///
/// Scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 (+ density extras 2/6/10 for board rows).
library;

const double kSpace2 = 2;
const double kSpace4 = 4;
const double kSpace6 = 6;
const double kSpace8 = 8;
const double kSpace10 = 10;
const double kSpace12 = 12;
const double kSpace16 = 16;
const double kSpace24 = 24;
const double kSpace32 = 32;
const double kSpace48 = 48;

/// Control height seed (Neon `--control-h`).
const double kControlHeight = 40;

const double kPanelPadSm = 8;
const double kPanelPadMd = 12;
const double kPanelPadLg = 16;

const double kPageXSm = 8;
const double kPageX = 20;
const double kPageYSm = 6;
const double kPageY = 12;

/// Vertical padding inside a flap row cell strip.
const double kFlapRowY = 6;

/// **Board not cards:** zero gap between stacked flap rows.
const double kFlapGap = 0;

/// Named spacing tokens for hosts that prefer a map-like API.
class FlapSpacing {
  const FlapSpacing._();

  static const double s2 = kSpace2;
  static const double s4 = kSpace4;
  static const double s6 = kSpace6;
  static const double s8 = kSpace8;
  static const double s10 = kSpace10;
  static const double s12 = kSpace12;
  static const double s16 = kSpace16;
  static const double s24 = kSpace24;
  static const double s32 = kSpace32;
  static const double s48 = kSpace48;
  static const double controlH = kControlHeight;
  static const double panelSm = kPanelPadSm;
  static const double panelMd = kPanelPadMd;
  static const double panelLg = kPanelPadLg;
  static const double pageXSm = kPageXSm;
  static const double pageX = kPageX;
  static const double pageYSm = kPageYSm;
  static const double pageY = kPageY;
  static const double flapRowY = kFlapRowY;
  static const double flapGap = kFlapGap;
}
