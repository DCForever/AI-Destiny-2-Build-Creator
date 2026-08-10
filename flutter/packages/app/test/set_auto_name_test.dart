import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('buildArmorSetAutoNameBase', () {
    test('class · pc · family · tags', () {
      expect(
        buildArmorSetAutoNameBase(
          guardianClass: GuardianClass.titan,
          pcLabel: '2pc',
          familyLabel: 'TechSec',
          tags: const ['pve', 'raid'],
        ),
        'Titan · 2pc · TechSec · pve, raid',
      );
    });

    test('empty family becomes em dash', () {
      expect(
        buildArmorSetAutoNameBase(
          guardianClass: GuardianClass.hunter,
          pcLabel: '—',
          familyLabel: '',
        ),
        'Hunter · — · —',
      );
    });
  });

  group('labelsFromSetBonusGoals', () {
    test('empty → dashes', () {
      final l = labelsFromSetBonusGoals(const []);
      expect(l.pcLabel, '—');
      expect(l.familyLabel, '—');
    });

    test('1×4pc', () {
      final l = labelsFromSetBonusGoals(const [
        SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 4),
      ]);
      expect(l.pcLabel, '4pc');
      expect(l.familyLabel, 'TechSec');
    });

    test('2×2pc', () {
      final l = labelsFromSetBonusGoals(const [
        SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 2),
      ]);
      expect(l.pcLabel, '2+2pc');
      expect(l.familyLabel, 'A+B');
    });
  });

  group('resolveArmorSetName', () {
    test('blank preferred → auto-name', () {
      final name = resolveArmorSetName(
        guardianClass: GuardianClass.warlock,
        goals: const [
          SetBonusCoverageGoal(setBonusKey: 'Twofer', minPieces: 2),
        ],
      );
      expect(name, 'Warlock · 2pc · Twofer');
    });

    test('collision suffix', () {
      final name = resolveArmorSetName(
        guardianClass: GuardianClass.titan,
        preferredName: 'My Set',
        existingNames: const ['My Set', 'My Set 2'],
      );
      expect(name, 'My Set 3');
    });
  });
}
