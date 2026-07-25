import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:test/test.dart';

void main() {
  group('dark Cold Graphite colors', () {
    test('void / surface / raised / rules', () {
      expect(kFlapBackgroundDark, 0xFF070B10);
      expect(kFlapSurfaceDark, 0xFF0E1319);
      expect(kFlapSurfaceRaisedDark, 0xFF141A22);
      expect(kFlapLineDark, 0xFF1F2733);
      expect(kFlapLineStrongDark, 0xFF2A3342);
      expect(FlapColorTokens.dark.background, kFlapBackgroundDark);
      expect(FlapColorTokens.dark.surface, kFlapSurfaceDark);
    });

    test('lettering + cyan-teal readiness + status lamps', () {
      expect(kFlapForegroundDark, 0xFFE4EAF2);
      expect(kFlapMutedDark, 0xFF8492A6);
      expect(kFlapAccentDark, 0xFF4EC4BC);
      expect(kFlapAccentStrongDark, 0xFF6FD4CD);
      expect(kFlapAccentDimDark, 0x244EC4BC);
      expect(kFlapDangerDark, 0xFFE05A52);
      expect(kFlapSuccessDark, 0xFF5CBC8E);
      expect(kFlapWarningDark, 0xFFC9A84A);
      // One Lamp: success must not equal accent.
      expect(kFlapSuccessDark, isNot(kFlapAccentDark));
    });

    test('Destiny element ink (dark board)', () {
      expect(kElementKineticDark, 0xFFFFFFFF);
      expect(kElementArcDark, 0xFF85C5EC);
      expect(kElementSolarDark, 0xFFF2721B);
      expect(kElementVoidDark, 0xFFB184C5);
      expect(kElementStasisDark, 0xFF4D88FF);
      expect(kElementStrandDark, 0xFF35E366);
      expect(kElementPrismaticDark, 0xFFD67EE2);
      expect(FlapColorTokens.dark.elementArc, kElementArcDark);
    });

    test('argbToCssHex formats opaque and dim accent', () {
      expect(argbToCssHex(kFlapAccentDark), '#4ec4bc');
      expect(argbToCssHex(kFlapBackgroundDark), '#070b10');
      expect(argbToCssHex(kFlapAccentDimDark), '#4ec4bc24');
    });
  });

  group('light Paper Ledger colors', () {
    test('cream neutrals + rubber-stamp amber', () {
      expect(FlapColorTokens.light.background, 0xFFEBE6DB);
      expect(FlapColorTokens.light.surface, 0xFFF7F3EA);
      expect(FlapColorTokens.light.surfaceRaised, 0xFFFFFDF7);
      expect(FlapColorTokens.light.line, 0xFFC4BBA8);
      expect(FlapColorTokens.light.foreground, 0xFF1A1B1F);
      expect(FlapColorTokens.light.muted, 0xFF5A5F6A);
      expect(FlapColorTokens.light.accent, 0xFF9A6418);
      expect(FlapColorTokens.light.accentStrong, 0xFF7A4E12);
      expect(FlapColorTokens.light.accentDim, 0x1F9A6418);
      expect(FlapColorTokens.light.success, 0xFF1A6E3F);
      expect(FlapColorTokens.light.danger, 0xFFB53A2A);
      expect(FlapColorTokens.light.warning, 0xFF8F6510);
      expect(FlapColorTokens.light.background, isNot(kFlapBackgroundDark));
    });
  });

  group('spacing + square radii', () {
    test('density scale and panel pads', () {
      expect(kSpace2, 2);
      expect(kSpace12, 12);
      expect(kPanelPadMd, 12);
      expect(kPageY, 12);
      expect(FlapSpacing.flapGap, 0);
      expect(kFlapGap, 0);
    });

    test('all radii are zero (square board rule)', () {
      expect(kFlapRadius, 0);
      expect(kContainerRadius, 0);
      expect(kControlRadius, 0);
      expect(FlapRadii.flap, 0);
      expect(FlapRadii.none, 0);
    });
  });

  group('typography metrics', () {
    test('family names and board roles', () {
      expect(kFontDisplay, contains('Barlow'));
      expect(kFontBody, contains('IBM Plex Sans'));
      expect(kFontMono, contains('IBM Plex Mono'));
      expect(kTypeLabel.fontWeight, 600);
      expect(kTypeBody.fontSize, 15);
    });
  });

  group('FlapBoard layout contracts', () {
    test('rail width 320 and row gap 0', () {
      expect(kFlapLibraryRailWidth, 320);
      expect(kFlapBoardRowGap, 0);
      expect(FlapBoardLayout.libraryRailWidth, 320);
      expect(FlapBoardLayout.rowGap, 0);
    });

    test('named column templates for sets / synergy / builds', () {
      expect(kFlapLibraryColumnTemplates, hasLength(3));

      final sets = flapColumnTemplateById('sets');
      expect(sets.columnsCss, isNotEmpty);
      expect(sets.cellRoles, contains(FlapCellRole.name));
      expect(sets.headerLabels, contains('Name'));

      final synergy = flapColumnTemplateById('synergy');
      expect(synergy.cellRoles, contains(FlapCellRole.identity));
      expect(synergy.headerLabels, contains('Designation'));

      final builds = flapColumnTemplateById('builds');
      expect(builds.cellRoles, [
        FlapCellRole.name,
        FlapCellRole.identity,
        FlapCellRole.exotics,
        FlapCellRole.synergy,
        FlapCellRole.status,
      ]);
      expect(builds.headerLabels, hasLength(5));
      expect(builds.columnsCss, isNotEmpty);
    });

    test('unknown template id throws', () {
      expect(() => flapColumnTemplateById('nope'), throwsArgumentError);
    });
  });
}
