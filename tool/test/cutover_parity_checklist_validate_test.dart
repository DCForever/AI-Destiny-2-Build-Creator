import 'dart:io';

import 'package:test/test.dart';

import '../cutover_parity_checklist_validate.dart';

void main() {
  group('validateCutoverChecklist (repo doc)', () {
    test('canonical checklist passes structural validation', () {
      final result = validateCutoverChecklist();
      expect(
        result.ok,
        isTrue,
        reason: result.allErrors.join('\n'),
      );
      expect(result.exists, isTrue);
      expect(result.missingMarkers, isEmpty);
      expect(result.verdictErrors, isEmpty);
    });

    test('PROGRAM_GATE and PRODUCTION_CUTOVER are explicit GO or NO-GO', () {
      final root = findWorkspaceRoot();
      final content = File(
        '${root.path}/$kCutoverChecklistRelativePath',
      ).readAsStringSync();
      expect(kProgramGateLine.hasMatch(content), isTrue);
      expect(kProductionCutoverLine.hasMatch(content), isTrue);
    });
  });

  group('missingRequiredMarkers', () {
    test('reports each absent marker', () {
      const stub = '# empty';
      final missing = missingRequiredMarkers(stub);
      expect(missing, containsAll(kRequiredMarkers));
    });

    test('empty list when all markers present', () {
      final buf = StringBuffer()
        ..writeln('PROGRAM_GATE: GO')
        ..writeln('PRODUCTION_CUTOVER: NO-GO')
        ..writeln('## Product production nav parity')
        ..writeln('## Capability parity')
        ..writeln('## Next retirement criteria');
      for (final m in kRequiredMarkers) {
        // Ensure every marker appears (some already written).
        if (!buf.toString().contains(m)) {
          buf.writeln(m);
        }
      }
      expect(missingRequiredMarkers(buf.toString()), isEmpty);
    });
  });

  group('validateVerdictLines', () {
    test('accepts GO and NO-GO', () {
      expect(
        validateVerdictLines(
          'PROGRAM_GATE: GO\nPRODUCTION_CUTOVER: NO-GO\n',
        ),
        isEmpty,
      );
      expect(
        validateVerdictLines(
          'PROGRAM_GATE: NO-GO\nPRODUCTION_CUTOVER: GO\n',
        ),
        isEmpty,
      );
    });

    test('rejects missing or invalid values', () {
      final errors = validateVerdictLines('PROGRAM_GATE: MAYBE\n');
      expect(errors, isNotEmpty);
    });
  });

  group('runCutoverChecklistValidate', () {
    test('returns 0 for workspace root', () {
      expect(runCutoverChecklistValidate(), 0);
    });
  });
}
