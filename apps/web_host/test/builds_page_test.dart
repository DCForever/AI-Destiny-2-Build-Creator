import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_web_host/builds/builds_controller.dart';
import 'package:destiny2_web_host/builds/builds_page.dart';
import 'package:destiny2_web_host/compose/compose_services.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

void main() {
  group('BuildsPage', () {
    testComponents('blocked when no controller', (tester) async {
      tester.pumpComponent(const BuildsPage());
      expect(find.text(BuildsPage.titleText), findsOneComponent);
      expect(find.textContaining('writer tab'), findsComponents);
    });

    testComponents('renders create form with memory controller', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async => db.close());
      final services = ComposeServices(db: db);
      tester.pumpComponent(BuildsPage(controller: services.builds));
      expect(find.text(BuildsPage.titleText), findsOneComponent);
      expect(find.textContaining('Create build'), findsComponents);
      expect(find.textContaining('never auto-applies'), findsComponents);
    });
  });

  group('BuildsController binding', () {
    test('ComposeServices exposes three controllers on same db', () {
      final db = AppDatabase.memory();
      addTearDown(() async => db.close());
      final s = ComposeServices(db: db);
      expect(s.builds, isA<BuildsController>());
      expect(identical(s.builds.db, s.sets.db), isTrue);
    });
  });
}
