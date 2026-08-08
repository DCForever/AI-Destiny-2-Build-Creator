import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

/// Mobile structure-only: list → push detail (Catalog push deferred product path).
@widgetbook.UseCase(
  name: 'List → push detail (phone frame)',
  type: CatalogWeaponsGrid,
  path: '[Catalog]/Mobile',
)
Widget mobileListPushDetail(BuildContext context) {
  return const _MobileCatalogShell();
}

@widgetbook.UseCase(
  name: 'Detail full-screen (phone frame)',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Mobile',
)
Widget mobileDetailFull(BuildContext context) {
  final family = midnightCoupFamily();
  return _phoneFrame(
    CatalogWeaponDetail(
      item: family.cardItem,
      instances: multiPowerInstances(itemHash: family.cardItem.hash),
      showCanRoll: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      familyMembers: family.members,
      onSelectFamilyMember: (_) {},
    ),
  );
}

/// Optional viewport knob via Widgetbook ViewportAddon when present; fixed phone here.
Widget _phoneFrame(Widget child) {
  return Center(
    child: Container(
      width: 390,
      height: 720,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

class _MobileCatalogShell extends StatefulWidget {
  const _MobileCatalogShell();

  @override
  State<_MobileCatalogShell> createState() => _MobileCatalogShellState();
}

class _MobileCatalogShellState extends State<_MobileCatalogShell> {
  final _navKey = GlobalKey<NavigatorState>();

  List<WeaponFamily> get _families => [
        midnightCoupFamily(),
        ribbontailFamily(),
        groupWeaponFamilies([kUnsworn]).single,
        groupWeaponFamilies([kAceOfSpades]).single,
      ];

  @override
  Widget build(BuildContext context) {
    return _phoneFrame(
      Navigator(
        key: _navKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (ctx) {
              final args = settings.arguments;
              if (settings.name == '/detail' && args is WeaponFamily) {
                final family = args;
                return Scaffold(
                  appBar: AppBar(
                    title: Text(family.displayName),
                    leading: BackButton(
                      onPressed: () => _navKey.currentState?.pop(),
                    ),
                  ),
                  body: CatalogWeaponDetail(
                    item: family.cardItem,
                    instances:
                        multiPowerInstances(itemHash: family.cardItem.hash),
                    showCanRoll: false,
                    craftAvailable: false,
                    definitionSocketPlugs: kDefinitionSocketPlugs,
                    plugNameByHash: kPlugNameByHash,
                    plugIconByHash: kPlugIconByHash,
                    familyMembers: family.members,
                    onSelectFamilyMember: (_) {},
                  ),
                );
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Catalog')),
                body: CatalogWeaponsGrid(
                  families: _families,
                  showOwned: true,
                  onSelectFamily: (f) {
                    _navKey.currentState?.pushNamed('/detail', arguments: f);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
