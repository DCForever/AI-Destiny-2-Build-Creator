import 'package:flutter/material.dart';

import 'catalog/catalog_page.dart';
import 'host_bootstrap.dart';
import 'settings/settings_page.dart';
import 'theme/flap_theme.dart';

/// Root Flutter app for the Windows host (DART-019/020/029).
///
/// Shell destinations: Catalog (offline) + Settings (manifest status).
/// Theme: Matte Flap Ledger stub (DART-029) — square flat cards, void canvas.
class Destiny2WindowsApp extends StatefulWidget {
  const Destiny2WindowsApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<Destiny2WindowsApp> createState() => _Destiny2WindowsAppState();
}

class _Destiny2WindowsAppState extends State<Destiny2WindowsApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(),
      home: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              key: const Key('host_nav_rail'),
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Catalog'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  CatalogPage(
                    key: const Key('catalog_page'),
                    services: widget.services,
                  ),
                  SettingsPage(
                    key: const Key('settings_page'),
                    services: widget.services,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
