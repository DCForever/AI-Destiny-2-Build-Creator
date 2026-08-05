import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default keys · empty groups',
  type: CatalogSortGroupSheet,
  path: '[Catalog]/SortGroup',
)
Widget sortGroupDefault(BuildContext context) {
  return _sheetFrame(
    CatalogSortGroupSheet(
      sortKeys: List<CatalogSortKey>.from(kDefaultWeaponSortKeys),
      groupDimensions: const [],
      availableGroupDimensions: weaponGroupDimensions,
      onApply: (_, __) {},
      onCancel: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Active slot · element groups',
  type: CatalogSortGroupSheet,
  path: '[Catalog]/SortGroup',
)
Widget sortGroupWithDims(BuildContext context) {
  return _sheetFrame(
    CatalogSortGroupSheet(
      sortKeys: List<CatalogSortKey>.from(kDefaultWeaponSortKeys),
      groupDimensions: const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ],
      availableGroupDimensions: weaponGroupDimensions,
      onApply: (_, __) {},
      onCancel: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Interactive apply (snackbar)',
  type: CatalogSortGroupSheet,
  path: '[Catalog]/SortGroup',
)
Widget sortGroupInteractive(BuildContext context) {
  return _SortGroupInteractive();
}

Widget _sheetFrame(Widget child) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
      child: SingleChildScrollView(child: child),
    ),
  );
}

class _SortGroupInteractive extends StatefulWidget {
  @override
  State<_SortGroupInteractive> createState() => _SortGroupInteractiveState();
}

class _SortGroupInteractiveState extends State<_SortGroupInteractive> {
  var _last = 'Reorder + Apply to see result';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _sheetFrame(
            CatalogSortGroupSheet(
              sortKeys: List<CatalogSortKey>.from(kDefaultWeaponSortKeys),
              groupDimensions: const [CatalogGroupDimension.slot],
              availableGroupDimensions: weaponGroupDimensions,
              onApply: (sort, group) {
                setState(() {
                  _last =
                      'sort=${sort.map((k) => k.name).join('→')} · '
                      'group=${group.map((g) => g.name).join('+')}';
                });
              },
              onCancel: () => setState(() => _last = 'cancelled'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_last, key: const Key('wb_sort_group_last_apply')),
        ),
      ],
    );
  }
}
