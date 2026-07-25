import 'package:destiny2_web_host/db/web_db_status.dart';
import 'package:destiny2_web_host/pages/settings_page.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  group('SettingsPage DB status', () {
    testComponents('shows blocked banner and role when blocked', (tester) async {
      tester.pumpComponent(
        const SettingsPage(
          dbStatus: WebDbSessionStatus(
            phase: WebDbPhase.ready,
            role: WebDbRole.blocked,
          ),
        ),
      );

      expect(find.text(SettingsPage.blockedBannerText), findsOneComponent);
      expect(find.textContaining('Role: blocked'), findsOneComponent);
      expect(find.textContaining('another tab holds the writer'), findsOneComponent);
      expect(find.text(SettingsPage.helloText), findsOneComponent);
    });

    testComponents('shows writer ready status and storage', (tester) async {
      tester.pumpComponent(
        const SettingsPage(
          dbStatus: WebDbSessionStatus(
            phase: WebDbPhase.ready,
            role: WebDbRole.writer,
            storageImplementation: 'opfsLocks',
          ),
        ),
      );

      expect(find.text(SettingsPage.writerReadyHint), findsOneComponent);
      expect(find.textContaining('Role: writer'), findsOneComponent);
      expect(find.textContaining('Storage: opfsLocks'), findsOneComponent);
      expect(find.textContaining('ready (writer)'), findsOneComponent);
    });

    testComponents('shows single-tab writer policy copy', (tester) async {
      tester.pumpComponent(
        const SettingsPage(
          dbStatus: WebDbSessionStatus(
            phase: WebDbPhase.ready,
            role: WebDbRole.writer,
            storageImplementation: 'inMemory',
          ),
        ),
      );

      expect(find.textContaining('Single-tab writer'), findsComponents);
      expect(find.textContaining('No Next.js'), findsOneComponent);
      expect(find.textContaining('D-WEB-DB'), findsOneComponent);
    });
  });
}
