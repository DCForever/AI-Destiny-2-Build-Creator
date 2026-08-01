import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

class _Auth implements EquipAuthPort {
  _Auth({this.signedIn = false, this.tokenValue});
  bool signedIn;
  BungieTokens? tokenValue;
  @override
  bool get isSignedIn => signedIn;
  @override
  BungieTokens? get tokens => tokenValue;
}

class _NoProfile implements BungieProfileClient {
  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async =>
      const [];

  @override
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoWrite implements BungieWriteClient {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('canApply uses shared canEnableEquipCta rules', () async {
    final db = AppDatabase.memory();
    final auth = _Auth();
    final session = EquipSession(
      db: db,
      auth: auth,
      profileClient: _NoProfile(),
      writeClient: _NoWrite(),
      skipSyncIfStale: true,
    );

    expect(session.canApply, isFalse);
    expect(session.softAdvisory, contains('never auto-apply'));
    expect(
      canEnableEquipCta(
        signedIn: true,
        equipReady: true,
        characterId: 'c1',
        equipping: false,
        loading: false,
      ),
      isTrue,
    );

    session.selectCharacter('c1');
    // Still not signed in / not ready
    expect(session.canApply, isFalse);

    await db.close();
  });

  test('clearBinding resets readiness summary', () async {
    final db = AppDatabase.memory();
    final session = EquipSession(
      db: db,
      auth: _Auth(),
      profileClient: _NoProfile(),
      writeClient: _NoWrite(),
      skipSyncIfStale: true,
    );
    session.selectCharacter('x');
    session.clearBinding();
    expect(session.selectedCharacterId, isNull);
    expect(session.readinessSummary, contains('Select a variant'));
    await db.close();
  });
}
