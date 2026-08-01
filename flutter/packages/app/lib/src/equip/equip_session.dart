/// Shared equip orchestration (Windows + web hosts).
///
/// UI-agnostic: hosts wrap with ChangeNotifier and inject session access.
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build;
import 'package:destiny2_domain/destiny2_domain.dart';

import '../presentation/equip_format.dart';
import '../variant_use_cases.dart';

/// Pending equip after gaps confirm (empty combat slots).
class PendingEquipAction {
  const PendingEquipAction({
    required this.characterId,
    required this.emptyCombatSlots,
  });

  final String characterId;
  final List<String> emptyCombatSlots;
}

/// Access to signed-in tokens without coupling to host OAuth session types.
abstract class EquipAuthPort {
  bool get isSignedIn;
  BungieTokens? get tokens;
}

/// Optional hooks after a pre-equip inventory sync (Windows refreshes sync card).
typedef EquipAfterSyncHook = Future<void> Function();

/// Shared equip-ready + gaps-confirm + execute path (DART-038/047).
///
/// Soft guidance never applies. Hosts must not reimplement this state machine.
class EquipSession {
  EquipSession({
    required this.db,
    required this.auth,
    required this.profileClient,
    required this.writeClient,
    this.skipSyncIfStale = false,
    this.equipmentBucketLookup,
    this.equipmentBucketLookupBuilder,
    this.perkNameMap,
    this.perkNameMapBuilder,
    this.weaponRollMetaLookup,
    this.weaponRollMetaLookupBuilder,
    this.weaponSocketContextBuilder,
    this.afterSync,
  });

  final AppDatabase db;
  final EquipAuthPort auth;
  final BungieProfileClient profileClient;
  final BungieWriteClient writeClient;
  final bool skipSyncIfStale;
  final Map<int, int>? equipmentBucketLookup;
  final EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder;
  final Map<int, String>? perkNameMap;
  final PerkNameMapBuilder? perkNameMapBuilder;
  final Map<int, RollTagWeaponMeta>? weaponRollMetaLookup;
  final WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder;
  final WeaponSocketContextBuilder? weaponSocketContextBuilder;
  final EquipAfterSyncHook? afterSync;

  final List<void Function()> _listeners = <void Function()>[];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  String? _buildId;
  String? _variantId;
  int? _userId;
  String _buildClass = '';

  List<CharacterSummary> _characters = const [];
  String? _selectedCharacterId;
  EquipReadyResult? _readiness;
  ResolvedVariantEquipment? _resolved;
  List<String> _emptyCombatSlots = const [];
  EquipStatus? _lastStatus;
  PendingEquipAction? _pendingGaps;
  bool _loadingCharacters = false;
  bool _loadingReadiness = false;
  bool _equipping = false;
  String? _error;
  String? _statusMessage;
  int _writeCalls = 0;

  List<CharacterSummary> get characters => List.unmodifiable(_characters);
  List<CharacterSummary> get matchingCharacters {
    if (_buildClass.isEmpty) return characters;
    return [
      for (final c in _characters)
        if (c.classType == _buildClass) c,
    ];
  }

  String? get selectedCharacterId => _selectedCharacterId;
  EquipReadyResult? get readiness => _readiness;
  bool get equipReady => _readiness?.equipReady ?? false;
  List<PinStatus> get pinStatuses =>
      List.unmodifiable(_readiness?.pinStatuses ?? const []);
  List<String> get emptyCombatSlots => List.unmodifiable(_emptyCombatSlots);
  EquipStatus? get lastStatus => _lastStatus;
  PendingEquipAction? get pendingGaps => _pendingGaps;
  bool get loadingCharacters => _loadingCharacters;
  bool get loadingReadiness => _loadingReadiness;
  bool get equipping => _equipping;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  String get buildClass => _buildClass;
  bool get isSignedIn => auth.isSignedIn;
  int get writeCalls => _writeCalls;
  String get softAdvisory => kEquipSoftAdvisoryCaption;

  String get readinessSummary => _readiness == null
      ? 'Select a variant to check equip-ready'
      : formatEquipReadySummary(_readiness!);

  bool get canApply => canEnableEquipCta(
        signedIn: isSignedIn,
        equipReady: equipReady,
        characterId: _selectedCharacterId,
        equipping: _equipping,
        loading: _loadingCharacters || _loadingReadiness,
      );

