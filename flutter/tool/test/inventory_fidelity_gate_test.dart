import 'dart:io';

import 'package:test/test.dart';

import '../inventory_fidelity/markers.dart';
import '../inventory_fidelity_gate.dart';

void main() {
  group('validateInventoryFidelityGate (repo)', () {
    test('workspace gate passes', () {
      final result = validateInventoryFidelityGate();
      expect(result.ok, isTrue, reason: result.errors.join('\n'));
      expect(result.docExists, isTrue);
      expect(result.missingMarkers, isEmpty);
      expect(result.fixturesExist, isTrue);
      expect(result.compareResult?.ok, isTrue);
    });

    test('runInventoryFidelityGate returns 0', () {
      expect(runInventoryFidelityGate(), 0);
    });
  });

  group('missingHarnessDocMarkers', () {
    test('reports each absent marker', () {
      const stub = '# empty';
      final missing = missingHarnessDocMarkers(stub);
      expect(missing, containsAll(kInventoryHarnessRequiredMarkers));
    });

    test('empty when all markers present', () {
      final buf = StringBuffer();
      for (final m in kInventoryHarnessRequiredMarkers) {
        buf.writeln(m);
      }
      expect(missingHarnessDocMarkers(buf.toString()), isEmpty);
    });
  });

  group('gate separation from p0', () {
    test('gate source documents PROC-05 separation', () {
      final root = findWorkspaceRoot();
      final gateSrc = File(
        '${root.path}/tool/inventory_fidelity_gate.dart',
      ).readAsStringSync();
      expect(gateSrc, contains('p0_parity_gate'));
      expect(gateSrc, contains('PROC-05'));
      // Gate must not shell out to pure domain suite (docs may mention
      // p0_parity_gate.dart by name for separation guidance).
      expect(gateSrc, isNot(contains('run_all_pure_tests')));
      expect(gateSrc, isNot(contains("import 'p0_parity_gate")));
      expect(gateSrc, isNot(contains('runGraphGuard')));
      expect(gateSrc, isNot(contains('Process.run')));
      expect(gateSrc, isNot(contains('Process.start')));
    });
  });

  group('validateInventoryFidelityGate isolation', () {
    test('fails when doc missing in temp root', () {
      final tmp = Directory.systemTemp.createTempSync('inv-fid-gate-');
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      });
      final result = validateInventoryFidelityGate(workspaceRoot: tmp);
      expect(result.ok, isFalse);
      expect(result.docExists, isFalse);
      expect(result.errors, isNotEmpty);
    });
  });
}
