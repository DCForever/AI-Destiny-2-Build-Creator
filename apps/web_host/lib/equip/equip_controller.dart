/// Equip-ready + optional equip orchestration for Jaspr web (DART-047).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';
import 'equip_format.dart';

/// Pending equip after gaps confirm (empty combat slots).
class PendingEquipAction {
  const PendingEquipAction({
    required this.characterId,
    required this.emptyCombatSlots,
  });

  final String characterId;
  final List<String> emptyCombatSlots;
}

/// Host orchestration for equip UI on web.
///
/// Enforces equip-ready hard gate, class match, optional gaps confirm for empty
/// combat slots, then plan + best-effort execute (DART-037). Soft never applies.
class EquipController extends ChangeNotifier {
  EquipController({
    required this.db,
    required this.session,
    required this.profileClient,
    required this.writeClient,
    this.skipSyncIfStale = false,
  });

  final AppDatabase db;
  final WebOAuthSession session;
  final BungieProfileClient profileClient;
  final BungieWriteClient writeClient;

  /// When true, equip path does not call [syncIfStale] (tests / offline).
  final bool skipSyncIfStale;

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
  bool get isSignedIn => session.isSignedIn;
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

  /// Bind to current build/variant selection and refresh readiness + characters.
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
    if (!session.isSignedIn || session.tokens == null) {
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
      final token = session.tokens!.accessToken;
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

  /// Request equip. Returns null if started or pending gaps confirm;
  /// error string if blocked before execute.
  Future<String?> requestEquip({bool forceGapsConfirm = false}) async {
    _error = null;
    _statusMessage = null;
    _lastStatus = null;

    if (!session.isSignedIn || session.tokens == null) {
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
    final tokens = session.tokens;
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
        );
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