  List<String> get stepReportLines {
    final status = _lastStatus;
    if (status == null) return const [];
    return [
      for (final step in status.steps) formatEquipStepReportLine(step),
    ];
  }

  Future<void> bind({
    required int userId,
    required String buildId,
    required String variantId,
    required String buildClass,
  }) async {
    _userId = userId;
    _buildId = buildId;
    _variantId = variantId;
    _buildClass = buildClass;
    _lastStatus = null;
    _pendingGaps = null;
    _error = null;
    _statusMessage = null;
    await Future.wait([
      refreshReadiness(),
      loadCharacters(),
    ]);
  }

  void clearBinding() {
    _userId = null;
    _buildId = null;
    _variantId = null;
    _buildClass = '';
    _resolved = null;
    _readiness = null;
    _emptyCombatSlots = const [];
    _selectedCharacterId = null;
    _characters = const [];
    _lastStatus = null;
    _pendingGaps = null;
    _error = null;
    _statusMessage = null;
    notifyListeners();
  }

  void selectCharacter(String? characterId) {
    _selectedCharacterId = characterId;
    _error = null;
    notifyListeners();
  }

  Future<void> loadCharacters() async {
    if (!auth.isSignedIn || auth.tokens == null) {
      _characters = const [];
      _selectedCharacterId = null;
      _loadingCharacters = false;
      notifyListeners();
      return;
    }
    _loadingCharacters = true;
    _error = null;
    notifyListeners();
    try {
      final token = auth.tokens!.accessToken;
      final memberships = await profileClient.getMemberships(token);
      if (memberships.isEmpty) {
        _characters = const [];
        _error = 'No Destiny memberships found';
      } else {
        _characters =
            await profileClient.getCharacters(token, memberships.first);
        final matching = matchingCharacters;
        if (_selectedCharacterId != null &&
            matching.every((c) => c.characterId != _selectedCharacterId)) {
          _selectedCharacterId = null;
        }
        if (_selectedCharacterId == null && matching.length == 1) {
          _selectedCharacterId = matching.single.characterId;
        }
      }
    } catch (e) {
      _error = _safe(e);
      _characters = const [];
    } finally {
      _loadingCharacters = false;
      notifyListeners();
    }
  }

  Future<void> refreshReadiness() async {
    final userId = _userId;
    final buildId = _buildId;
    final variantId = _variantId;
    if (userId == null || buildId == null || variantId == null) {
      _readiness = null;
      _resolved = null;
      _emptyCombatSlots = const [];
      notifyListeners();
      return;
    }
    _loadingReadiness = true;
    notifyListeners();
    try {
      final resolved = await resolveUserVariant(db, userId, buildId, variantId);
      _resolved = resolved;
      if (resolved == null) {
        _readiness = const EquipReadyResult(equipReady: false);
        _emptyCombatSlots = EquipmentSlot.combatSlots
            .map((s) => s.wireName)
            .toList(growable: false);
      } else {
        final inv = await listInventoryItems(db, userId);
        final index = buildInventoryPinIndex([
          for (final row in inv)
            InventoryPinItem(
              instanceId: row.instanceId,
              itemHash: row.itemHash,
            ),
        ]);
        _readiness = computeEquipReady(resolved, index);
        _emptyCombatSlots = emptyCombatSlotWires(resolved.equipment);
      }
      _error = null;
    } catch (e) {
      _error = _safe(e);
      _readiness = const EquipReadyResult(equipReady: false);
    } finally {
      _loadingReadiness = false;
      notifyListeners();
    }
  }

