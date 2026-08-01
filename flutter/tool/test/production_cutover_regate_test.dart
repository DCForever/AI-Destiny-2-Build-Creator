import 'dart:io';

import 'package:test/test.dart';

import '../production_cutover/markers.dart';
import '../production_cutover_regate.dart';

void main() {
  group('validateProductionCutoverRegate (repo)', () {
    test('canonical docs pass re-gate after DART-061', () {
      final result = validateProductionCutoverRegate();
      expect(
        result.ok,
        isTrue,
        reason: result.errors.join('\n'),
      );
      expect(result.cutoverExists, isTrue);
      expect(result.missingVerdict, isEmpty);
      expect(result.missingRcPass, isEmpty);
      expect(result.branchingExists, isTrue);
      expect(result.gapsExist, isTrue);
    });

    test('runProductionCutoverRegate returns 0 for workspace', () {
      expect(runProductionCutoverRegate(), 0);
    });
  });

  group('missingVerdictMarkers', () {
    test('reports absent GO verdicts', () {
      const stub = 'PROGRAM_GATE: GO\nPRODUCTION_CUTOVER: NO-GO\n';
      final missing = missingVerdictMarkers(stub);
      expect(missing, contains('PRODUCTION_CUTOVER: GO'));
    });

    test('empty when both GO', () {
      const ok = 'PROGRAM_GATE: GO\nPRODUCTION_CUTOVER: GO\n';
      expect(missingVerdictMarkers(ok), isEmpty);
    });
  });

  group('missingRcPassStatuses', () {
    test('flags FAIL status row', () {
      final content = StringBuffer()
        ..writeln('| ID | Criterion | Pass | Evidence | Status |')
        ..writeln('| **RC-BRANCH** | merge policy | after GO | branching | **FAIL** |');
      for (final rc in kRetirementCriteria) {
        if (rc == 'RC-BRANCH') continue;
        content.writeln(
          '| **$rc** | x | y | z | **PASS** |',
        );
      }
      final missing = missingRcPassStatuses(content.toString());
      expect(
        missing.any((m) => m.contains('RC-BRANCH')),
        isTrue,
      );
    });

    test('accepts all PASS rows', () {
      final content = StringBuffer();
      for (final rc in kRetirementCriteria) {
        content.writeln('| **$rc** | criterion | pass | evidence | **PASS** |');
      }
      expect(missingRcPassStatuses(content.toString()), isEmpty);
    });
  });

  group('missingGoEvidenceMarkers', () {
    test('reports each absent marker', () {
      expect(
        missingGoEvidenceMarkers('# empty'),
        containsAll(kCutoverGoEvidenceMarkers),
      );
    });
  });

  group('missingBranchingMarkers', () {
    test('requires merge-after-GO markers', () {
      expect(
        missingBranchingMarkers('# no policy'),
        containsAll(kBranchingPolicyRequiredMarkers),
      );
      final ok = StringBuffer();
      for (final m in kBranchingPolicyRequiredMarkers) {
        ok.writeln(m);
      }
      expect(missingBranchingMarkers(ok.toString()), isEmpty);
    });
  });

  group('missingFeatureGapsMarkers', () {
    test('requires cutover gap markers and closed status', () {
      expect(
        missingFeatureGapsMarkers('# no gaps'),
        containsAll(kFeatureGapsCutoverMarkers),
      );
      final ok = StringBuffer()
        ..writeln('GAP-CUT-01')
        ..writeln('closed')
        ..writeln('GAP-FEAT-02')
        ..writeln('DART-061')
        ..writeln('dim.gg')
        ..writeln('jsonOnly');
      expect(missingFeatureGapsMarkers(ok.toString()), isEmpty);
    });
  });

  group('validateProductionCutoverRegate (temp fail)', () {
    test('fails on empty temp workspace', () {
      final tmp = Directory.systemTemp.createTempSync('prod_cutover_');
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      });
      final result = validateProductionCutoverRegate(workspaceRoot: tmp);
      expect(result.ok, isFalse);
      expect(result.errors, isNotEmpty);
    });
  });
}
