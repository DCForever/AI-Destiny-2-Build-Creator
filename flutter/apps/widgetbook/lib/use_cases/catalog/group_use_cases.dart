import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Expanded header',
  type: CatalogGroupHeader,
  path: '[Catalog]/Group',
)
Widget groupHeaderExpanded(BuildContext context) {
  return CatalogGroupHeader(
    groupKey: 'kinetic',
    label: 'Kinetic',
    count: 14,
    expanded: true,
    onToggle: () {},
  );
}

@widgetbook.UseCase(
  name: 'Collapsed header',
  type: CatalogGroupHeader,
  path: '[Catalog]/Group',
)
Widget groupHeaderCollapsed(BuildContext context) {
  return CatalogGroupHeader(
    groupKey: 'energy',
    label: 'Energy',
    count: 8,
    expanded: false,
    onToggle: () {},
  );
}

@widgetbook.UseCase(
  name: 'Outline rail (≥2 groups)',
  type: CatalogGroupOutlineRail,
  path: '[Catalog]/Group',
)
Widget groupOutlineRail(BuildContext context) {
  return SizedBox(
    height: 320,
    child: Align(
      alignment: Alignment.centerRight,
      child: CatalogGroupOutlineRail(
        activeKey: 'kinetic',
        onJump: (_) {},
        groups: const [
          (key: 'kinetic', label: 'Kinetic', count: 14),
          (key: 'energy', label: 'Energy', count: 8),
          (key: 'power', label: 'Power', count: 5),
        ],
      ),
    ),
  );
}
