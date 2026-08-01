import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

String successBody(Object? response) => jsonEncode({
      'ErrorCode': 1,
      'ErrorStatus': 'Success',
      'Message': 'Ok',
      'ThrottleSeconds': 0,
      'Response': response,
    });

void main() {
  group('parseCharactersResponse', () {
    test('maps classType integers and sorts by dateLastPlayed desc', () {
      final list = parseCharactersResponse({
        'characters': {
          'data': {
            'c-hunter': {
              'characterId': 'c-hunter',
              'classType': 1,
              'light': 1810,
              'emblemPath': '/common/destiny2_content/icons/h.png',
              'dateLastPlayed': '2026-07-20T10:00:00Z',
            },
            'c-titan': {
              'characterId': 'c-titan',
              'classType': 0,
              'light': 1820,
              'dateLastPlayed': '2026-07-24T12:00:00Z',
            },
            'c-warlock': {
              'characterId': 'c-warlock',
              'classType': 2,
              'light': 1800,
              'dateLastPlayed': '2026-07-22T08:00:00Z',
            },
          },
        },
      });

      expect(list, hasLength(3));
      expect(list[0].characterId, 'c-titan');
      expect(list[0].classType, 'Titan');
      expect(list[0].light, 1820);
      expect(list[1].characterId, 'c-warlock');
      expect(list[1].classType, 'Warlock');
      expect(list[2].characterId, 'c-hunter');
      expect(list[2].classType, 'Hunter');
      expect(list[2].emblemPath, '/common/destiny2_content/icons/h.png');
    });

    test('empty when characters missing', () {
      expect(parseCharactersResponse({}), isEmpty);
      expect(parseCharactersResponse(null), isEmpty);
    });
  });

  group('HttpBungieProfileClient.getCharacters', () {
    const membership = DestinyMembership(
      membershipType: 3,
      membershipId: 'mem1',
      displayName: 'G1',
    );

    test('GETs profile components=200 and parses list', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'test-key',
        transport: (req) async {
          seen = req;
          return BungieHttpResponse(
            statusCode: 200,
            body: successBody({
              'characters': {
                'data': {
                  'char-1': {
                    'characterId': 'char-1',
                    'classType': 1,
                    'light': 1900,
                    'dateLastPlayed': '2026-07-25T00:00:00Z',
                  },
                },
              },
            }),
          );
        },
      );

      final client = HttpBungieProfileClient(http: http);
      final characters =
          await client.getCharacters('access-token', membership);

      expect(seen, isNotNull);
      expect(seen!.uri.path, contains('/Destiny2/3/Profile/mem1/'));
      expect(seen!.uri.queryParameters['components'], '200');
      expect(seen!.headers['Authorization'], 'Bearer access-token');
      expect(seen!.headers['X-API-Key'], 'test-key');
      expect(characters, hasLength(1));
      expect(characters.single.characterId, 'char-1');
      expect(characters.single.classType, 'Hunter');
      expect(characters.single.light, 1900);
    });
  });
}
