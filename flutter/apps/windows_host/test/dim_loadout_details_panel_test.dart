import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/dim_loadouts/dim_loadout_details_panel.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('missing file status shows quiet not-loaded line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: const Scaffold(
          body: DimLoadoutDetailsPanel(
            status: DimLoadoutsPanelStatus.notLoaded,
          ),
        ),
      ),
    );
    expect(find.text('DIM link details not loaded'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('loaded loadout shows plain-text ranking and notes', (
    tester,
  ) async {
    final parsed = parseCachedDimLoadouts(
      File(_fixturePath()).readAsStringSync(),
    );
    expect(parsed.isOk, isTrue);
    final loadout = parsed.loadouts.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DimLoadoutDetailsPanel(
              status: DimLoadoutsPanelStatus.loaded,
              loadout: loadout,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Contraverse Hold'), findsOneWidget);
    expect(find.textContaining('inferred'), findsWidgets);
    expect(find.textContaining('Grenade'), findsWidgets);
    expect(find.textContaining('matched:'), findsWidgets);
    expect(find.textContaining('grenade'), findsWidgets);
    expect(find.text('Vortex Grenade'), findsOneWidget);
    expect(find.text('Ashes to Assets'), findsOneWidget);
    expect(find.text('Void Siphon'), findsOneWidget);
    expect(
      find.textContaining('Stack grenade uptime'),
      findsOneWidget,
    );
    // No rich text / link widgets for untrusted notes.
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('from-link ranking labels constraints without matched words', (
    tester,
  ) async {
    final parsed = parseCachedDimLoadouts(
      File(_fixturePath()).readAsStringSync(),
    );
    final loadout = parsed.loadouts[1];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DimLoadoutDetailsPanel(
              status: DimLoadoutsPanelStatus.loaded,
              loadout: loadout,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('from link'), findsWidgets);
    expect(find.textContaining('#1 Melee'), findsOneWidget);
    expect(find.textContaining('matched:'), findsNothing);
  });
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    final candidate = File(
      '${dir.path}/packages/domain/test/fixtures/dim_loadouts_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/../../packages/domain/test/fixtures/dim_loadouts_min.json',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('dim_loadouts_min.json not found from ${Directory.current}');
}
