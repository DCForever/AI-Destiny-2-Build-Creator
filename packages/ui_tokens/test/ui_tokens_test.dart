import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:test/test.dart';

void main() {
  group('dark Matte Flap Ledger colors (DESIGN.md / globals.css)', () {
    test('void / surface / raised / rules', () {
      expect(kFlapBackgroundDark, 0xFF050608);
      expect(kFlapSurfaceDark, 0xFF0C0E12);
      expect(kFlapSurfaceRaisedDark, 0xFF12151C);
      expect(kFlapLineDark, 0xFF1C212C);
      expect(kFlapLineStrongDark, 0xFF2A3140);
      expect(FlapColorTokens.dark.background, kFlapBackgroundDark);
      expect(FlapColorTokens.dark.surface, kFlapSurfaceDark);
    });

    test('lettering + readiness amber + status lamps', () {
      expect(kFlapForegroundDark, 0xFFE8EAEF);
      expect(kFlapMutedDark, 0xFF8A93A6);
      expect(kFlapAccentDark, 0xFFE6B35C);
      expect(kFlapAccentStrongDark, 0xFFF0C878);
      expect(kFlapAccentDimDark, 0x24E6B35C);
      expect(kFlapDangerDark, 0xFFE2654F);
      expect(kFlapSuccessDark, 0xFF6FC28B);
      expect(kFlapWarningDark, 0xFFD9A93F);
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
      expect(argbToCssHex(kFlapAccentDark), '#e6b35c');
      expect(argbToCssHex(kFlapBackgroundDark), '#050608');
      expect(argbToCssHex(kFlapAccentDimDark), '#e6b35c24');
    });
  });

  group('light palette constants (future ThemeToggle)', () {
    test('paper neutrals exist and differ from dark void', () {
      expect(FlapColorTokens.light.background, 0xFFE8E6E1);
      expect(FlapColorTokens.light.surface, 0xFFF4F2EC);
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
