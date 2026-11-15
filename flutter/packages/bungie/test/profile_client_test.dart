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
  group('parseMembershipsResponse', () {
    test('orders primary membership first', () {
      final memberships = parseMembershipsResponse({
        'destinyMemberships': [
          {
            'membershipType': 3,
            'membershipId': '111',
            'displayName': 'G1',
            'bungieGlobalDisplayName': '',
          },
          {
            'membershipType': 1,
            'membershipId': '222',
            'bungieGlobalDisplayName': 'Guardian#0001',
          },
        ],
        'primaryMembershipId': '222',
      });

      expect(memberships, hasLength(2));
      expect(memberships.first.membershipId, '222');
      expect(memberships.first.displayName, 'Guardian#0001');
      expect(memberships.first.membershipType, 1);
    });
  });

  group('HttpBungieProfileClient', () {
    const membership = DestinyMembership(
      membershipType: 3,
      membershipId: 'mem1',
      displayName: 'G1',
    );

    test('getMemberships uses shared client path and parses list', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(
            statusCode: 200,
            body: successBody({
              'destinyMemberships': [
                {
                  'membershipType': 3,
                  'membershipId': 'm1',
                  'bungieGlobalDisplayName': 'Alpha',
                },
              ],
            }),
          );
        },
      );
      final client = HttpBungieProfileClient(http: http);
      final list = await client.getMemberships('tok');
      expect(list.single.membershipId, 'm1');
      expect(list.single.displayName, 'Alpha');
      expect(
        seen!.uri.path,
        contains('/User/GetMembershipsForCurrentUser/'),
      );
      expect(seen!.headers['Authorization'], 'Bearer tok');
    });

    test('getCharacterLoadoutsProfile uses components 200,206', () async {
      BungieHttpRequest? seen;
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(
            statusCode: 200,
            body: successBody({
              'characters': {
                'data': {
                  'char1': {
                    'characterId': 'char1',
                    'classType': 0,
                    'light': 2000,
                    'dateLastPlayed': '2026-01-01',
                  },
                },
              },
              'characterLoadouts': {
                'data': {
                  'char1': {
                    'loadouts': [
                      {
                        'iconHash': 0,
                        'colorHash': 0,
                        'nameHash': 0,
                        'items': [
                          {'itemInstanceId': '99'},
                        ],
                      },
                    ],
                  },
                },
              },
            }),
          );
        },
      );
      final client = HttpBungieProfileClient(http: http);
      final profile = await client.getCharacterLoadoutsProfile('tok', membership);
      expect(
        seen!.uri.queryParameters['components'],
        kCharacterLoadoutsProfileComponents,
      );
      final characters = parseCharactersResponse(profile);
      final loadouts = parseCharacterLoadoutsResponse(profile, characters);
      expect(loadouts, hasLength(1));
      expect(loadouts.single.itemInstanceIds, ['99']);
      expect(loadouts.single.className, 'Titan');
    });

    test('getFullInventory parses vault, character, equipped', () async {
      final http = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          expect(request.uri.queryParameters['components'], isNotEmpty);
          return BungieHttpResponse(
            statusCode: 200,
            body: successBody(_fullInventoryResponse),
          );
        },
      );
      final client = HttpBungieProfileClient(http: http);
      final items = await client.getFullInventory('tok', membership);

      expect(items, hasLength(3));
      final vault = items.firstWhere((i) => i.instanceId == 'vault1');
      expect(vault.location, 'vault');
      expect(vault.power, 1800);
      expect(vault.isMasterwork, isTrue);
      expect(vault.plugHashes, [501]);
      expect(vault.bucketHash, 1498876634);

      final charInv = items.firstWhere((i) => i.instanceId == 'charInv1');
      expect(charInv.location, 'character');
      expect(charInv.characterId, 'char1');
      expect(charInv.isCrafted, isTrue);
      expect(charInv.power, 1810);

      final equip = items.firstWhere((i) => i.instanceId == 'equip1');
      expect(equip.location, 'equipped');
      expect(equip.power, 1820);
    });

    test('drops unknown buckets and missing instance ids', () async {
      final result = parseFullInventoryResponse({
        'profileInventory': {
          'data': {
            'items': [
              {'itemHash': 1, 'bucketHash': 99999999, 'itemInstanceId': 'x'},
              {'itemHash': 2, 'bucketHash': 1498876634},
              {
                'itemHash': 3,
                'bucketHash': 1498876634,
                'itemInstanceId': 'ok',
              },
            ],
          },
        },
        'characterInventories': {'data': <String, Object?>{}},
        'characterEquipment': {'data': <String, Object?>{}},
        'itemComponents': {
          'instances': {
            'data': {
              'ok': {'primaryStat': {'value': 10}},
            },
          },
          'sockets': {
            'data': <String, Object?>{},
          },
        },
      }, membership);

      expect(result.items, hasLength(1));
      expect(result.items.single.instanceId, 'ok');
      expect(result.diagnostics.dropped.unknownBucket, 1);
      expect(result.diagnostics.dropped.missingInstanceId, 1);
      expect(result.diagnostics.parsed.total, 1);
      expect(result.diagnostics.inventorySectionsComplete, isTrue);
    });

    test('privacy-blocked inventory section marks sections incomplete', () {
      final result = parseFullInventoryResponse({
        'profileInventory': {'privacy': 2},
        'characterInventories': {'data': <String, Object?>{}},
        'characterEquipment': {'data': <String, Object?>{}},
      }, membership);

      expect(result.diagnostics.inventorySectionsComplete, isFalse);
      expect(result.items, isEmpty);
    });

    test('parses armor named stats', () {
      final result = parseFullInventoryResponse({
        'profileInventory': {
          'data': {
            'items': [
              {
                'itemHash': 700001,
                'bucketHash': 3448274439,
                'itemInstanceId': 'armor1',
              },
            ],
          },
        },
        'itemComponents': {
          'instances': {
            'data': {
              'armor1': {'primaryStat': {'value': 1810}},
            },
          },
          'sockets': {
            'data': {
              'armor1': {'sockets': <Object>[]},
            },
          },
          'stats': {
            'data': {
              'armor1': {
                'stats': [
                  {'statHash': 392767087, 'value': 10},
                  {'statHash': 4244567218, 'value': 20},
                ],
              },
            },
          },
        },
      }, membership);

      expect(result.items.single.statValues?['Health'], 10);
      expect(result.items.single.statValues?['Melee'], 20);
    });

    test('parses socket capture + energy for subclass and armor', () {
      final result = parseFullInventoryResponse({
        'profileInventory': {'data': {'items': <Object>[]}},
        'characterInventories': {'data': <String, Object?>{}},
        'characterEquipment': {
          'data': {
            'char1': {
              'items': [
                {
                  'itemHash': 900001,
                  'bucketHash': kSubclassBucketHash,
                  'itemInstanceId': 'sub1',
                },
                {
                  'itemHash': 900002,
                  'bucketHash': 3448274439,
                  'itemInstanceId': 'helm1',
                },
              ],
            },
          },
        },
        'itemComponents': {
          'instances': {
            'data': {
              'sub1': {'primaryStat': {'value': 0}},
              'helm1': {
                'primaryStat': {'value': 1810},
                'energy': {
                  'energyCapacity': 10,
                  'energyUsed': 4,
                },
              },
            },
          },
          'sockets': {
            'data': {
              'sub1': {
                'sockets': [
                  {'plugHash': 111, 'isEnabled': true, 'isVisible': true},
                  // Empty but unlocked fragment socket (M2).
                  {'plugHash': 0, 'isEnabled': true, 'isVisible': true},
                  {'plugHash': 222, 'isEnabled': true, 'isVisible': true},
                ],
              },
              'helm1': {
                'sockets': [
                  {'plugHash': 301, 'isEnabled': true, 'isVisible': true},
                  {'plugHash': 302, 'isEnabled': true, 'isVisible': true},
                ],
              },
            },
          },
          'reusablePlugs': {
            'data': {
              'sub1': {
                'plugs': {
                  '0': [
                    {
                      'plugItemHash': 111,
                      'canInsert': true,
                      'enabled': true,
                    },
                    {
                      'plugItemHash': 112,
                      'canInsert': true,
                      'enabled': true,
                    },
                    {
                      'plugItemHash': 113,
                      'canInsert': false,
                      'enabled': true,
                    },
                    {
                      // Missing canInsert/enabled ⇒ unknown → excluded.
                      'plugItemHash': 114,
                    },
                  ],
                },
              },
              'helm1': {
                'plugs': {
                  '0': [
                    {
                      'plugItemHash': 301,
                      'canInsert': true,
                      'enabled': true,
                    },
                    {
                      'plugItemHash': 303,
                      'canInsert': true,
                      'enabled': true,
                    },
                  ],
                },
              },
            },
          },
        },
        'profilePlugSets': {
          'data': {
            'plugs': {
              '55': [
                {
                  'plugItemHash': 555,
                  'canInsert': true,
                  'enabled': true,
                },
                {
                  'plugItemHash': 556,
                  'canInsert': false,
                  'enabled': true,
                },
              ],
            },
          },
        },
        'characterPlugSets': {
          'data': {
            'char1': {
              'plugs': {
                '66': [
                  {
                    'plugItemHash': 666,
                    'canInsert': true,
                    'enabled': true,
                  },
                ],
              },
            },
            'char2': {
              'plugs': {
                '77': [
                  {
                    'plugItemHash': 777,
                    'canInsert': true,
                    'enabled': true,
                  },
                ],
              },
            },
          },
        },
      }, membership);

      final sub = result.items.firstWhere((i) => i.instanceId == 'sub1');
      expect(sub.socketCapture, isNotNull);
      expect(sub.socketCapture, hasLength(3));
      expect(sub.socketCapture!.first.equippedPlugHash, 111);
      expect(
        sub.socketCapture!.any((s) => s.socketIndex == 1 && s.equippedPlugHash == 0),
        isTrue,
        reason: 'empty unlocked socket must be captured',
      );
      expect(
        sub.socketCapture!.first.reusablePlugHashes,
        containsAll([111, 112]),
      );
      expect(
        sub.socketCapture!.first.reusablePlugHashes.contains(113),
        isFalse,
        reason: 'canInsert:false must not count as unlocked/usable',
      );
      expect(
        sub.socketCapture!.first.reusablePlugHashes.contains(114),
        isFalse,
        reason: 'missing canInsert/enabled is unknown — skip',
      );

      final helm = result.items.firstWhere((i) => i.instanceId == 'helm1');
      expect(helm.socketCapture, isNotNull);
      expect(helm.energyCapacity, 10);
      expect(helm.energyUsed, 4);
      expect(
        helm.socketCapture!.first.reusablePlugHashes,
        containsAll([301, 303]),
      );

      expect(result.profilePlugSetPlugHashes, contains(555));
      expect(result.profilePlugSetPlugHashes.contains(556), isFalse);
      expect(
        result.unlockedPlugSetPlugHashesForCharacter('char1'),
        containsAll([555, 666]),
      );
      expect(
        result.unlockedPlugSetPlugHashesForCharacter('char1').contains(777),
        isFalse,
        reason: '105 must be limited to the Apply character',
      );
      expect(
        result.unlockedPlugSetPlugHashesForCharacter('char2'),
        containsAll([555, 777]),
      );
    });

    test('inventory components include sockets, reusable plugs, plug sets', () {
      expect(kInventoryProfileComponents, contains('305'));
      expect(kInventoryProfileComponents, contains('310'));
      expect(kInventoryProfileComponents, contains('104'));
      expect(kInventoryProfileComponents, contains('105'));
    });

    test('needsSocketCapture covers subclass and armor', () {
      expect(needsSocketCapture(kSubclassBucketHash), isTrue);
      expect(needsSocketCapture(3448274439), isTrue); // helmet
      expect(needsSocketCapture(1498876634), isTrue); // kinetic weapon
      expect(needsSocketCapture(999999), isFalse);
    });
  });

  group('resolveTransferContainerBuckets', () {
    test('resolves vault general via lookup; drops without', () {
      const vaultKinetic = RawInventoryItem(
        instanceId: 'v1',
        itemHash: 42,
        bucketHash: 138197802,
        location: 'vault',
      );
      const equip = RawInventoryItem(
        instanceId: 'e1',
        itemHash: 1,
        bucketHash: 1498876634,
        location: 'equipped',
      );

      final dropped = resolveTransferContainerBuckets(
        [vaultKinetic, equip],
        const {},
      );
      expect(dropped.items, hasLength(1));
      expect(dropped.droppedNonEquipment, 1);

      final resolved = resolveTransferContainerBuckets(
        [vaultKinetic, equip],
        {42: 1498876634},
      );
      expect(resolved.items, hasLength(2));
      expect(resolved.resolvedFromTransfer, 1);
      expect(
        resolved.items.firstWhere((i) => i.instanceId == 'v1').bucketHash,
        1498876634,
      );
    });
  });
}

