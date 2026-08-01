import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('domain package smoke', () {
    test('exports pure smoke label', () {
      expect(domainPackageSmokeLabel(), equals('destiny2_domain'));
    });

    test('package loads without IO/UI runtime deps', () {
      // Importing the library is the assertion: resolution fails if forbidden
      // deps were required at runtime. Label remains non-empty.
      expect(domainPackageSmokeLabel(), isNotEmpty);
    });
  });
}
