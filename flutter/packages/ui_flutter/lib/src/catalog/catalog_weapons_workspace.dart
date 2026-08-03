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

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final hasDetail = detail != null;

    Widget mainChild = main;
    Widget? detailChild = detail;
    if (softZones) {
      mainChild = NeonZone(child: mainChild);
      if (detailChild != null) {
        detailChild = NeonZone(child: detailChild);
      }
    }

    return Row(
      key: const Key('catalog_weapons_workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: mainChild),
        if (hasDetail) ...[
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
            child: detailChild,
          ),
        ],
      ],
    );
  }
}