const _fullInventoryResponse = {
  'profileInventory': {
    'data': {
      'items': [
        {
          'itemHash': 800001,
          'bucketHash': 1498876634,
          'itemInstanceId': 'vault1',
        },
      ],
    },
  },
  'characterInventories': {
    'data': {
      'char1': {
        'items': [
          {
            'itemHash': 800002,
            'bucketHash': 2465295065,
            'itemInstanceId': 'charInv1',
          },
        ],
      },
    },
  },
  'characterEquipment': {
    'data': {
      'char1': {
        'items': [
          {
            'itemHash': 800003,
            'bucketHash': 953998645,
            'itemInstanceId': 'equip1',
          },
        ],
      },
    },
  },
  'itemComponents': {
    'instances': {
      'data': {
        'vault1': {
          'primaryStat': {'value': 1800},
          'isMasterwork': true,
          'isCrafted': false,
        },
        'charInv1': {
          'primaryStat': {'value': 1810},
          'isCrafted': true,
        },
        'equip1': {
          'primaryStat': {'value': 1820},
        },
      },
    },
    'sockets': {
      'data': {
        'vault1': {
          'sockets': [
            {'plugHash': 501, 'isEnabled': true},
          ],
        },
        'charInv1': {
          'sockets': [
            {'plugHash': 502, 'isEnabled': true},
          ],
        },
        'equip1': {
          'sockets': [
            {'plugHash': 503, 'isEnabled': true},
          ],
        },
      },
    },
  },
};
