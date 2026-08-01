/// Structural baseline for modularization work (post audit implementation).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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

  group('M1: shared formatters live in destiny2_app', () {
    test('package owns soft guidance + equip + dim formatters', () {
      final soft = _read(
        'packages/app/lib/src/presentation/soft_guidance_format.dart',
      );
      expect(soft, contains('kSoftGuidanceAdvisoryCaption'));
      expect(soft, contains('coverageTierToneKey'));
      final equip =
          _read('packages/app/lib/src/presentation/equip_format.dart');
      expect(equip, contains('canEnableEquipCta'));
      final dim =
          _read('packages/app/lib/src/presentation/dim_export_format.dart');
      expect(dim, contains('canEnableDimExportCta'));
    });

    test('host soft_guidance files re-export package (not independent impl)',
        () {
      for (final path in [
        'apps/windows_host/lib/builds/soft_guidance_format.dart',
        'apps/web_host/lib/compose/soft_guidance_format.dart',
        'apps/mobile_host/lib/builds/soft_guidance_format.dart',
      ]) {
        final src = _read(path);
        expect(src, contains("export 'package:destiny2_app/destiny2_app.dart'"));
        expect(src.contains('coverageTierToneKey('), isFalse,
            reason: 'no local function body in $path');
      }
    });
  });

  group('M2: equip session shared core', () {
    test('EquipSession exists and host controllers wrap it', () {
      final session = _read('packages/app/lib/src/equip/equip_session.dart');
      expect(session, contains('class EquipSession'));
      expect(session, contains('confirmGapsAndEquip'));
      final win = _read('apps/windows_host/lib/equip/equip_controller.dart');
      expect(win, contains('EquipSession'));
      final web = _read('apps/web_host/lib/equip/equip_controller.dart');
      expect(web, contains('EquipSession'));
    });
  });

  group('U1/U2: UI kit placement', () {
    test('ItemRichnessPanel lives in ui_flutter', () {
      final panel =
          _read('packages/ui_flutter/lib/src/item_richness.dart');
      expect(panel, contains('class ItemRichnessPanel'));
      final catalog = _read('apps/windows_host/lib/catalog/catalog_page.dart');
      expect(catalog, contains('ItemRichnessPanel'));
    });

    test('LibraryWorkspace used by three library pages', () {
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

    test('builds library page is split into part files', () {
      expect(
        File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page_rail.dart'))
            .existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page_compose.dart'))
            .existsSync(),
        isTrue,
      );
      final main = _read('apps/windows_host/lib/builds/builds_library_page.dart');
      expect(main, contains("part 'builds_library_page_rail.dart'"));
    });
  });

  group('compose session', () {
    test('BuildsComposeSession exported from package', () {
      final src =
          _read('packages/app/lib/src/builds/builds_compose_session.dart');
      expect(src, contains('class BuildsComposeSession'));
      expect(src, contains('attachSet'));
      expect(src, contains('pinSlot'));
      expect(src, contains('refreshSoftCoverage'));
      expect(src, contains('saveSoftStatTargets'));
      expect(src, contains('selectVariant'));
    });

    test('mobile/windows/web thin-wrap BuildsComposeSession for compose', () {
      final mobile =
          _read('apps/mobile_host/lib/builds/builds_controller.dart');
      final windows =
          _read('apps/windows_host/lib/builds/builds_library_controller.dart');
      final web = _read('apps/web_host/lib/builds/builds_controller.dart');

      for (final entry in {
        'mobile': mobile,
        'windows': windows,
        'web': web,
      }.entries) {
        final src = entry.value;
        final host = entry.key;
        expect(src, contains('BuildsComposeSession'), reason: host);
        expect(src, contains('core.attachSet'), reason: host);
        expect(src, contains('core.pinSlot'), reason: host);
        expect(src, contains('core.refreshSoftCoverage'), reason: host);
        expect(src, contains('core.saveSoftStatTargets'), reason: host);
        expect(src, contains('core.selectVariant'), reason: host);
        // Compose state machine must not be reimplemented with private fields.
        expect(src, isNot(contains('List<AttachmentView> _attachments')),
            reason: host);
        expect(src, isNot(contains('List<SlotPinView> _slotPins')),
            reason: host);
        expect(src, isNot(contains('CoverageQueryResult? _coverage')),
            reason: host);
      }

      // View models live in package code; hosts re-export, not redefine.
      expect(mobile, isNot(contains('class DraftSynergyType')));
      expect(windows, isNot(contains('class DraftSynergyType')));
      expect(web, isNot(contains('class DraftSynergyType')));
      expect(mobile, isNot(contains('class SlotPinView')));
      expect(windows, isNot(contains('class SlotPinView')));
      expect(web, isNot(contains('class SlotPinView')));
      expect(mobile, isNot(contains('class AttachmentView {')));
      expect(windows, isNot(contains('class AttachmentView {')));
      expect(web, isNot(contains('class AttachmentView {')));
    });
  });
}
