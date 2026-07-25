import 'package:flutter/material.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'host_bootstrap.dart';
import 'theme/flap_theme.dart';

/// Public Bungie API key only (optional). Never CLIENT_SECRET.
const String _bungieApiKeyDefine = String.fromEnvironment('BUNGIE_API_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registers bundled sqlite3 for Drift on Android (and other Flutter targets).
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

  final apiKey = _bungieApiKeyDefine.isEmpty ? null : _bungieApiKeyDefine;

  MobileAppServices? services;
  Object? bootstrapError;

  try {
    services = await MobileHostBootstrap.open(apiKey: apiKey);
  } catch (e, st) {
    bootstrapError = e;
    debugPrint('Mobile host bootstrap failed: $e\n$st');
  }

  runApp(
    bootstrapError != null || services == null
        ? _BootstrapErrorApp(error: bootstrapError ?? 'Unknown bootstrap error')
        : Destiny2MobileApp(services: services),
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to open local storage/database:\n$error',
              key: const Key('bootstrap_error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
