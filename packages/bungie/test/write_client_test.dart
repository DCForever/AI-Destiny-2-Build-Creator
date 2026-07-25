import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

String successBody([Object? response]) => jsonEncode({
      'ErrorCode': 1,
      'ErrorStatus': 'Success',
      'Message': 'Ok',
      'ThrottleSeconds': 0,
      'Response': response ?? 0,
    });

void main() {
  const ctx = WriteClientContext(accessToken: 'tok', membershipType: 3);

  group('HttpBungieWriteClient', () {
    test('transferItem POSTs TransferItem with API key + Bearer', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'public-key',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody());
        },
      );
      final client = HttpBungieWriteClient(http: http);

      await client.transferItem(
        ctx,
        const TransferItemArgs(
          itemHash: 10,
          instanceId: 'i1',
          characterId: 'char-a',
          transferToVault: false,
        ),
      );

      expect(seen, isNotNull);
      expect(seen!.method, 'POST');
      expect(
        seen!.uri.path,
        contains('/Destiny2/Actions/Items/TransferItem/'),
      );
      expect(seen!.headers['X-API-Key'], 'public-key');
      expect(seen!.headers['Authorization'], 'Bearer tok');
      expect(seen!.headers.keys, isNot(contains('client_secret')));
      final body = jsonDecode(seen!.body!) as Map<String, dynamic>;
      expect(body['itemReferenceHash'], 10);
      expect(body['itemId'], 'i1');
      expect(body['characterId'], 'char-a');
      expect(body['membershipType'], 3);
      expect(body['transferToVault'], isFalse);
      expect(body['stackSize'], 1);
      expect(body.containsKey('client_secret'), isFalse);
    });

    test('equipItem POSTs EquipItem body', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody());
        },
      );
      final client = HttpBungieWriteClient(http: http);

      await client.equipItem(
        ctx,
        const EquipItemArgs(
          itemHash: 10,
          instanceId: 'i1',
          characterId: 'char-a',
        ),
      );

      expect(seen!.uri.path, contains('/Destiny2/Actions/Items/EquipItem/'));
      final body = jsonDecode(seen!.body!) as Map<String, dynamic>;
      expect(body['itemId'], 'i1');
      expect(body['characterId'], 'char-a');
      expect(body['membershipType'], 3);
    });

    test('applyArtifactConfig throws not fully wired', () async {
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async =>
            BungieHttpResponse(statusCode: 200, body: successBody()),
      );
      final client = HttpBungieWriteClient(http: http);

      await expectLater(
        client.applyArtifactConfig(
          ctx,
          const ApplyArtifactArgs(
            characterId: 'char-a',
            artifactHash: 99,
            config: [1, 2],
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not fully wired'),
          ),
        ),
      );
    });

    test('applyFashionSlot equips when instance present', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody());
        },
      );
      final client = HttpBungieWriteClient(http: http);

      await client.applyFashionSlot(
        ctx,
        const ApplyFashionArgs(
          characterId: 'char-a',
          slot: 'ghost',
          itemHash: 50,
          instanceId: 'i-ghost',
        ),
      );

      expect(seen!.uri.path, contains('/Destiny2/Actions/Items/EquipItem/'));
    });

    test('applyFashionSlot throws when instance missing', () async {
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async =>
            BungieHttpResponse(statusCode: 200, body: successBody()),
      );
      final client = HttpBungieWriteClient(http: http);

      await expectLater(
        client.applyFashionSlot(
          ctx,
          const ApplyFashionArgs(
            characterId: 'char-a',
            slot: 'ghost',
            itemHash: 50,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('createMockWriteClient', () {
    test('defaults to success no-ops', () async {
      final client = createMockWriteClient();
      await client.transferItem(
        ctx,
        const TransferItemArgs(
          itemHash: 1,
          instanceId: 'i',
          characterId: 'c',
          transferToVault: false,
        ),
      );
      await client.equipItem(
        ctx,
        const EquipItemArgs(
          itemHash: 1,
          instanceId: 'i',
          characterId: 'c',
        ),
      );
      await client.applyArtifactConfig(
        ctx,
        const ApplyArtifactArgs(characterId: 'c', artifactHash: 1),
      );
      await client.applyFashionSlot(
        ctx,
        const ApplyFashionArgs(
          characterId: 'c',
          slot: 'ghost',
          itemHash: 1,
        ),
      );
    });
  });
}
