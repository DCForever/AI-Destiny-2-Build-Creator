import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:test/test.dart';

void main() {
  group('dark neutral charcoal colors', () {
    test('void / surface / raised / rules', () {
      expect(kFlapBackgroundDark, 0xFF121212);
      expect(kFlapSurfaceDark, 0xFF1E1E1E);
      expect(kFlapSurfaceRaisedDark, 0xFF2A2A2A);
      expect(kFlapLineDark, 0x38FFFFFF);
      expect(kFlapLineStrongDark, 0x61FFFFFF);
      expect(FlapColorTokens.dark.background, kFlapBackgroundDark);
      expect(FlapColorTokens.dark.surface, kFlapSurfaceDark);
    });

    test('lettering + grey signal + status lamps', () {
      expect(kFlapForegroundDark, 0xFFF5F5F5);
      expect(kFlapMutedDark, 0xFFA3A3A3);
      expect(kFlapAccentDark, 0xFFE0E0E0);
      expect(kFlapAccentStrongDark, 0xFFFFFFFF);
      expect(kFlapAccentDimDark, 0x26E0E0E0);
      expect(kFlapDangerDark, 0xFFFF003C);
      expect(kFlapSuccessDark, 0xFF2EE6A6);
      expect(kFlapWarningDark, 0xFFF5C542);
      expect(kFlapAccentSecondaryDark, 0xFF8A8A8A);
      // One lamp: success must not equal accent.
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
      expect(argbToCssHex(kFlapAccentDark), '#e0e0e0');
      expect(argbToCssHex(kFlapBackgroundDark), '#121212');
      expect(argbToCssHex(kFlapAccentDimDark), '#e0e0e026');
    });

    test('rarity wash tokens keep exotic gold', () {
      expect(kRarityExotic, 0xFFCEAE33);
      expect(kRarityLegendary, 0xFF522F65);
      expect(kRarityLegendaryEdge, 0xFFA178C4);
    });
  });

  group('light neutral stage colors', () {
    test('whites / greys / black ink + charcoal chrome', () {
      expect(FlapColorTokens.light.background, 0xFFF5F5F5);
      expect(FlapColorTokens.light.surface, 0xFFFFFFFF);
      expect(FlapColorTokens.light.surfaceRaised, 0xFFEEEEEE);
      expect(FlapColorTokens.light.line, 0x29000000);
      expect(FlapColorTokens.light.foreground, 0xFF111111);
      expect(FlapColorTokens.light.muted, 0xFF595959);
      expect(FlapColorTokens.light.accent, 0xFF1A1A1A);
      expect(FlapColorTokens.light.accentStrong, 0xFF000000);
      expect(FlapColorTokens.light.accentDim, 0x1F1A1A1A);
      expect(FlapColorTokens.light.success, 0xFF166534);
      // Dark success lamp unchanged.
      expect(FlapColorTokens.dark.success, 0xFF2EE6A6);
      expect(FlapColorTokens.light.success, isNot(FlapColorTokens.dark.success));
      expect(FlapColorTokens.light.danger, 0xFFFF003C);
      expect(FlapColorTokens.light.warning, 0xFFF5C542);
      expect(FlapColorTokens.light.background, isNot(kFlapBackgroundDark));
    });
  });

  group('spacing + square radii', () {
    test('density scale and panel pads', () {
      expect(kSpace2, 2);
      expect(kSpace12, 12);
      expect(kSpace32, 32);
      expect(kSpace48, 48);
      expect(kControlHeight, 40);
      expect(kPanelPadMd, 12);
      expect(kPageY, 12);
      expect(FlapSpacing.flapGap, 0);
      expect(kFlapGap, 0);
    });

    test('radii are zero default with soft max 2', () {
      expect(kFlapRadius, 0);
      expect(kContainerRadius, 0);
      expect(kControlRadius, 0);
      expect(kRadiusMax, 2);
      expect(kRadiusHardCap, 4);
      expect(FlapRadii.flap, 0);
      expect(FlapRadii.none, 0);
    });
  });

  group('typography metrics', () {
    test('family names and board roles', () {
      expect(kFontDisplay, contains('Orbitron'));
      expect(kFontBody, contains('Inter'));
      expect(kFontMono, contains('JetBrains'));
      expect(kTypeLabel.fontWeight, 600);
      expect(kTypeBody.fontSize, 13);
    });
  });

  group('FlapBoard layout contracts', () {
    test('rail width 320 and row gap 0', () {
      expect(kFlapLibraryRailWidth, 320);
      expect(kFlapBoardRowGap, 0);
      expect(FlapBoardLayout.libraryRailWidth, 320);
      expect(FlapBoardLayout.rowGap, 0);
    });

    test('named column templates for sets / armor / synergy / builds', () {
      // Measured: kFlapLibraryColumnTemplates includes sets-armor (G-SET flap).
      expect(kFlapLibraryColumnTemplates, hasLength(4));

      final sets = flapColumnTemplateById('sets');
      expect(sets.columnsCss, isNotEmpty);
      expect(sets.cellRoles, contains(FlapCellRole.name));
      expect(sets.headerLabels, contains('Name'));

      final setsArmor = flapColumnTemplateById('sets-armor');
      expect(setsArmor.columnsCss, isNotEmpty);
      expect(setsArmor.cellRoles, [
        FlapCellRole.name,
        FlapCellRole.identity,
        FlapCellRole.tally,
        FlapCellRole.meta,
        FlapCellRole.status,
      ]);
      expect(setsArmor.headerLabels, ['Name', 'Class', 'Pcs', 'Cover', 'Used']);

      final synergy = flapColumnTemplateById('synergy');
      expect(synergy.cellRoles, contains(FlapCellRole.identity));
      expect(synergy.headerLabels, contains('Design'));

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
