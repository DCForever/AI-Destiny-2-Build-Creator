import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'host_bootstrap.dart';
import 'settings/settings_page.dart';
import 'theme/flap_theme.dart';

/// Root Flutter app for the mobile host.
///
/// **UX rebuild baseline:** Settings only (full body). No bottom nav until a
/// second area (e.g. Catalog) returns — Material [NavigationBar] requires ≥2
/// destinations. Appearance: Neon void / Cool technical.
class Destiny2MobileApp extends StatefulWidget {
  const Destiny2MobileApp({
    super.key,
    required this.services,
  });

  final MobileAppServices services;

  @override
  State<Destiny2MobileApp> createState() => _Destiny2MobileAppState();
}

class _Destiny2MobileAppState extends State<Destiny2MobileApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(brightness: Brightness.light),
      darkTheme: buildFlapTheme(brightness: Brightness.dark),
      themeMode: _themeMode,
      home: Scaffold(
        key: const Key('mobile_shell'),
        backgroundColor: Colors.transparent,
        body: NeonShellBackground(
          showHorizon: false,
          child: SettingsPage(
            key: const Key('settings_page'),
            services: widget.services,
            themeMode: _themeMode,
            onThemeModeChanged: (m) => setState(() => _themeMode = m),
          ),
        ),
        // Bottom nav returns when a second destination (e.g. Catalog) lands.
        // Key kept offstage-free; tests assert absence during baseline.
      ),
    );
  }
}
