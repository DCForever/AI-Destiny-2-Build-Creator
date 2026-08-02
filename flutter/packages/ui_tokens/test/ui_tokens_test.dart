import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:test/test.dart';

void main() {
  group('dark Neon Network colors', () {
    test('void / surface / raised / rules', () {
      expect(kFlapBackgroundDark, 0xFF05050F);
      expect(kFlapSurfaceDark, 0xFF0A0A18);
      expect(kFlapSurfaceRaisedDark, 0xFF101028);
      expect(kFlapLineDark, 0x38E8EEF2);
      expect(kFlapLineStrongDark, 0x61E8EEF2);
      expect(FlapColorTokens.dark.background, kFlapBackgroundDark);
      expect(FlapColorTokens.dark.surface, kFlapSurfaceDark);
    });

    test('lettering + cyan-neon signal + status lamps', () {
      expect(kFlapForegroundDark, 0xFFF0FDFF);
      expect(kFlapMutedDark, 0xFF7DD3E0);
      expect(kFlapAccentDark, 0xFF00E5FF);
      expect(kFlapAccentStrongDark, 0xFF00B8D4);
      expect(kFlapAccentDimDark, 0x2600E5FF);
      expect(kFlapDangerDark, 0xFFFF003C);
      expect(kFlapSuccessDark, 0xFF2EE6A6);
      expect(kFlapWarningDark, 0xFFF5C542);
      expect(kFlapAccentSecondaryDark, 0xFFFF1A8C);
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
      expect(argbToCssHex(kFlapAccentDark), '#00e5ff');
      expect(argbToCssHex(kFlapBackgroundDark), '#05050f');
      expect(argbToCssHex(kFlapAccentDimDark), '#00e5ff26');
    });

    test('rarity wash tokens match Neon catalog kit', () {
      expect(kRarityExotic, 0xFFCEAE33);
      expect(kRarityLegendary, 0xFF522F65);
      expect(kRarityLegendaryEdge, 0xFFA178C4);
    });
  });

  group('light cool technical stage colors', () {
    test('cool neutrals + cyan signal chrome', () {
      expect(FlapColorTokens.light.background, 0xFFF4F7FB);
      expect(FlapColorTokens.light.surface, 0xFFFFFFFF);
      expect(FlapColorTokens.light.surfaceRaised, 0xFFEEF2F7);
      expect(FlapColorTokens.light.line, 0x240A0A18);
      expect(FlapColorTokens.light.foreground, 0xFF0A0A18);
      expect(FlapColorTokens.light.muted, 0xFF4A5A68);
      expect(FlapColorTokens.light.accent, 0xFF00C4DB);
      expect(FlapColorTokens.light.accentStrong, 0xFF00A8BC);
      expect(FlapColorTokens.light.accentDim, 0x1F00C4DB);
      expect(FlapColorTokens.light.success, 0xFF2EE6A6);
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

    test('named column templates for sets / synergy / builds', () {
      expect(kFlapLibraryColumnTemplates, hasLength(3));

      final sets = flapColumnTemplateById('sets');
      expect(sets.columnsCss, isNotEmpty);
      expect(sets.cellRoles, contains(FlapCellRole.name));
      expect(sets.headerLabels, contains('Name'));

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
