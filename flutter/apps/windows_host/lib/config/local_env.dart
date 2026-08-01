import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Loads gitignored desktop credentials from `.env.windows.local`.
///
/// Search order (first file that exists):
/// 1. `<cwd>/.env.windows.local`
/// 2. `<cwd>/apps/windows_host/.env.windows.local` (when launched from monorepo root)
/// 3. Executable directory / parent (packaged or `build/.../runner/Debug`)
///
/// Never logs secret values. Compile-time `--dart-define` values should still
/// take precedence when non-empty.
Map<String, String> loadWindowsLocalEnv() {
  final candidates = <String>[
    p.join(Directory.current.path, '.env.windows.local'),
    p.join(Directory.current.path, 'apps', 'windows_host', '.env.windows.local'),
  ];

  try {
    final exe = Platform.resolvedExecutable;
    final exeDir = p.dirname(exe);
    candidates.add(p.join(exeDir, '.env.windows.local'));
    // Debug runner: .../build/windows/x64/runner/Debug → walk up to package root
    candidates.add(p.normalize(p.join(exeDir, '..', '..', '..', '..', '..', '.env.windows.local')));
    candidates.add(p.normalize(p.join(exeDir, '..', '..', '..', '..', '..', '..', '.env.windows.local')));
  } catch (_) {}

  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final map = _parseDotEnv(file.readAsStringSync());
      debugPrint('local_env: loaded ${map.keys.join(", ")} from $path');
      return map;
    } catch (e) {
      debugPrint('local_env: failed to read $path: $e');
    }
  }
  debugPrint('local_env: no .env.windows.local found (cwd=${Directory.current.path})');
  return const {};
}

Map<String, String> _parseDotEnv(String contents) {
  final out = <String, String>{};
  for (final raw in contents.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final i = line.indexOf('=');
    if (i < 1) continue;
    final key = line.substring(0, i).trim();
    var value = line.substring(i + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) out[key] = value;
  }
  return out;
}

/// Prefer non-empty [define], else map value, else [fallback].
String resolveConfigValue({
  required String define,
  required Map<String, String> fileEnv,
  required String key,
  String fallback = '',
}) {
  if (define.trim().isNotEmpty) return define.trim();
  final fromFile = fileEnv[key]?.trim() ?? '';
  if (fromFile.isNotEmpty) return fromFile;
  return fallback;
}
