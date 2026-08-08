import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_atmosphere.dart';

/// Default full-height detail sidebar width (weapons UX brief — not 320 rail).
const double kCatalogWeaponsDetailWidth = 400;

/// Desktop weapons workspace: main results + fixed ~400px full-height detail.
///
/// Do **not** use [LibraryWorkspace] (320 library rail) for this layout.
class CatalogWeaponsWorkspace extends StatelessWidget {
  const CatalogWeaponsWorkspace({
    super.key,
    required this.main,
    this.detail,
    this.detailWidth = kCatalogWeaponsDetailWidth,
    this.softZones = true,
  });

  final Widget main;
  final Widget? detail;
  final double detailWidth;
  final bool softZones;

  /// Minimum main-pane width required beside a fixed detail rail.
  static const double kMinMainBesideDetail = 240;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final hasDetail = detail != null;

    Widget mainChild = main;
    Widget detailChild = detail ?? const SizedBox.shrink();
    if (softZones) {
      mainChild = NeonZone(child: mainChild);
      if (hasDetail) {
        detailChild = NeonZone(child: detailChild);
      }
    }

    // Side-by-side only when there is room (desktop / wide tablet). On phone
    // viewports (e.g. Widgetbook iPhone 13) a forced 400px rail overflows the
    // frame and thrashs layout + semantics (parentDataDirty / AX bridge).
    return LayoutBuilder(
      key: const Key('catalog_weapons_workspace'),
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        // Unbounded / zero during Viewport transitions — never force a rail.
        if (!maxW.isFinite || maxW < 1) {
          return mainChild;
        }

        final sideBySide =
            hasDetail && maxW >= detailWidth + kMinMainBesideDetail;

        if (!sideBySide) {
          // Narrow: main only (mobile host uses push-detail, not a rail).
          return mainChild;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mainChild),
            SizedBox(
              width: kSpace16,
              child: Center(
                child: Container(
                  width: kFlapRuleThickness,
                  color: palette.line,
                ),
              ),
            ),
            SizedBox(
              key: const Key('catalog_detail_pane'),
              width: detailWidth,
              // Host keys [detail] by selected hash so AX remounts cleanly.
              child: detailChild,
            ),
          ],
        );
      },
    );
  }
}
