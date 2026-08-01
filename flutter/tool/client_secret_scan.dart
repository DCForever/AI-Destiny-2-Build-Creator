// Client secret source scan (DART-058 / GAP-AUTH-01 / RC-AUTH / RC-SECRETS).
//
//   dart run tool/client_secret_scan.dart
//
// Exit 0 only when Flutter/Jaspr client package+host lib trees contain no
// confidential secret assignment or secret fromEnvironment keys.
//
// Allowed: documentation phrases like "Never pass CLIENT_SECRET" without
// assignment/fromEnvironment.

import 'dart:io';

/// Relative client roots scanned from workspace root.
const List<String> kClientScanRoots = [
  'packages/bungie/lib',
  'packages/app/lib',
  'packages/domain/lib',
  'packages/db/lib',
  'packages/manifest/lib',
  'packages/storage/lib',
  'packages/sandbox_data/lib',
  'packages/ui_tokens/lib',
  'packages/ui_flutter/lib',
  'apps/windows_host/lib',
  'apps/web_host/lib',
  'apps/mobile_host/lib',
];

/// File suffixes included in the scan.
const List<String> kClientScanExtensions = ['.dart', '.yaml', '.yml'];

/// Assignment / map-key style confidential secrets (must not appear).
final RegExp kForbiddenSecretAssign = RegExp(
  r'''(?:BUNGIE_CLIENT_SECRET|SESSION_SECRET|clientSecret)\s*[:=]|'''
  r'''['"]client_secret['"]\s*:|'''
  r'''\bclient_secret\s*[:=]''',
  caseSensitive: false,
);

/// Compile-time env keys that must never load secrets into clients.
final RegExp kForbiddenSecretFromEnvironment = RegExp(
  r'''fromEnvironment\(\s*['"](?:BUNGIE_CLIENT_SECRET|CLIENT_SECRET|SESSION_SECRET)['"]''',
);

/// Process env / dart-define documentation of secret keys as values is OK when
/// only mentioned in "never" prose; forbid explicit defines of secrets:
final RegExp kForbiddenDartDefineSecret = RegExp(
  r'''--dart-define\s*=\s*(?:BUNGIE_CLIENT_SECRET|SESSION_SECRET)\s*=''',
  caseSensitive: false,
);

/// One scan hit.
class ClientSecretScanFinding {
  ClientSecretScanFinding({
    required this.path,
    required this.line,
    required this.snippet,
    required this.pattern,
  });

  final String path;
  final int line;
  final String snippet;
  final String pattern;

  @override
  String toString() => '$path:$line [$pattern] $snippet';
}

/// Finds Dart workspace root (dir with packages/bungie), including nested
/// `flutter/` under the monorepo root (DART-069).
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 12; i++) {
    final candidate = Directory('${dir.path}/packages/bungie');
    if (candidate.existsSync()) {
      return dir;
    }
    final nested = Directory('${dir.path}/flutter/packages/bungie');
    if (nested.existsSync()) {
      return Directory('${dir.path}/flutter');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

/// Returns true when a line is documentation-only mention of secrets.
bool isDocumentationOnlySecretMention(String line) {
  final lower = line.toLowerCase();
  final isProse = lower.contains('never') ||
      lower.contains('no client_secret') ||
      lower.contains('no `client_secret`') ||
      lower.contains('without client_secret') ||
      lower.contains('not') && lower.contains('secret') ||
      lower.contains('//') && lower.contains('secret') ||
      lower.contains('///') ||
      lower.trimLeft().startsWith('*') ||
      lower.trimLeft().startsWith('//') ||
      lower.trimLeft().startsWith('#') ||
      lower.contains('must not') ||
      lower.contains('do not') ||
      lower.contains('don\'t') ||
      lower.contains('forbidden') ||
      lower.contains('omit') ||
      lower.contains('scan');
  // Doc comments and strings that only warn about secrets.
  if (line.trimLeft().startsWith('//') ||
      line.trimLeft().startsWith('///') ||
      line.trimLeft().startsWith('*') ||
      line.trimLeft().startsWith('#')) {
    return true;
  }
  // Soft-guidance / UX strings that say "No CLIENT_SECRET".
  if (RegExp(
        r'''['"].*(?:never|no)\s+(?:pass\s+)?(?:CLIENT_SECRET|client_secret|SESSION_SECRET)''',
        caseSensitive: false,
      ).hasMatch(line) &&
      !kForbiddenSecretFromEnvironment.hasMatch(line) &&
      !RegExp(r'''BUNGIE_CLIENT_SECRET\s*=\s*\S+''').hasMatch(line)) {
    return true;
  }
  return isProse &&
      !kForbiddenSecretFromEnvironment.hasMatch(line) &&
      !RegExp(r'''(?:BUNGIE_CLIENT_SECRET|SESSION_SECRET)\s*=\s*['"]?\w+''')
          .hasMatch(line);
}

/// Scan a single file body; returns findings (empty = clean).
List<ClientSecretScanFinding> scanClientSecretText(
  String path,
  String content,
) {
  final findings = <ClientSecretScanFinding>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (isDocumentationOnlySecretMention(line)) {
      // Still flag fromEnvironment of secrets even in comments? No — comments OK.
      continue;
    }
    if (kForbiddenSecretFromEnvironment.hasMatch(line)) {
      findings.add(
        ClientSecretScanFinding(
          path: path,
          line: i + 1,
          snippet: line.trim(),
          pattern: 'fromEnvironment-secret',
        ),
      );
      continue;
    }
    if (kForbiddenDartDefineSecret.hasMatch(line)) {
      findings.add(
        ClientSecretScanFinding(
          path: path,
          line: i + 1,
          snippet: line.trim(),
          pattern: 'dart-define-secret',
        ),
      );
      continue;
    }
    if (kForbiddenSecretAssign.hasMatch(line)) {
      findings.add(
        ClientSecretScanFinding(
          path: path,
          line: i + 1,
          snippet: line.trim(),
          pattern: 'secret-assign',
        ),
      );
    }
  }
  return findings;
}

/// Walk client roots under [workspaceRoot] and collect findings.
List<ClientSecretScanFinding> scanClientSecrets({
  Directory? workspaceRoot,
  List<String>? roots,
}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final scanRoots = roots ?? kClientScanRoots;
  final findings = <ClientSecretScanFinding>[];

  for (final rel in scanRoots) {
    final dir = Directory('${root.path}/$rel'.replaceAll('/', Platform.pathSeparator));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      final lower = path.toLowerCase();
      final okExt = kClientScanExtensions.any((e) => lower.endsWith(e));
      if (!okExt) continue;
      // Skip generated / build noise if any under lib (rare).
      if (lower.contains('${Platform.pathSeparator}build${Platform.pathSeparator}')) {
        continue;
      }
      final content = entity.readAsStringSync();
      final relPath = path
          .replaceFirst(root.path, '')
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^/'), '');
      findings.addAll(scanClientSecretText(relPath, content));
    }
  }
  return findings;
}

/// CLI entry: exit 0 when clean.
int runClientSecretScan({Directory? workspaceRoot}) {
  final findings = scanClientSecrets(workspaceRoot: workspaceRoot);
  if (findings.isEmpty) {
    stdout.writeln(
      'Client secret scan OK: no BUNGIE_CLIENT_SECRET / SESSION_SECRET '
      'assignment in client lib trees.',
    );
    return 0;
  }
  stderr.writeln('Client secret scan FAILED (${findings.length} hit(s)):');
  for (final f in findings) {
    stderr.writeln('  $f');
  }
  return 1;
}

void main(List<String> args) {
  exit(runClientSecretScan());
}
