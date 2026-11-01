import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'catalog/catalog_page.dart';
import 'host_bootstrap.dart';
import 'sets/sets_library_page.dart';
import 'settings/settings_page.dart';
import 'theme/flap_theme.dart';
import 'warlock/warlock_builds_page.dart';

/// Root Flutter app for the Windows host.
///
/// **UX rebuild shell:** Catalog + **Sets** (Armor MVP implement) + read-only
/// Warlock builds + Settings.
/// Loadouts / Build / Synergy return via the area UX redesign loop.
/// Appearance: **Neon void** dark + **Cool technical** light ([ThemeMode]).
/// Design system tokens unchanged.
class Destiny2WindowsApp extends StatefulWidget {
  const Destiny2WindowsApp({
    super.key,
    required this.services,
    this.warlockMatrixPath,
  });

  final AppServices services;

  /// Overrides [warlockMatrixPathEnv]. Null reads the process environment.
  final String? warlockMatrixPath;

  /// Primary nav labels (product order subset until full shell returns).
  static const List<String> navLabels = [
    'Catalog',
    'Sets',
    'Warlocks',
    'Settings',
  ];

  static const int catalogNavIndex = 0;
  static const int setsNavIndex = 1;
  static const int warlockBuildsNavIndex = 2;
  static const int settingsNavIndex = 3;

  @override
  State<Destiny2WindowsApp> createState() => _Destiny2WindowsAppState();
}

class _Destiny2WindowsAppState extends State<Destiny2WindowsApp> {
  int _index = Destiny2WindowsApp.catalogNavIndex;
  ThemeMode _themeMode = ThemeMode.system;

  /// Bumped when Catalog is re-selected so IndexedStack reloads after Settings sync.
  int _catalogReloadToken = 0;

  void _onDestinationSelected(int i) {
    setState(() {
      if (i == Destiny2WindowsApp.catalogNavIndex &&
          _index != Destiny2WindowsApp.catalogNavIndex) {
        _catalogReloadToken++;
      }
      _index = i;
    });
  }

  String? get _matrixPath {
    final override = widget.warlockMatrixPath;
    if (override != null) return override;
    return warlockMatrixPathFromEnvironment(Platform.environment);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(brightness: Brightness.light),
      darkTheme: buildFlapTheme(brightness: Brightness.dark),
      themeMode: _themeMode,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: NeonShellBackground(
          child: Row(
            children: [
              NavigationRail(
                key: const Key('host_nav_rail'),
                selectedIndex: _index,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: Text('Catalog'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    selectedIcon: Icon(Icons.dashboard_customize),
                    label: Text('Sets'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: Text('Warlocks'),
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
                      onOpenSettings: () => _onDestinationSelected(
                        Destiny2WindowsApp.settingsNavIndex,
                      ),
                    ),
                    SetsLibraryPage(
                      key: const Key('sets_library_page'),
                      services: widget.services,
                    ),
                    WarlockBuildsPage(
                      key: const Key('warlock_builds_page'),
                      initialPath: _matrixPath,
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
      ),
    );
  }
}
