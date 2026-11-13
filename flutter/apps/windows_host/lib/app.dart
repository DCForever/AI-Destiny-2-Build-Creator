import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'builds_mock/builds_mock_page.dart';
import 'catalog/catalog_page.dart';
import 'host_bootstrap.dart';
import 'sets/sets_library_page.dart';
import 'settings/settings_page.dart';
import 'theme/flap_theme.dart';
import 'warlock/warlock_builds_page.dart';

/// Root Flutter app for the Windows host.
///
/// **UX rebuild shell:** Catalog + **Sets** (Armor MVP implement) + read-only
/// Warlock builds + Builds (Warlock matrix list) + Settings.
/// Loadouts / Build / Synergy return via the area UX redesign loop.
/// Appearance: **Neutral stage** light (default) + **Neutral charcoal** dark.
class Destiny2WindowsApp extends StatefulWidget {
  const Destiny2WindowsApp({
    super.key,
    required this.services,
    this.warlockMatrixPath,
  });

  final AppServices services;

  /// Test inject: when non-null, used as the matrix path (skips saved/env).
  /// Production leaves this null so Settings saved path → env → none applies.
  final String? warlockMatrixPath;

  /// Primary nav labels (product order subset until full shell returns).
  static const List<String> navLabels = [
    'Catalog',
    'Sets',
    'Warlocks',
    'Builds',
    'Settings',
  ];

  static const int catalogNavIndex = 0;
  static const int setsNavIndex = 1;
  static const int warlockBuildsNavIndex = 2;
  static const int buildsMockNavIndex = 3;
  static const int settingsNavIndex = 4;

  @override
  State<Destiny2WindowsApp> createState() => _Destiny2WindowsAppState();
}

class _Destiny2WindowsAppState extends State<Destiny2WindowsApp> {
  int _index = Destiny2WindowsApp.catalogNavIndex;
  ThemeMode _themeMode = ThemeMode.light;

  /// Bumped when Catalog is re-selected so IndexedStack reloads after Settings sync.
  int _catalogReloadToken = 0;

  /// Bumped when the Warlock matrix path is saved so Builds/Warlocks remount.
  int _matrixReloadToken = 0;

  /// Path from `{StorageRoot}/settings/warlock_matrix_path.txt`, if any.
  String? _savedMatrixPath;

  @override
  void initState() {
    super.initState();
    _loadSavedMatrixPath();
  }

  Future<void> _loadSavedMatrixPath() async {
    try {
      final saved = await WarlockMatrixPathSetting(
        root: widget.services.storageRoot,
      ).load();
      if (!mounted) return;
      setState(() => _savedMatrixPath = saved);
    } catch (_) {
      // Prefer env / none when the preference file is unreadable.
      if (!mounted) return;
      setState(() => _savedMatrixPath = null);
    }
  }

  void _onMatrixPathSaved(String? path) {
    setState(() {
      _savedMatrixPath = path;
      _matrixReloadToken++;
    });
  }

  void _onDestinationSelected(int i) {
    setState(() {
      if (i == Destiny2WindowsApp.catalogNavIndex &&
          _index != Destiny2WindowsApp.catalogNavIndex) {
        _catalogReloadToken++;
      }
      _index = i;
    });
  }

  /// Precedence: test inject → saved Settings path → WARLOCK_MATRIX_PATH → none.
  String? get _matrixPath {
    final override = widget.warlockMatrixPath;
    if (override != null) return override;
    return resolveWarlockMatrixPath(
      savedSetting: _savedMatrixPath,
      environment: Platform.environment,
    );
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
                    icon: Icon(Icons.construction_outlined),
                    selectedIcon: Icon(Icons.construction),
                    label: Text('Builds'),
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
                    KeyedSubtree(
                      key: ValueKey<String>(
                        'warlock_builds_matrix_$_matrixReloadToken',
                      ),
                      child: WarlockBuildsPage(
                        key: const Key('warlock_builds_page'),
                        initialPath: _matrixPath,
                      ),
                    ),
                    KeyedSubtree(
                      key: ValueKey<String>(
                        'builds_mock_matrix_$_matrixReloadToken',
                      ),
                      child: BuildsMockPage(
                        key: const Key('builds_mock_page_host'),
                        storageRoot: widget.services.storageRoot,
                        warlockMatrixPath: _matrixPath,
                      ),
                    ),
                    SettingsPage(
                      key: const Key('settings_page'),
                      services: widget.services,
                      themeMode: _themeMode,
                      onThemeModeChanged: (m) => setState(() => _themeMode = m),
                      onWarlockMatrixPathSaved: _onMatrixPathSaved,
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
