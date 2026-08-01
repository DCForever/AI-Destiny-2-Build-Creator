import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';

/// Host adapter: [EquipSession] + Flutter [ChangeNotifier] (DART-038).
class EquipController extends ChangeNotifier {
  EquipController({
    required AppDatabase db,
    required WindowsOAuthSession session,
    required BungieProfileClient profileClient,
    required BungieWriteClient writeClient,
    required InventorySyncController inventorySync,
    bool skipSyncIfStale = false,
    Map<int, int>? equipmentBucketLookup,
    EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder,
    Map<int, String>? perkNameMap,
    PerkNameMapBuilder? perkNameMapBuilder,
    Map<int, RollTagWeaponMeta>? weaponRollMetaLookup,
    WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder,
    WeaponSocketContextBuilder? weaponSocketContextBuilder,
  }) : session = session,
       inventorySync = inventorySync,
       core = EquipSession(
         db: db,
         auth: _SessionAuth(session),
         profileClient: profileClient,
         writeClient: writeClient,
         skipSyncIfStale: skipSyncIfStale,
         equipmentBucketLookup:
             equipmentBucketLookup ?? inventorySync.equipmentBucketLookup,
         equipmentBucketLookupBuilder: equipmentBucketLookupBuilder ??
             inventorySync.equipmentBucketLookupBuilder,
         perkNameMap: perkNameMap ?? inventorySync.perkNameMap,
         perkNameMapBuilder:
             perkNameMapBuilder ?? inventorySync.perkNameMapBuilder,
         weaponRollMetaLookup:
             weaponRollMetaLookup ?? inventorySync.weaponRollMetaLookup,
         weaponRollMetaLookupBuilder: weaponRollMetaLookupBuilder ??
             inventorySync.weaponRollMetaLookupBuilder,
         weaponSocketContextBuilder: weaponSocketContextBuilder ??
             inventorySync.weaponSocketContextBuilder,
         afterSync: () => inventorySync.refreshStatus(),
       ) {
    core.addListener(notifyListeners);
  }

  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;
  final EquipSession core;

  List<CharacterSummary> get characters => core.characters;
  List<CharacterSummary> get matchingCharacters => core.matchingCharacters;
  String? get selectedCharacterId => core.selectedCharacterId;
  EquipReadyResult? get readiness => core.readiness;
  bool get equipReady => core.equipReady;
  List<PinStatus> get pinStatuses => core.pinStatuses;
  List<String> get emptyCombatSlots => core.emptyCombatSlots;
  EquipStatus? get lastStatus => core.lastStatus;
  PendingEquipAction? get pendingGaps => core.pendingGaps;
  bool get loadingCharacters => core.loadingCharacters;
  bool get loadingReadiness => core.loadingReadiness;
  bool get equipping => core.equipping;
  String? get error => core.error;
  String? get statusMessage => core.statusMessage;
  String get buildClass => core.buildClass;
  bool get isSignedIn => core.isSignedIn;
  int get writeCalls => core.writeCalls;
  String get readinessSummary => core.readinessSummary;
  bool get canApply => core.canApply;

  Future<void> bind({
    required int userId,
    required String buildId,
    required String variantId,
    required String buildClass,
  }) =>
      core.bind(
        userId: userId,
        buildId: buildId,
        variantId: variantId,
        buildClass: buildClass,
      );

  void clearBinding() => core.clearBinding();
  void selectCharacter(String? characterId) =>
      core.selectCharacter(characterId);
  Future<void> loadCharacters() => core.loadCharacters();
  Future<void> refreshReadiness() => core.refreshReadiness();
  Future<String?> requestEquip({bool forceGapsConfirm = false}) =>
      core.requestEquip(forceGapsConfirm: forceGapsConfirm);
  Future<String?> confirmGapsAndEquip() => core.confirmGapsAndEquip();
  void cancelGapsConfirm() => core.cancelGapsConfirm();

  @override
  void dispose() {
    core.removeListener(notifyListeners);
    super.dispose();
  }
}

class _SessionAuth implements EquipAuthPort {
  _SessionAuth(this._session);
  final WindowsOAuthSession _session;
  @override
  bool get isSignedIn => _session.isSignedIn;
  @override
  BungieTokens? get tokens => _session.tokens;
}
