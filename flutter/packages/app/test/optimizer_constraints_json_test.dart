import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('optimizer_constraints_json', () {
    test('parse null/empty → null', () {
      expect(parseOptimizerConstraints(null), isNull);
      expect(parseOptimizerConstraints(''), isNull);
      expect(parseOptimizerConstraints('   '), isNull);
    });

    test('round-trip minimal constraints', () {
      final c = ArmorSetOptimizerConstraints(
        lockedExoticItemHash: 42,
        preferReuse: true,
        statPriorities: const [ArmorStatName.melee, ArmorStatName.health],
        statThresholds: const {ArmorStatName.melee: 80},
      );
      final raw = serializeOptimizerConstraints(c);
      final parsed = parseOptimizerConstraints(raw);
      expect(parsed, isNotNull);
      expect(parsed!.lockedExoticItemHash, 42);
      expect(parsed.preferReuse, isTrue);
      expect(parsed.statPriorities, [ArmorStatName.melee, ArmorStatName.health]);
      expect(parsed.statThresholds![ArmorStatName.melee], 80);
      expect(hasOptimizerConstraintsPayload(parsed), isTrue);
    });

    test('invalid json → null', () {
      expect(parseOptimizerConstraints('{not json'), isNull);
    });

    test('seedConstraintsFromBuild', () {
      final seeded = seedConstraintsFromBuild(
        exoticArmorHash: 99,
        softStatTargets: {'Melee': 70},
      );
      expect(seeded.lockedExoticItemHash, 99);
      expect(seeded.statThresholds![ArmorStatName.melee], 70);
    });
  });
}
