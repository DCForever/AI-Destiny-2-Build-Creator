import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_windows_host/builds_mock/apply_move_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Move and equip accepts; Cancel rejects', (tester) async {
    ApplyMoveConfirmResult? accepted;
    ApplyMoveConfirmResult? cancelled;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Column(
              children: [
                TextButton(
                  key: const Key('open_accept'),
                  onPressed: () async {
                    accepted = await showApplyMoveConfirmDialog(
                      context: context,
                      moves: const [
                        ApplyMovePreview(
                          itemId: 'h',
                          itemLabel: 'Helmet A',
                          fromLabel: 'Vault',
                          toLabel: 'Warlock',
                        ),
                      ],
                      targetLabel: 'Warlock 2010 · …4821',
                    );
                  },
                  child: const Text('open'),
                ),
                TextButton(
                  key: const Key('open_cancel'),
                  onPressed: () async {
                    cancelled = await showApplyMoveConfirmDialog(
                      context: context,
                      moves: const [
                        ApplyMovePreview(
                          itemId: 'h',
                          itemLabel: 'Helmet A',
                          fromLabel: 'Vault',
                          toLabel: 'Warlock',
                        ),
                      ],
                    );
                  },
                  child: const Text('open cancel'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('apply_move_confirm_dialog')), findsOneWidget);
    expect(find.textContaining('Helmet A'), findsOneWidget);
    expect(find.text('Move and equip'), findsOneWidget);
    await tester.tap(find.byKey(const Key('apply_move_confirm_accept')));
    await tester.pumpAndSettle();
    expect(accepted, ApplyMoveConfirmResult.accepted);

    await tester.tap(find.byKey(const Key('open_cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply_move_confirm_cancel')));
    await tester.pumpAndSettle();
    expect(cancelled, ApplyMoveConfirmResult.cancelled);
  });
}