  Future<String?> requestEquip({bool forceGapsConfirm = false}) async {
    _error = null;
    _statusMessage = null;
    _lastStatus = null;

    if (!auth.isSignedIn || auth.tokens == null) {
      const msg = 'Sign in to equip';
      _error = msg;
      notifyListeners();
      return msg;
    }
    final characterId = _selectedCharacterId;
    if (characterId == null || characterId.isEmpty) {
      const msg = 'Select a character';
      _error = msg;
      notifyListeners();
      return msg;
    }
    final match = matchingCharacters
        .where((c) => c.characterId == characterId)
        .toList();
    if (match.isEmpty) {
      const msg = 'Character does not match build class';
      _error = msg;
      notifyListeners();
      return msg;
    }

    await refreshReadiness();
    final ready = _readiness;
    if (ready == null || !ready.equipReady) {
      final msg = ready == null
          ? 'Not equip-ready'
          : formatEquipReadySummary(ready);
      _error = msg;
      notifyListeners();
      return msg;
    }

    if (!forceGapsConfirm && _emptyCombatSlots.isNotEmpty) {
      _pendingGaps = PendingEquipAction(
        characterId: characterId,
        emptyCombatSlots: List.unmodifiable(_emptyCombatSlots),
      );
      notifyListeners();
      return null;
    }

    return _executeEquip(characterId);
  }

  Future<String?> confirmGapsAndEquip() async {
    final pending = _pendingGaps;
    if (pending == null) {
      return 'No pending gaps confirm';
    }
    _pendingGaps = null;
    notifyListeners();
    return _executeEquip(pending.characterId);
  }

  void cancelGapsConfirm() {
    _pendingGaps = null;
    _statusMessage = 'Equip cancelled';
    notifyListeners();
  }

  Future<String?> _executeEquip(String characterId) async {
    final userId = _userId;
    final buildId = _buildId;
    final variantId = _variantId;
    final tokens = auth.tokens;
    if (userId == null ||
        buildId == null ||
        variantId == null ||
        tokens == null) {
      const msg = 'Missing equip context';
      _error = msg;
      notifyListeners();
      return msg;
    }

    _equipping = true;
    _error = null;
    notifyListeners();

    try {
      if (!skipSyncIfStale) {
        await syncIfStale(
          db: db,
          userId: userId,
          accessToken: tokens.accessToken,
          profileClient: profileClient,
          equipmentBucketLookup: equipmentBucketLookup,
          equipmentBucketLookupBuilder: equipmentBucketLookupBuilder,
          perkNameMap: perkNameMap,
          perkNameMapBuilder: perkNameMapBuilder,
          weaponRollMetaLookup: weaponRollMetaLookup,
          weaponRollMetaLookupBuilder: weaponRollMetaLookupBuilder,
          weaponSocketContextBuilder: weaponSocketContextBuilder,
        );
        final hook = afterSync;
        if (hook != null) await hook();
      }

      final resolved =
          await resolveUserVariant(db, userId, buildId, variantId);
      if (resolved == null) {
        throw const EquipReadyException(
          'Variant not found',
          code: DomainFailureCodes.notEquipReady,
        );
      }
      final inv = await listInventoryItems(db, userId);
      final index = buildInventoryPinIndex([
        for (final row in inv)
          InventoryPinItem(
            instanceId: row.instanceId,
            itemHash: row.itemHash,
          ),
      ]);
      final readiness = computeEquipReady(resolved, index);
      assertEquipReady(readiness);
      _readiness = readiness;
      _resolved = resolved;
      _emptyCombatSlots = emptyCombatSlotWires(resolved.equipment);

      final equipInv = [
        for (final row in inv)
          EquipInventoryItem(
            instanceId: row.instanceId,
            itemHash: row.itemHash,
            location: row.location,
            characterId: row.characterId,
          ),
      ];

      final plan = planEquipSteps(
        EquipPlanInput(
          equipment: resolved.equipment,
          inventory: equipInv,
          characterId: characterId,
          artifact: null,
        ),
      );

      final memberships =
          await profileClient.getMemberships(tokens.accessToken);
      if (memberships.isEmpty) {
        throw StateError('No Destiny memberships found');
      }
      final membership = memberships.first;

      _writeCalls += 1;
      final status = await executeEquipPlan(
        writeClient,
        WriteClientContext(
          accessToken: tokens.accessToken,
          membershipType: membership.membershipType,
        ),
        characterId,
        plan,
      );
      _lastStatus = status;
      _statusMessage = formatEquipStatusSummary(status);
      _equipping = false;
      notifyListeners();
      return null;
    } on EquipReadyException catch (e) {
      _error = e.message;
      _equipping = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      final msg = _safe(e);
      _error = msg;
      _equipping = false;
      notifyListeners();
      return msg;
    }
  }

  static String _safe(Object e) {
    final text = e.toString();
    if (text.length > 240) return '${text.substring(0, 240)}…';
    return text;
  }
}
