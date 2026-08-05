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
  late final List<CatalogFamilyGroup> _groups;
  late final Map<String, GlobalKey> _anchors;
  final _scrollController = ScrollController();
  var _collapsed = <String>{};
  String? _active;

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
    // Force a few extra rows for scroll by duplicating display with different names.
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
          hash: 802,
          name: 'Scathelocke',
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
          hash: 803,
          name: 'Seventh Seraph Carbine',
          slot: 'Kinetic',
          element: 'Kinetic',
          ammo: 'Primary',
          frame: 'Precision Frame',
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
    _groups = groupWeaponFamilyBrowse(
      _families,
      const [CatalogGroupDimension.slot],
    );
    _anchors = {
      for (final g in _groups) g.key: GlobalKey(),
    };
    // Start with Energy + Power collapsed so jump must expand.
    _collapsed = {
      for (final g in _groups.skip(1)) g.key,
    };
    _active = _groups.isNotEmpty ? _groups.first.key : null;
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
    setState(() {
      _active = key;
      // Expand-on-jump (view-only; never rewrites filters).
      _collapsed = {..._collapsed}..remove(key);
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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                for (final g in _groups) ...[
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _anchors[g.key],
                      child: CatalogGroupHeader(
                        groupKey: g.key,
                        label: g.label,
                        count: g.families.length,
                        expanded: !_collapsed.contains(g.key),
                        onToggle: () => _toggle(g.key),
                      ),
                    ),
                  ),
                  if (!_collapsed.contains(g.key))
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      sliver: SliverGrid(
                        gridDelegate:
                            CatalogWeaponsGrid.gridDelegate,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final family = g.families[index];
                            return CatalogWeaponFamilyCard(
                              family: family,
                              showOwned: true,
                              onTap: () {},
                            );
                          },
                          childCount: g.families.length,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          CatalogGroupOutlineRail(
            groups: [
              for (final g in _groups)
                (key: g.key, label: g.label, count: g.families.length),
            ],
            activeKey: _active,
            onJump: _jump,
          ),
        ],
      ),
    );
  }
}

