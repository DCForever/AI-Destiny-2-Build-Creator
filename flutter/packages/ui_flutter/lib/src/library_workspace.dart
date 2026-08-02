import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';
import 'neon_atmosphere.dart';

/// Dual-pane library shell: fixed rail + detail (Neon Network / FlapBoard).
///
/// Soft zones replace card cages; hairline structure only. Mobile Focus Swap
/// should not force this layout — use only on desktop-class hosts.
class LibraryWorkspace extends StatelessWidget {
  const LibraryWorkspace({
    super.key,
    required this.rail,
    required this.detail,
    this.railWidth = kFlapLibraryRailWidth,
    this.maxWidth = kPageFrameMaxWidth,
    this.softZones = true,
  });

  final Widget rail;
  final Widget detail;
  final double railWidth;
  final double maxWidth;

  /// Wrap rail/detail in [NeonZone] surfaces (default true).
  final bool softZones;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    Widget railChild = rail;
    Widget detailChild = detail;
    if (softZones) {
      railChild = NeonZone(child: rail);
      detailChild = NeonZone(child: detail);
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(kSpace8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: railWidth, child: railChild),
              SizedBox(
                width: kSpace12,
                child: Center(
                  child: Container(
                    width: kFlapRuleThickness,
                    color: palette.line,
                  ),
                ),
              ),
              Expanded(child: detailChild),
            ],
          ),
        ),
      ),
    );
  }
}
