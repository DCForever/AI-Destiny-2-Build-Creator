import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('isTagBlockedBySynergyTypeVocab', () {
    test('blocks synergy type wires', () {
      expect(isTagBlockedBySynergyTypeVocab('verb'), isTrue);
      expect(isTagBlockedBySynergyTypeVocab('Verb'), isTrue);
      expect(isTagBlockedBySynergyTypeVocab('melee'), isTrue);
      expect(isTagBlockedBySynergyTypeVocab('Element'), isTrue);
    });

    test('allows free tags', () {
      expect(isTagBlockedBySynergyTypeVocab('raid'), isFalse);
      expect(isTagBlockedBySynergyTypeVocab('pve'), isFalse);
      expect(isTagBlockedBySynergyTypeVocab('GM'), isFalse);
    });
  });

  group('filterTagsAgainstSynergyTypeVocab', () {
    test('splits accepted vs blocked', () {
      final r = filterTagsAgainstSynergyTypeVocab(const [
        'raid',
        'verb',
        'pve',
        'Melee',
        'raid',
      ]);
      expect(r.accepted, ['raid', 'pve']);
      expect(r.blocked, ['verb', 'Melee']);
      expect(r.hasBlocked, isTrue);
    });
  });
}
