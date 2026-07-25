import 'package:flutter/material.dart';

import 'builds/builds_controller.dart';
import 'builds/builds_list_page.dart';
import 'host_bootstrap.dart';
import 'settings/settings_page.dart';
import 'theme/flap_theme.dart';

/// Root Flutter app for the mobile host (DART-040).
///
/// Bottom nav: Builds | Settings. Builds uses nested [Navigator] for
/// Focus Swap (list XOR detail). Theme: Matte Flap Ledger.
class Destiny2MobileApp extends StatefulWidget {
  const Destiny2MobileApp({
    super.key,
    required this.services,
    this.buildsController,
  });

  final MobileAppServices services;

  /// Optional injectable controller (tests).
  final BuildsController? buildsController;

  @override
  State<Destiny2MobileApp> createState() => _Destiny2MobileAppState();
}

class _Destiny2MobileAppState extends State<Destiny2MobileApp> {
  int _index = 0;
  late final BuildsController _buildsController;
  bool _ownController = false;

  /// Nested navigator for Builds Focus Swap (list → detail push).
  final GlobalKey<NavigatorState> _buildsNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (widget.buildsController != null) {
      _buildsController = widget.buildsController!;
    } else {
      _ownController = true;
      _buildsController = BuildsController(db: widget.services.db);
    }
  }

  @override
  void dispose() {
    if (_ownController) {
      _buildsController.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int i) {
    if (i == _index) {
      // Re-tap Builds: pop to list root (Focus Swap reset).
      if (i == 0) {
        _buildsNavKey.currentState?.popUntil((r) => r.isFirst);
      }
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(),
      home: Scaffold(
        key: const Key('mobile_shell'),
        body: IndexedStack(
          index: _index,
          children: [
            // Focus Swap: nested navigator — list root XOR detail route.
            Navigator(
              key: _buildsNavKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => BuildsListPage(
                    controller: _buildsController,
                  ),
                );
              },
            ),
            SettingsPage(
              services: widget.services,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          key: const Key('mobile_bottom_nav'),
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              key: Key('nav_builds'),
              icon: Icon(Icons.construction_outlined),
              selectedIcon: Icon(Icons.construction),
              label: 'Builds',
            ),
            NavigationDestination(
              key: Key('nav_settings'),
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
