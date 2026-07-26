import 'package:flutter/material.dart';

import 'builds/builds_library_page.dart';
import 'catalog/catalog_page.dart';
import 'host_bootstrap.dart';
import 'loadouts/loadouts_page.dart';
import 'sets/sets_library_page.dart';
import 'settings/settings_page.dart';
import 'synergies/synergies_library_page.dart';
import 'theme/flap_theme.dart';

/// Root Flutter app for the Windows host (DART-019…039 + DART-055 Loadouts).
///
/// Shell destinations: Catalog + Sets + Synergies + Builds + Loadouts + Settings.
/// Appearance: **Cold Graphite** dark + **Paper Ledger** light ([ThemeMode]).
class Destiny2WindowsApp extends StatefulWidget {
  const Destiny2WindowsApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  /// Primary nav destination labels (tests / greps — DART-055).
  static const List<String> navLabels = [
    'Catalog',
    'Sets',
    'Synergies',
    'Builds',
    'Loadouts',
    'Settings',
  ];

  @override
  State<Destiny2WindowsApp> createState() => _Destiny2WindowsAppState();
}

class _Destiny2WindowsAppState extends State<Destiny2WindowsApp> {
  int _index = 0;
  ThemeMode _themeMode = ThemeMode.system;

  /// Bumped when Catalog is re-selected so IndexedStack does not keep a stale
  /// empty load from before Settings manifest/inventory sync (BUG-20260725-001).
  int _catalogReloadToken = 0;

  void _onDestinationSelected(int i) {
    setState(() {
      // Catalog is index 0 and stays mounted under IndexedStack — reload when
      // returning from another destination so entity stores + inventory join.
      if (i == 0 && _index != 0) {
        _catalogReloadToken++;
      }
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      // MaterialApp: theme=light face, darkTheme=dark face.
      theme: buildFlapTheme(brightness: Brightness.light),
      darkTheme: buildFlapTheme(brightness: Brightness.dark),
      themeMode: _themeMode,
      home: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              key: const Key('host_nav_rail'),
              selectedIndex: _index,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Catalog'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.layers_outlined),
                  selectedIcon: Icon(Icons.layers),
                  label: Text('Sets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub),
                  label: Text('Synergies'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.construction_outlined),
                  selectedIcon: Icon(Icons.construction),
                  label: Text('Builds'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.playlist_add_check_outlined),
                  selectedIcon: Icon(Icons.playlist_add_check),
                  label: Text('Loadouts'),
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
                    reloadToken: _catalogReloadToken,
                  ),
                  SetsLibraryPage(
                    key: const Key('sets_library_page'),
                    services: widget.services,
                  ),
                  SynergiesLibraryPage(
                    key: const Key('synergies_library_page'),
                    services: widget.services,
                  ),
                  BuildsLibraryPage(
                    key: const Key('builds_library_page'),
                    services: widget.services,
                  ),
                  LoadoutsPage(
                    key: const Key('loadouts_page'),
                    services: widget.services,
                  ),
                  SettingsPage(
                    key: const Key('settings_page'),
                    services: widget.services,
                    themeMode: _themeMode,
                    onThemeModeChanged: (m) => setState(() => _themeMode = m),
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
