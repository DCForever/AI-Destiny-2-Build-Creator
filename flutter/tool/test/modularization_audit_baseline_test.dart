/// Structural baseline for the modularization / shared-UI audit.
///
/// Locks path evidence: triple-hosted pure formatters, equip orchestration
/// twins, ItemRichness placement, and LibraryWorkspace adoption. Fails if
/// files move without updating the audit assumptions.
///
/// This is intentionally filesystem + symbol based (not a reimplementation of
/// product formatters). Behavior of formatters is covered by host
/// `*_format_test.dart` suites.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Resolve Melos workspace root (`flutter/`) by walking from CWD / script.
Directory get _workspaceRoot {
  Directory dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    final packages = Directory(p.join(dir.path, 'packages'));
    final apps = Directory(p.join(dir.path, 'apps'));
    if (pubspec.existsSync() && packages.existsSync() && apps.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('destiny2_build_creator_workspace') ||
          text.contains('workspace:')) {
        return dir;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  // Fallback: this file lives at flutter/tool/test/*.dart
  final scriptDir = File.fromUri(Platform.script).parent;
  return scriptDir.parent.parent;
}

String _read(String relative) {
  final f = File(p.join(_workspaceRoot.path, relative));
  expect(f.existsSync(), isTrue, reason: 'missing $relative');
  return f.readAsStringSync();
}

void main() {
  final root = _workspaceRoot;

  test('workspace root contains packages and three hosts', () {
    expect(Directory(p.join(root.path, 'packages')).existsSync(), isTrue);
    expect(
      Directory(p.join(root.path, 'apps', 'windows_host')).existsSync(),
      isTrue,
    );
    expect(
      Directory(p.join(root.path, 'apps', 'mobile_host')).existsSync(),
      isTrue,
    );
    expect(
      Directory(p.join(root.path, 'apps', 'web_host')).existsSync(),
      isTrue,
    );
  });

  group('M1: triple soft_guidance_format copies', () {
    const paths = [
      'apps/windows_host/lib/builds/soft_guidance_format.dart',
      'apps/web_host/lib/compose/soft_guidance_format.dart',
      'apps/mobile_host/lib/builds/soft_guidance_format.dart',
    ];

    test('each host defines caption + tone key + chip label', () {
      for (final path in paths) {
        final src = _read(path);
        expect(src, contains('kSoftGuidanceAdvisoryCaption'));
        expect(src, contains('coverageTierToneKey'));
        expect(src, contains('formatSynergyCoverageChipLabel'));
        expect(src, contains('formatSoftStatTargetsSummary'));
      }
    });

    test('caption string is identical across hosts', () {
      final captions = paths.map((path) {
        final src = _read(path);
        final match = RegExp(
          r"const String kSoftGuidanceAdvisoryCaption\s*=\s*'([^']*(?:'\\''[^']*)*)'\s*"
          r"(?:'([^']*)')?",
          multiLine: true,
        ).firstMatch(src);
        // Multi-line string concatenation: collect adjacent string literals
        // after the const name.
        final block = RegExp(
          r"kSoftGuidanceAdvisoryCaption\s*=\s*((?:'[^']*'\s*)+);",
          multiLine: true,
        ).firstMatch(src);
        expect(block, isNotNull, reason: 'caption block in $path');
        final parts = RegExp(r"'([^']*)'")
            .allMatches(block!.group(1)!)
            .map((m) => m.group(1)!)
            .join();
        // Silence unused if regex alternate path
        expect(match == null || match.groupCount >= 0, isTrue);
        return parts;
      }).toList();

      expect(captions[0], isNotEmpty);
      expect(captions[1], captions[0]);
      expect(captions[2], captions[0]);
      expect(captions[0], contains('never auto-applies'));
    });
  });

  group('M2: equip_controller win/web twin API', () {
    test('shared orchestration methods present on both hosts', () {
      for (final path in [
        'apps/windows_host/lib/equip/equip_controller.dart',
        'apps/web_host/lib/equip/equip_controller.dart',
      ]) {
        final src = _read(path);
        expect(src, contains('class EquipController'));
        for (final symbol in [
          'confirmGapsAndEquip',
          'requestEquip',
          'refreshReadiness',
          'canEnableEquipCta',
          'PendingEquipAction',
        ]) {
          expect(src, contains(symbol), reason: '$symbol in $path');
        }
      }
    });
  });

  group('U1/U2: UI kit placement', () {
    test('ItemRichnessPanel lives under windows_host widgets and is used by catalog',
        () {
      final panel = _read('apps/windows_host/lib/widgets/item_richness.dart');
      expect(panel, contains('class ItemRichnessPanel'));
      final catalog = _read('apps/windows_host/lib/catalog/catalog_page.dart');
      expect(catalog, contains('ItemRichnessPanel'));
    });

    test('LibraryWorkspace is defined in ui_flutter and used by three libraries',
        () {
      final kit =
          _read('packages/ui_flutter/lib/src/library_workspace.dart');
      expect(kit, contains('class LibraryWorkspace'));
      for (final path in [
        'apps/windows_host/lib/builds/builds_library_page.dart',
        'apps/windows_host/lib/sets/sets_library_page.dart',
        'apps/windows_host/lib/synergies/synergies_library_page.dart',
      ]) {
        expect(_read(path), contains('LibraryWorkspace'), reason: path);
      }
    });
  });

  group('M5: designation chrome SSoT', () {
    test('app package owns formatDesignationChrome; windows synergy wraps it',
        () {
      final app = _read('packages/app/lib/src/designation_chrome.dart');
      expect(app, contains('formatDesignationChrome'));
      expect(app, contains('designationWireKey'));
      final wrap =
          _read('apps/windows_host/lib/synergies/synergy_designation.dart');
      expect(wrap, contains('formatDesignationChrome'));
    });
  });
}
