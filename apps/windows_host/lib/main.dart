import 'package:flutter/material.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'config/local_env.dart';
import 'host_bootstrap.dart';
import 'theme/flap_theme.dart';

/// Public Bungie API key only (optional). Never CLIENT_SECRET.
const String _bungieApiKeyDefine = String.fromEnvironment('BUNGIE_API_KEY');

/// Public OAuth client id only. Never CLIENT_SECRET / BUNGIE_CLIENT_SECRET.
const String _bungieClientIdDefine = String.fromEnvironment('BUNGIE_CLIENT_ID');

/// Windows loopback redirect URI registered on the Public Bungie app.
const String _bungieRedirectUriDefine = String.fromEnvironment(
  'BUNGIE_REDIRECT_URI',
  defaultValue: kDefaultWindowsRedirectUri,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registers bundled sqlite3 for Drift on Windows (and other Flutter targets).
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

  // Runtime file (gitignored) so MCP / IDE launches work without dart-define.
  // Non-empty --dart-define still wins.
  final fileEnv = loadWindowsLocalEnv();
  final apiKey = resolveConfigValue(
    define: _bungieApiKeyDefine,
    fileEnv: fileEnv,
    key: 'BUNGIE_API_KEY',
  );
  final clientId = resolveConfigValue(
    define: _bungieClientIdDefine,
    fileEnv: fileEnv,
    key: 'BUNGIE_CLIENT_ID',
  );
  final redirectUri = resolveConfigValue(
    define: _bungieRedirectUriDefine,
    fileEnv: fileEnv,
    key: 'BUNGIE_REDIRECT_URI',
    fallback: kDefaultWindowsRedirectUri,
  );

  debugPrint(
    'OAuth config: clientIdLen=${clientId.length} '
    'apiKeyLen=${apiKey.length} redirect=$redirectUri',
  );

  AppServices? services;
  Object? bootstrapError;

  try {
    services = await HostBootstrap.open(
      apiKey: apiKey.isEmpty ? null : apiKey,
      clientId: clientId,
      redirectUri: redirectUri,
    );
  } catch (e, st) {
    bootstrapError = e;
    debugPrint('Host bootstrap failed: $e\n$st');
  }

  runApp(
    bootstrapError != null || services == null
        ? _BootstrapErrorApp(error: bootstrapError ?? 'Unknown bootstrap error')
        : Destiny2WindowsApp(services: services),
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destiny 2 Build Creator',
      theme: buildFlapTheme(brightness: Brightness.light),
      darkTheme: buildFlapTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
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
