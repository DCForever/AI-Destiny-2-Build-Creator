import 'package:destiny2_web_host/builds/builds_page.dart';
import 'package:destiny2_web_host/components/shell_header.dart';
import 'package:destiny2_web_host/sets/sets_page.dart';
import 'package:destiny2_web_host/synergies/synergies_page.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

void main() {
  group('ShellHeader compose spine nav', () {
    test('routes match AppShell short labels and order (DART-068)', () {
      final labels = ShellHeader.routes.map((r) => r.label).toList();
      expect(
        labels,
        [
          'Loadouts',
          'Build',
          'Synergy',
          'Sets',
          'Catalog',
          'Settings',
        ],
      );
      final paths = ShellHeader.routes.map((r) => r.path).toList();
      expect(
        paths,
        [
          '/loadouts',
          '/builds',
          '/synergies',
          '/sets',
          '/catalog',
          '/',
        ],
      );
    });

    testComponents('renders nav labels', (tester) async {
      tester.pumpComponent(
        Router(
          routes: [
            Route(
              path: '/',
              builder: (context, state) => const ShellHeader(),
            ),
          ],
        ),
      );
      expect(find.text('Catalog'), findsOneComponent);
      expect(find.text('Build'), findsOneComponent);
      expect(find.text('Sets'), findsOneComponent);
      expect(find.text('Synergy'), findsOneComponent);
      expect(find.text('Loadouts'), findsOneComponent);
      expect(find.text('Settings'), findsOneComponent);
    });
  });


  group('compose pages titles without services', () {
    testComponents('Sets blocked state', (tester) async {
      tester.pumpComponent(const SetsPage());
      expect(find.text(SetsPage.titleText), findsOneComponent);
    });

    testComponents('Synergies blocked state', (tester) async {
      tester.pumpComponent(const SynergiesPage());
      expect(find.text(SynergiesPage.titleText), findsOneComponent);
    });

    testComponents('Builds blocked state', (tester) async {
      tester.pumpComponent(const BuildsPage());
      expect(find.text(BuildsPage.titleText), findsOneComponent);
    });
  });
}
