import 'dart:io';

import 'package:test/test.dart';

import '../dual_run_ops/markers.dart';
import '../dual_run_ops_gate.dart';

void main() {
  group('validateDualRunOpsGate (repo)', () {
    test('canonical runbook + shells + cutover pass', () {
      final result = validateDualRunOpsGate();
      expect(
        result.ok,
        isTrue,
        reason: result.errors.join('\n'),
      );
      expect(result.runbookExists, isTrue);
      expect(result.missingMarkers, isEmpty);
      expect(result.missingShells, isEmpty);
      expect(result.cutoverExists, isTrue);
    });

    test('runDualRunOpsGate returns 0 for workspace', () {
      expect(runDualRunOpsGate(), 0);
    });
  });

  group('missingRunbookMarkers', () {
    test('reports each absent marker', () {
      const stub = '# empty';
      final missing = missingRunbookMarkers(stub);
      expect(missing, containsAll(kDualRunRunbookRequiredMarkers));
    });

    test('empty when all markers present', () {
      final buf = StringBuffer();
      for (final m in kDualRunRunbookRequiredMarkers) {
        buf.writeln(m);
      }
      expect(missingRunbookMarkers(buf.toString()), isEmpty);
    });
  });

  group('missingShellPaths', () {
    test('reports missing under empty temp dir', () {
      final tmp = Directory.systemTemp.createTempSync('dual_run_ops_');
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      });
      final missing = missingShellPaths(tmp);
      expect(missing, containsAll(kDualRunShellRelativePaths));
    });
  });

  group('missingCutoverOpsMarkers', () {
    test('requires runbook filename and RC-OPS', () {
      expect(
        missingCutoverOpsMarkers('# no ops'),
        containsAll(kCutoverOpsEvidenceMarkers),
      );
      final ok = StringBuffer()
        ..writeln('RC-OPS')
        ..writeln('dual-run')
        ..writeln('multiplatform-dart-dual-run-rollback-runbook');
      expect(missingCutoverOpsMarkers(ok.toString()), isEmpty);
    });
  });
}
