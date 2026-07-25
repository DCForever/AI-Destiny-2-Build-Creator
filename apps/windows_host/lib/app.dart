import 'package:flutter/material.dart';

import 'host_bootstrap.dart';
import 'settings/settings_page.dart';

/// Root Flutter app for the Windows host skeleton.
class Destiny2WindowsApp extends StatelessWidget {
  const Destiny2WindowsApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4F72),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: SettingsPage(services: services),
    );
  }
}
