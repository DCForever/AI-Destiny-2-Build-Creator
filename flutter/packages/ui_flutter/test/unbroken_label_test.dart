import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('preventIntraWordWrap', () {
    test('joins letters inside each token', () {
      final out = preventIntraWordWrap('An Insurmountable');
      expect(out.contains(kWordJoiner), isTrue);
      expect(stripIntraWordJoiners(out), 'An Insurmountable');
      expect(out.split(' '), hasLength(2));
      expect(stripIntraWordJoiners(out.split(' ').first), 'An');
      expect(out.split(' ').last.contains(kWordJoiner), isTrue);
    });

    test('leaves short tokens and empty strings alone', () {
      expect(preventIntraWordWrap(''), '');
      expect(preventIntraWordWrap('A'), 'A');
    });
  });

  group('packWholeWordLines', () {
    const style = TextStyle(
      fontSize: 11,
      fontFamily: 'monospace',
      letterSpacing: 0,
    );

    test('wraps only at spaces', () {
      final packed = packWholeWordLines(
        'An Insurmountable Skullfort',
        maxWidth: 80,
        style: style,
        maxLines: 2,
      );
      expect(packed.contains('Insurm\n'), isFalse);
      expect(packed.split('\n'), hasLength(lessThanOrEqualTo(2)));
      expect(packed.startsWith('An'), isTrue);
    });

    test('ellipsizes a single over-wide token', () {
      final packed = packWholeWordLines(
        'Insurmountable',
        maxWidth: 40,
        style: style,
        maxLines: 2,
      );
      expect(packed.contains('\n'), isFalse);
      expect(packed.endsWith('…'), isTrue);
      expect(packed.contains('ountable'), isFalse);
    });
  });

  group('UnbrokenLabel', () {
    testWidgets('single-line does not soft-wrap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 40,
              child: UnbrokenLabel('GRENADE'),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'GRENADE');
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('multi-line keeps whole words and semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: UnbrokenLabel(
                'An Insurmountable Skullfort',
                maxLines: 2,
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.semanticsLabel, 'An Insurmountable Skullfort');
      expect(text.maxLines, 2);
      expect(text.data, isNot(contains('Insurm\nountable')));
      expect(text.data, contains('An'));
    });
  });
}
