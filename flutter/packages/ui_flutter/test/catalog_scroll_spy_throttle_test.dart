import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogScrollSpyThrottle (GAP-PERF-02)', () {
    testWidgets('coalesces rapid updates to leading + trailing', (tester) async {
      var probes = 0;
      final throttle = CatalogScrollSpyThrottle(
        interval: const Duration(milliseconds: 80),
        onProbe: () => probes++,
      );
      addTearDown(throttle.dispose);

      // Leading probe fires immediately.
      throttle.onScrollUpdate();
      expect(probes, 1);

      // Burst inside quiet window → trailing only.
      throttle.onScrollUpdate();
      throttle.onScrollUpdate();
      throttle.onScrollUpdate();
      expect(probes, 1);

      await tester.pump(const Duration(milliseconds: 80));
      expect(probes, 2);

      // No further updates → no extra probe after next window.
      await tester.pump(const Duration(milliseconds: 80));
      expect(probes, 2);
    });

    testWidgets('flush forces immediate probe and clears trailing',
        (tester) async {
      var probes = 0;
      final throttle = CatalogScrollSpyThrottle(
        interval: const Duration(milliseconds: 80),
        onProbe: () => probes++,
      );
      addTearDown(throttle.dispose);

      throttle.onScrollUpdate();
      expect(probes, 1);
      throttle.onScrollUpdate(); // trailing pending
      throttle.flush(); // scroll end
      expect(probes, 2);

      await tester.pump(const Duration(milliseconds: 80));
      // Trailing was cleared by flush — no third probe.
      expect(probes, 2);
    });

    testWidgets('dispose cancels pending timer', (tester) async {
      var probes = 0;
      final throttle = CatalogScrollSpyThrottle(
        interval: const Duration(milliseconds: 80),
        onProbe: () => probes++,
      );

      throttle.onScrollUpdate();
      throttle.onScrollUpdate();
      throttle.dispose();
      await tester.pump(const Duration(milliseconds: 100));
      expect(probes, 1);
    });
  });
}
