import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

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
        activeKey: 'Kinetic',
        onJump: (_) {},
        groups: const [
          CatalogGroupOutlineEntry(
            key: 'Kinetic',
            label: 'Kinetic',
            count: 14,
            dimension: CatalogGroupDimension.slot,
          ),
          CatalogGroupOutlineEntry(
            key: 'Energy',
            label: 'Energy',
            count: 8,
            dimension: CatalogGroupDimension.slot,
          ),
          CatalogGroupOutlineEntry(
            key: 'Power',
            label: 'Power',
            count: 5,
            dimension: CatalogGroupDimension.slot,
          ),
        ],
      ),
    ),
  );
}

/// Outline jump expands collapsed group + scrolls (BR-CAT-007 view-only).
@widgetbook.UseCase(
  name: 'Outline jump · expand-on-jump + scroll',
  type: CatalogGroupOutlineRail,
  path: '[Catalog]/Group',
)
Widget groupOutlineJumpExpand(BuildContext context) {
  return const _OutlineJumpExpandDemo();
}

class _OutlineJumpExpandDemo extends StatefulWidget {
  const _OutlineJumpExpandDemo();

  @override
  State<_OutlineJumpExpandDemo> createState() => _OutlineJumpExpandDemoState();
}

class _OutlineJumpExpandDemoState extends State<_OutlineJumpExpandDemo> {
  late final List<WeaponFamily> _families;
  late final List<CatalogFamilyGroupNode> _tree;
  late final Map<String, GlobalKey> _anchors;
  final _scrollController = ScrollController();
  var _collapsed = <String>{};
  String? _active;
  static const _dims = [
    CatalogGroupDimension.slot,
    CatalogGroupDimension.element,
  ];

  @override
  void initState() {
    super.initState();
    _families = [
      midnightCoupFamily(),
      ribbontailFamily(),
      groupWeaponFamilies([kUnsworn]).single,
      groupWeaponFamilies([kAceOfSpades]).single,
      groupWeaponFamilies([
        kMidnightCoupBase.copyWith(
          hash: 701,
          name: 'Gizmo Weft',
          itemTypeName: 'Grenade Launcher',
          element: 'Strand',
          slot: 'Kinetic',
        ),
      ]).single,
    ];
    _families.addAll([
      groupWeaponFamilies([
        const CatalogItem(
          hash: 801,
          name: 'Duty Bound',
          slot: 'Kinetic',
          element: 'Kinetic',
          ammo: 'Primary',
          frame: 'Adaptive Frame',
          itemTypeName: 'Auto Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single,
      groupWeaponFamilies([
        const CatalogItem(
          hash: 901,
          name: 'The Epicurean',
          slot: 'Energy',
          element: 'Void',
          ammo: 'Special',
          frame: 'Precision Frame',
          itemTypeName: 'Fusion Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single,
      groupWeaponFamilies([
        const CatalogItem(
          hash: 902,
          name: 'Cartesian Coordinate',
          slot: 'Energy',
          element: 'Solar',
          ammo: 'Special',
          frame: 'Rapid-Fire Frame',
          itemTypeName: 'Fusion Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single,
      groupWeaponFamilies([
        const CatalogItem(
          hash: 1001,
          name: 'Hammerhead',
          slot: 'Power',
          element: 'Void',
          ammo: 'Heavy',
          frame: 'Adaptive Frame',
          itemTypeName: 'Machine Gun',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single,
    ]);
    _tree = groupWeaponFamilyBrowseNested(_families, _dims);
    _anchors = {
      for (final row in flattenAllFamilyGroupNodes(_tree))
        row.node.key: GlobalKey(),
    };
    // Collapse Energy (+ children) so JUMP must expand ancestors.
    _collapsed = {
      for (final n in _tree)
        if (n.label != 'Kinetic') n.key,
    };
    _active = _tree.isNotEmpty ? _tree.first.key : null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle(String key) {
    setState(() {
      if (_collapsed.contains(key)) {
        _collapsed = {..._collapsed}..remove(key);
      } else {
        _collapsed = {..._collapsed, key};
      }
    });
  }

  void _jump(String key) {
    if (isCatalogGroupPathFullyOpen(key, _collapsed)) {
      setState(() {
        _collapsed = {..._collapsed, key};
        _active = key;
      });
      return;
    }
    setState(() {
      _active = key;
      final next = {..._collapsed};
      for (final a in catalogGroupAncestorKeys(key)) {
        next.remove(a);
      }
      next.remove(key);
      _collapsed = next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchors[key]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          alignment: 0.05,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 900,
      height: 560,
      child: Row(
        key: const Key('wb_outline_jump_demo'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CatalogWeaponsGrid(
              families: _families,
              familyTree: _tree,
              groupDimensions: _dims,
              collapsedGroupKeys: _collapsed,
              onToggleGroup: _toggle,
              groupKeys: _anchors,
              scrollController: _scrollController,
              onActiveGroupChanged: (k) {
                if (_active != k) setState(() => _active = k);
              },
              onSelectFamily: (_) {},
            ),
          ),
          CatalogGroupOutlineRail(
            groups: [
              for (final row in flattenAllFamilyGroupNodes(_tree))
                CatalogGroupOutlineEntry(
                  key: row.node.key,
                  label: row.node.label,
                  count: row.node.count,
                  depth: row.depth,
                  dimension: catalogGroupDimensionAt(_dims, row.depth),
                  collapsedHint: _collapsed.contains(row.node.key),
                ),
            ],
            activeKey: _active,
            onJump: _jump,
          ),
        ],
      ),
    );
  }
}

@widgetbook.UseCase(
  name: 'Nested Slot→Element · icons',
  type: CatalogGroupHeader,
  path: '[Catalog]/Group',
)
Widget groupNestedHeadersIcons(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CatalogGroupHeader(
        groupKey: 'Energy',
        label: 'Energy',
        count: 5,
        dimension: CatalogGroupDimension.slot,
        expanded: true,
        onToggle: () {},
      ),
      CatalogGroupHeader(
        groupKey: 'Energy · Solar',
        label: 'Solar',
        count: 2,
        depth: 1,
        dimension: CatalogGroupDimension.element,
        expanded: true,
        onToggle: () {},
      ),
      CatalogGroupHeader(
        groupKey: 'Energy · Arc',
        label: 'Arc',
        count: 1,
        depth: 1,
        dimension: CatalogGroupDimension.element,
        expanded: false,
        onToggle: () {},
      ),
    ],
  );
}

