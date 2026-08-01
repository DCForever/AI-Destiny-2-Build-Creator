import 'dart:io';

import 'package:test/test.dart';

import '../proc06_thinning_gate.dart';

void main() {
  group('validateProc06ThinningGate (repo)', () {
    test('workspace gate passes', () {
      final result = validateProc06ThinningGate();
      expect(result.ok, isTrue, reason: result.errors.join('\n'));
      expect(result.checklistExists, isTrue);
      expect(result.missingChecklistMarkers, isEmpty);
      expect(result.skillExists, isTrue);
      expect(result.missingSkillMarkers, isEmpty);
      expect(result.featureGapsExists, isTrue);
    });

    test('runProc06ThinningGate returns 0', () {
      expect(runProc06ThinningGate(), 0);
    });
  });

  group('missingMarkers', () {
    test('reports each absent marker', () {
      const stub = '# empty';
      final missing = missingMarkers(stub, kProc06ChecklistMarkers);
      expect(missing, containsAll(kProc06ChecklistMarkers));
    });

    test('empty when all markers present', () {
      final buf = StringBuffer();
      for (final m in kProc06ChecklistMarkers) {
        buf.writeln(m);
      }
      expect(missingMarkers(buf.toString(), kProc06ChecklistMarkers), isEmpty);
    });
  });

  group('checklist file', () {
    test('contains enforcement markers', () {
      final root = findWorkspaceRoot();
      final text = File(
        '${root.path}/$kProc06ChecklistRelativePath',
      ).readAsStringSync();
      for (final m in kProc06ChecklistMarkers) {
        expect(text, contains(m), reason: 'missing $m');
      }
    });
  });
}
