import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'build_identity_format.dart';
import 'finish_gaps_format.dart';
import 'soft_guidance_format.dart';
import 'variant_compose_format.dart';

/// Stable offline library owner when the user is signed out (DART-030/031/032/033).
const String kLocalLibraryMembershipId = 'local-library';

/// Draft synergy type for create / identity edit UI.
class DraftSynergyType {
  const DraftSynergyType({required this.type, this.subType});

  final String type;
  final String? subType;

  SynergyTypeDesignation toDomain() => SynergyTypeDesignation(
        type: SynergyType(type.trim()),
        subType: () {
          final s = subType?.trim();
          if (s == null || s.isEmpty) return null;
          return s;
        }(),
      );

  String get designationKey =>
      formatSynergyDesignationKey(type, subType);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraftSynergyType &&
        other.type == type &&
        other.subType == subType;
  }

  @override
  int get hashCode => Object.hash(type, subType);
}

/// One expanded equipment slot pin for compose display (DART-033).
class SlotPinView {
  const SlotPinView({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    required this.setId,
    required this.attachmentMode,
    this.instanceId,
    this.setItemId,
  });

  final String slot;
  final int itemHash;
  final String itemName;
  final String setId;
  final String attachmentMode;
  final String? instanceId;

  /// Active set item id when known (live attach); used for pin upserts.
  final String? setItemId;

  String get pinLabel => formatSlotPinLabel(instanceId);
  String get pinDetail => formatSlotPinDetail(instanceId);
  bool get isLive => attachmentMode == AttachmentMode.live.wireName;
  bool get canEditPin => isLive && setItemId != null;
}

/// Attachment row with resolved set name for UI.
class AttachmentView {
  const AttachmentView({
    required this.record,
    this.setName,
    this.setType,
  });

  final AttachmentRecord record;
  final String? setName;
  final String? setType;

  String get summary => formatAttachmentSummary(
        setId: record.setId,
        setName: setName,
        mode: record.mode,
      );
}

/// In-process orchestration for Builds library + variant compose + soft guidance
/// (DART-032/033/034).
///
/// Calls [destiny2_app] build/variant/attachment/set/coverage use cases against
/// the host's single [AppDatabase]. Soft guidance never auto-applies.
class BuildsLibraryController extends ChangeNotifier {
  BuildsLibraryController({
    required this.db,
    required this.session,
    required this.inventorySync,
  });

  final AppDatabase db;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

  int? _userId;
  List<BuildRecord> _builds = const [];
  BuildDetail? _selected;
  String? _error;
  bool _loading = false;

  /// Draft synergy types for the create form.
  List<DraftSynergyType> _createDraftTypes = const [];

  /// Draft synergy types when editing selected identity.
  List<DraftSynergyType> _editDraftTypes = const [];

  // --- DART-033 compose state ---
  VariantRecord? _selectedVariant;
  List<AttachmentView> _attachments = const [];
  List<SlotPinView> _slotPins = const [];
  List<SetRecord> _attachableSets = const [];

  // --- DART-034 soft guidance (display only; never auto-applies) ---
  CoverageQueryResult? _coverage;
  SoftStatTargets _softStatTargets = const SoftStatTargets();
  /// Optional estimate for soft-stat warnings (tests may inject).
  StatEstimate? softStatEstimateOverride;

  // --- DART-064 identity confirm + subclass kit + hard-block preview ---
  SubclassKit _editSubclass = const SubclassKit();
  List<String>? _pendingIdentityFields;
  Map<String, Object?>? _pendingIdentityPayload;
  List<ComposeHardBlock> _composeHardBlocks = const [];
  String? _lastForkedFromId;

  /// Optional catalog base items for Manifest pickers / capacity (tests inject).
  List<CatalogItem>? catalogItems;

  int? get userId => _userId;
  List<BuildRecord> get builds => _builds;
  BuildDetail? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  List<DraftSynergyType> get createDraftTypes =>
      List.unmodifiable(_createDraftTypes);
  List<DraftSynergyType> get editDraftTypes =>
      List.unmodifiable(_editDraftTypes);

  VariantRecord? get selectedVariant => _selectedVariant;
  List<VariantRecord> get variants => _selected?.variants ?? const [];
  List<AttachmentView> get attachments => List.unmodifiable(_attachments);
  List<SlotPinView> get slotPins => List.unmodifiable(_slotPins);
  List<SetRecord> get attachableSets => List.unmodifiable(_attachableSets);

  CoverageQueryResult? get coverage => _coverage;
  CoverageResult get coverageResult =>
      _coverage?.coverage ?? CoverageResult.empty;
  List<SynergyCoverageRow> get synergyCoverageRows =>
      List.unmodifiable(coverageResult.synergies);
  List<SetBonusSoftRow> get setBonusSoftRows =>
      List.unmodifiable(coverageResult.setBonuses);
  List<ElementSoftMismatch> get elementSoftMismatches =>
      List.unmodifiable(coverageResult.elementMismatches);
  List<SoftStatWarningRow> get softStatWarnings =>
      List.unmodifiable(coverageResult.softStats);
  SoftStatTargets get softStatTargets => _softStatTargets;
  String get softStatTargetsSummary =>
      formatSoftStatTargetsSummary(_softStatTargets);
  bool get hasSoftMisses => _coverage?.hasSoftMisses ?? false;
  String get softGuidanceAdvisory => kSoftGuidanceAdvisoryCaption;

  SubclassKit get editSubclass => _editSubclass;
  List<String>? get pendingIdentityFields => _pendingIdentityFields;
  bool get identityConfirmRequired =>
      _pendingIdentityFields != null && _pendingIdentityFields!.isNotEmpty;
  List<ComposeHardBlock> get composeHardBlocks =>
      List.unmodifiable(_composeHardBlocks);
  bool get identitySaveHardBlocked =>
      composeSaveHardBlocked(_composeHardBlocks);
  String? get lastForkedFromId => _lastForkedFromId;

  String get subclassCapacityCaption {
    final aspects = _editSubclass.aspects
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    final fragments = _editSubclass.fragments
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    final cap = _resolveFragmentCapacityLocal(aspects);
    return formatSubclassCapacityCaption(
      aspectCount: aspects.length,
      fragmentCount: fragments.length,
      fragmentCapacity: cap.capacity,
      capacityResolved: cap.resolved,
    );
  }

  /// Pure finish-gap readiness (DART-057 / GAP-FEAT-06). Soft never auto-applies.
  FinishGapsResult? get finishGaps {
    final v = _selectedVariant;
    if (v == null) return null;
    final attIns = <FinishAttachmentInput>[];
    for (final a in _attachments) {
      final type = SetType.tryParse(a.setType ?? '');
      if (type == null) continue;
      attIns.add(
        FinishAttachmentInput(
          setId: a.record.setId,
          mode: finishAttachmentModeFromWire(a.record.mode),
          setType: type,
          setName: a.setName,
        ),
      );
    }
    final equipment = <String, FinishEquipmentClaim?>{
      for (final pin in _slotPins)
        pin.slot: FinishEquipmentClaim(
          slot: pin.slot,
          itemHash: pin.itemHash,
          itemName: pin.itemName,
          instanceId: pin.instanceId,
        ),
    };
    final hasMod = _attachments.any(
      (a) => (a.setType ?? '') == SetType.mod.wireName,
    );
    return evaluateFinishGaps(
      EvaluateFinishGapsInput(
        variantId: v.id,
        isDefaultVariant: v.isDefault,
        attachments: attIns,
        equipment: equipment,
        hasModCoverage: hasMod,
      ),
    );
  }

  /// Finish complete flag for equip/export CTA policy.
  bool get finishComplete => finishGaps?.complete ?? false;

  String synergySummaryOf(BuildRecord b) => formatSynergyDesignationList([
        for (final d in b.synergyTypes)
          (type: d.type, subType: d.subType),
      ]);

  String exoticsSummaryOf(BuildRecord b) => formatExoticsSummary(
        exoticArmorName: b.exoticArmorName,
        exoticArmorHash: b.exoticArmorHash,
        exoticWeaponName: b.exoticWeaponName,
        exoticWeaponHash: b.exoticWeaponHash,
      );

  String identitySummaryOf(BuildRecord b) => formatIdentitySummary(
        className: b.className,
        pinnedSuper: b.pinnedSuper,
      );

  /// Resolve local user (signed-in or [kLocalLibraryMembershipId]) and load list.
  Future<void> refresh({bool keepSelection = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _builds = await listUserBuilds(db, _userId!);
      if (keepSelection && _selected != null) {
        final id = _selected!.build.id;
        final priorVariantId = _selectedVariant?.id;
        final next = await getBuildDetail(db, _userId!, id);
        _selected = next;
        if (next != null) {
          _editDraftTypes = _recordsToDrafts(next.build.synergyTypes);
          _editSubclass = subclassKitFromJson(next.build.subclass);
          _refreshComposeHardBlocks();
          await _syncComposeAfterBuildLoad(next, preferredVariantId: priorVariantId);
        } else {
          _editDraftTypes = const [];
          _editSubclass = const SubclassKit();
          _clearCompose();
        }
      }
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<int> resolveLibraryUserId() async {
    final fromSync = inventorySync.localUserId;
    if (fromSync != null) return fromSync;

    final tokens = session.tokens;
    if (session.isSignedIn &&
        tokens != null &&
        tokens.bungieMembershipId.isNotEmpty) {
      final user = await ensureUser(
        db,
        bungieMembershipId: tokens.bungieMembershipId,
        membershipType: 0,
        displayName: '',
      );
      return user.id;
    }

    final local = await ensureUser(
      db,
      bungieMembershipId: kLocalLibraryMembershipId,
      membershipType: 0,
      displayName: 'Local library',
    );
    return local.id;
  }

  Future<void> selectBuild(String? buildId) async {
    if (buildId == null) {
      _selected = null;
      _editDraftTypes = const [];
      _clearCompose();
      notifyListeners();
      return;
    }
    final uid = _userId ?? await resolveLibraryUserId();
    _userId = uid;
    final row = await getBuildDetail(db, uid, buildId);
    _selected = row;
    _editDraftTypes =
        row != null ? _recordsToDrafts(row.build.synergyTypes) : const [];
    _editSubclass = row != null
        ? subclassKitFromJson(row.build.subclass)
        : const SubclassKit();
    _pendingIdentityFields = null;
    _pendingIdentityPayload = null;
    if (row != null) {
      _refreshComposeHardBlocks();
      await _syncComposeAfterBuildLoad(row);
    } else {
      _clearCompose();
    }
    notifyListeners();
  }

  void addCreateDraftType(String type, [String? subType]) {
    final draft = DraftSynergyType(type: type.trim(), subType: subType);
    if (draft.type.isEmpty) return;
    // Deduplicate by designation key.
    if (_createDraftTypes.any((d) => d.designationKey == draft.designationKey)) {
      return;
    }
    _createDraftTypes = [..._createDraftTypes, draft];
    notifyListeners();
  }

  void removeCreateDraftTypeAt(int index) {
    if (index < 0 || index >= _createDraftTypes.length) return;
    final next = List<DraftSynergyType>.from(_createDraftTypes)..removeAt(index);
    _createDraftTypes = next;
    notifyListeners();
  }

  void clearCreateDraftTypes() {
    if (_createDraftTypes.isEmpty) return;
    _createDraftTypes = const [];
    notifyListeners();
  }

  void addEditDraftType(String type, [String? subType]) {
    final draft = DraftSynergyType(type: type.trim(), subType: subType);
    if (draft.type.isEmpty) return;
    if (_editDraftTypes.any((d) => d.designationKey == draft.designationKey)) {
      return;
    }
    _editDraftTypes = [..._editDraftTypes, draft];
    notifyListeners();
  }

  void removeEditDraftTypeAt(int index) {
    if (index < 0 || index >= _editDraftTypes.length) return;
    final next = List<DraftSynergyType>.from(_editDraftTypes)..removeAt(index);
    _editDraftTypes = next;
    notifyListeners();
  }

  /// Create build; selects it on success. Returns error message or null.
  Future<String?> createBuild({
    String? name,
    required GuardianClass className,
    int? exoticArmorHash,
    String? exoticArmorName,
    int? exoticWeaponHash,
    String? exoticWeaponName,
    String? pinnedSuper,
    List<DraftSynergyType>? synergyTypes,
  }) async {
    final types = synergyTypes ?? _createDraftTypes;
    if (types.isEmpty) {
      const msg = 'At least one synergy type is required';
      _error = msg;
      notifyListeners();
      return msg;
    }
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final created = await createUserBuild(
        db,
        uid,
        CreateBuildCommand(
          name: name,
          className: className,
          exoticArmorHash: exoticArmorHash,
          exoticArmorName: exoticArmorName,
          exoticWeaponHash: exoticWeaponHash,
          exoticWeaponName: exoticWeaponName,
          pinnedSuper: pinnedSuper,
          synergyTypes: [for (final d in types) d.toDomain()],
        ),
      );
      _builds = await listUserBuilds(db, uid);
      _selected = created;
      _editDraftTypes = _recordsToDrafts(created.build.synergyTypes);
      _createDraftTypes = const [];
      await _syncComposeAfterBuildLoad(created);
      _error = null;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  void setEditSubclass(SubclassKit kit) {
    _editSubclass = kit;
    _refreshComposeHardBlocks();
    notifyListeners();
  }

  void cancelIdentityConfirm() {
    _pendingIdentityFields = null;
    _pendingIdentityPayload = null;
    notifyListeners();
  }

  /// Update selected build identity (name, synergy types, pins, kit).
  ///
  /// When identity fields change without [identityAction], stores pending
  /// confirm payload and returns IDENTITY_CONFIRM_REQUIRED message.
  Future<String?> updateSelectedIdentity({
    String? name,
    GuardianClass? className,
    List<DraftSynergyType>? synergyTypes,
    SubclassKit? subclass,
    bool setExoticArmor = false,
    int? exoticArmorHash,
    String? exoticArmorName,
    String? existingExoticArmorSlot,
    String? nextExoticArmorSlot,
    bool setExoticWeapon = false,
    int? exoticWeaponHash,
    String? exoticWeaponName,
    bool setPinnedSuper = false,
    String? pinnedSuper,
    IdentityAction? identityAction,
  }) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No build selected';
    }
    final types = synergyTypes ?? _editDraftTypes;
    if (types.isEmpty) {
      const msg = 'At least one synergy type is required';
      _error = msg;
      notifyListeners();
      return msg;
    }

    final kit = subclass ?? _editSubclass;
    _refreshComposeHardBlocks(
      exoticArmorHash: setExoticArmor ? exoticArmorHash : sel.build.exoticArmorHash,
      exoticWeaponHash:
          setExoticWeapon ? exoticWeaponHash : sel.build.exoticWeaponHash,
      subclass: kit,
      synergyCount: types.length,
    );
    if (identitySaveHardBlocked && identityAction != IdentityAction.fork) {
      // Still allow fork attempt; confirm/in-place blocked by hard preview.
      if (identityAction == null || identityAction == IdentityAction.confirm) {
        final msg = _composeHardBlocks.map((b) => b.message).join('; ');
        _error = msg;
        notifyListeners();
        return msg;
      }
    }

    try {
      final priorVariantId = _selectedVariant?.id;
      final updated = await updateUserBuild(
        db,
        uid,
        sel.build.id,
        UpdateBuildCommand(
          name: name,
          className: className,
          subclass: kit,
          synergyTypes: [for (final d in types) d.toDomain()],
          setExoticArmor: setExoticArmor,
          exoticArmorHash: exoticArmorHash,
          exoticArmorName: exoticArmorName,
          setExoticWeapon: setExoticWeapon,
          exoticWeaponHash: exoticWeaponHash,
          exoticWeaponName: exoticWeaponName,
          setPinnedSuper: setPinnedSuper,
          pinnedSuper: pinnedSuper,
          identityAction: identityAction,
          existingExoticArmorSlot: existingExoticArmorSlot,
          nextExoticArmorSlot: nextExoticArmorSlot,
        ),
      );
      if (updated == null) {
        return 'Build not found';
      }
      _pendingIdentityFields = null;
      _pendingIdentityPayload = null;
      _lastForkedFromId = updated.forkedFromId;
      _selected = updated;
      _editDraftTypes = _recordsToDrafts(updated.build.synergyTypes);
      _editSubclass = subclassKitFromJson(updated.build.subclass);
      _builds = await listUserBuilds(db, uid);
      await _syncComposeAfterBuildLoad(
        updated,
        preferredVariantId: priorVariantId,
      );
      _error = null;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      if (e.code == UseCaseErrorCode.identityConfirmRequired) {
        final fields = e.details['identityFields'];
        _pendingIdentityFields = fields is List
            ? [for (final f in fields) f.toString()]
            : const ['identity'];
        _pendingIdentityPayload = {
          'name': name,
          'className': className?.wireName,
          'setExoticArmor': setExoticArmor,
          'exoticArmorHash': exoticArmorHash,
          'exoticArmorName': exoticArmorName,
          'setExoticWeapon': setExoticWeapon,
          'exoticWeaponHash': exoticWeaponHash,
          'exoticWeaponName': exoticWeaponName,
          'setPinnedSuper': setPinnedSuper,
          'pinnedSuper': pinnedSuper,
          'existingExoticArmorSlot': existingExoticArmorSlot,
          'nextExoticArmorSlot': nextExoticArmorSlot,
        };
        _error = e.message;
        notifyListeners();
        return e.message;
      }
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Confirm or fork using the last pending identity payload.
  Future<String?> resolveIdentityAction(IdentityAction action) async {
    final payload = _pendingIdentityPayload;
    if (payload == null) {
      return updateSelectedIdentity(identityAction: action);
    }
    return updateSelectedIdentity(
      name: payload['name'] as String?,
      setExoticArmor: payload['setExoticArmor'] as bool? ?? false,
      exoticArmorHash: payload['exoticArmorHash'] as int?,
      exoticArmorName: payload['exoticArmorName'] as String?,
      setExoticWeapon: payload['setExoticWeapon'] as bool? ?? false,
      exoticWeaponHash: payload['exoticWeaponHash'] as int?,
      exoticWeaponName: payload['exoticWeaponName'] as String?,
      setPinnedSuper: payload['setPinnedSuper'] as bool? ?? false,
      pinnedSuper: payload['pinnedSuper'] as String?,
      existingExoticArmorSlot: payload['existingExoticArmorSlot'] as String?,
      nextExoticArmorSlot: payload['nextExoticArmorSlot'] as String?,
      identityAction: action,
    );
  }

  void _refreshComposeHardBlocks({
    int? exoticArmorHash,
    int? exoticWeaponHash,
    SubclassKit? subclass,
    int? synergyCount,
  }) {
    final sel = _selected;
    final kit = subclass ?? _editSubclass;
    final aspects = kit.aspects
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    final fragments = kit.fragments
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    final cap = _resolveFragmentCapacityLocal(aspects);
    final armor = exoticArmorHash ?? sel?.build.exoticArmorHash;
    final weapon = exoticWeaponHash ?? sel?.build.exoticWeaponHash;
    _composeHardBlocks = evaluateComposeHardBlocks(
      ComposeHardBlockInput(
        exoticWeaponHashes: [
          if (weapon != null) weapon,
        ],
        exoticArmorHashes: [
          if (armor != null) armor,
        ],
        aspectCount: aspects.length,
        fragmentCount: fragments.length,
        fragmentCapacity: cap.capacity,
        capacityResolved: cap.resolved,
        synergyTypeCount: synergyCount ??
            (sel?.build.synergyTypes.isEmpty == true
                ? 0
                : (_editDraftTypes.isEmpty
                    ? (sel?.build.synergyTypes.length ?? 0)
                    : _editDraftTypes.length)),
      ),
    );
  }

  ({int capacity, bool resolved}) _resolveFragmentCapacityLocal(
    List<String> aspects,
  ) {
    if (aspects.isEmpty) {
      return (capacity: 0, resolved: true);
    }
    final items = catalogItems;
    if (items == null || items.isEmpty) {
      return (capacity: 0, resolved: false);
    }
    var sum = 0;
    var resolved = 0;
    for (final name in aspects) {
      final match = items.where(
        (i) =>
            i.name.toLowerCase() == name.toLowerCase() &&
            (i.sourceStore ?? '') == 'aspects',
      );
      if (match.isEmpty) continue;
      // fragmentCapacity not on CatalogItem — unresolved per aspect unless
      // description encodes +N. Prefer unknown when no capacity meta.
      resolved += 1;
      final desc = match.first.description ?? '';
      final m = RegExp(r'\+(\d+)\s*frag', caseSensitive: false).firstMatch(desc);
      if (m != null) {
        sum += int.tryParse(m.group(1)!) ?? 0;
      }
    }
    if (resolved == 0) {
      return (capacity: 0, resolved: false);
    }
    // If we matched aspects but no capacity tokens, treat unresolved.
    if (sum == 0 && resolved < aspects.length) {
      return (capacity: sum, resolved: false);
    }
    if (sum == 0 && resolved == aspects.length) {
      // Matched all by name without capacity tokens → unknown.
      return (capacity: 0, resolved: false);
    }
    return (capacity: sum, resolved: resolved == aspects.length);
  }

  // ---------------------------------------------------------------------------
  // DART-033: Variants, attachments, slot pins
  // ---------------------------------------------------------------------------

  /// Select a variant on the current build for compose.
  Future<void> selectVariant(String? variantId) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null || variantId == null) {
      _selectedVariant = null;
      _attachments = const [];
      _slotPins = const [];
      _coverage = null;
      notifyListeners();
      return;
    }
    VariantRecord? match;
    for (final v in sel.variants) {
      if (v.id == variantId) {
        match = v;
        break;
      }
    }
    _selectedVariant = match;
    if (match != null) {
      await _loadComposeForVariant(uid, sel.build.id, match.id);
    } else {
      _attachments = const [];
      _slotPins = const [];
      _coverage = null;
    }
    notifyListeners();
  }

  /// Create a non-default named variant; selects it on success.
  Future<String?> createVariant({required String name}) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No build selected';
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      const msg = 'Variant name cannot be empty';
      _error = msg;
      notifyListeners();
      return msg;
    }
    try {
      final created = await createUserVariant(
        db,
        uid,
        sel.build.id,
        CreateVariantCommand(name: trimmed),
      );
      if (created == null) {
        return 'Build not found';
      }
      final detail = await getBuildDetail(db, uid, sel.build.id);
      _selected = detail;
      if (detail != null) {
        await _syncComposeAfterBuildLoad(detail, preferredVariantId: created.id);
      }
      _error = null;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Attach a library set (live) to the selected variant.
  ///
  /// Merges with existing attachments; hard gates + rollback via
  /// [updateUserVariant]. Returns error message or null.
  Future<String?> attachSet(
    String setId, {
    AttachmentMode mode = AttachmentMode.live,
  }) async {
    final sel = _selected;
    final variant = _selectedVariant;
    final uid = _userId;
    if (sel == null || variant == null || uid == null) {
      return 'No variant selected';
    }
    final id = setId.trim();
    if (id.isEmpty) {
      return 'Set id required';
    }
    if (_attachments.any((a) => a.record.setId == id)) {
      const msg = 'Set is already attached';
      _error = msg;
      notifyListeners();
      return msg;
    }

    final next = <SetAttachmentInput>[
      for (final a in _attachments)
        SetAttachmentInput(
          setId: a.record.setId,
          mode: parseAttachmentModeWire(a.record.mode),
          snapshotConfigs: a.record.snapshotConfigs,
        ),
      SetAttachmentInput(setId: id, mode: mode),
    ];

    return _replaceAttachments(sel.build.id, variant.id, next);
  }

  /// Detach a set from the selected variant.
  Future<String?> detachSet(String setId) async {
    final sel = _selected;
    final variant = _selectedVariant;
    final uid = _userId;
    if (sel == null || variant == null || uid == null) {
      return 'No variant selected';
    }
    final next = <SetAttachmentInput>[
      for (final a in _attachments)
        if (a.record.setId != setId)
          SetAttachmentInput(
            setId: a.record.setId,
            mode: parseAttachmentModeWire(a.record.mode),
            snapshotConfigs: a.record.snapshotConfigs,
          ),
    ];
    return _replaceAttachments(sel.build.id, variant.id, next);
  }

  /// Pin or clear instance on a live-attached set slot.
  ///
  /// [instanceId] null/empty → wishlist. Returns error or null.
  Future<String?> pinSlot({
    required String setId,
    required String slot,
    String? instanceId,
    String? setItemId,
  }) async {
    final uid = _userId;
    final variant = _selectedVariant;
    if (uid == null || variant == null) {
      return 'No variant selected';
    }

    final att = _attachments.where((a) => a.record.setId == setId).toList();
    if (att.isEmpty) {
      return 'Set is not attached';
    }
    if (att.single.record.mode != AttachmentMode.live.wireName) {
      const msg = 'Pin edit requires live attachment (snapshot is display-only)';
      _error = msg;
      notifyListeners();
      return msg;
    }

    try {
      final detail = await getSetDetail(db, uid, setId);
      if (detail == null) {
        return 'Set not found';
      }
      final active = detail.activeItems;
      SetItemRecord? item;
      if (setItemId != null) {
        for (final i in active) {
          if (i.id == setItemId) {
            item = i;
            break;
          }
        }
      }
      item ??= () {
        for (final i in active) {
          if (i.slot == slot) return i;
        }
        return null;
      }();
      if (item == null) {
        return 'Slot item not found on set';
      }

      final pin = instanceId?.trim();
      // Omit id so repo allocates a new row id after soft-removing the active
      // occupant (reusing the old id hits UNIQUE on set_items.id).
      final updated = await upsertUserSetItem(
        db,
        uid,
        setId,
        UpsertSetItemCommand(
          slot: item.slot,
          itemHash: item.itemHash,
          itemName: item.itemName,
          instanceId: (pin == null || pin.isEmpty) ? null : pin,
          selectedPerks: item.selectedPerks,
          masterworkHash: item.masterworkHash,
          modHashes: item.modHashes,
          sortOrder: item.sortOrder,
          replaceExisting: true,
        ),
      );
      if (updated == null) {
        return 'Set not found';
      }

      final sel = _selected;
      if (sel != null) {
        await _loadComposeForVariant(uid, sel.build.id, variant.id);
      }
      _error = null;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> _replaceAttachments(
    String buildId,
    String variantId,
    List<SetAttachmentInput> next,
  ) async {
    final uid = _userId;
    if (uid == null) return 'No user';
    try {
      await updateUserVariant(
        db,
        uid,
        buildId,
        variantId,
        UpdateVariantCommand(attachments: next),
      );
      final detail = await getBuildDetail(db, uid, buildId);
      _selected = detail;
      if (detail != null) {
        await _syncComposeAfterBuildLoad(detail, preferredVariantId: variantId);
      }
      _error = null;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      // Reload compose so UI matches rolled-back DB state.
      try {
        await _loadComposeForVariant(uid, buildId, variantId);
      } catch (_) {}
      final msg = formatComposeError(e.message);
      _error = msg;
      notifyListeners();
      return msg;
    } catch (e) {
      try {
        await _loadComposeForVariant(uid, buildId, variantId);
      } catch (_) {}
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // DART-034: Soft coverage chips + soft stat targets (display only)
  // ---------------------------------------------------------------------------

  /// Re-query soft coverage for the selected variant without mutating kit.
  ///
  /// Soft only — never auto-applies attachments, pins, or targets.
  Future<void> refreshSoftCoverage() async {
    final sel = _selected;
    final variant = _selectedVariant;
    final uid = _userId;
    if (sel == null || variant == null || uid == null) {
      _coverage = null;
      notifyListeners();
      return;
    }
    await _loadSoftCoverage(uid, sel.build.id, variant.id);
    notifyListeners();
  }

  /// Explicit save of soft stat targets on the selected build.
  ///
  /// Never called automatically from coverage evaluation or nudges.
  Future<String?> saveSoftStatTargets(SoftStatTargets targets) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No build selected';
    }
    try {
      final normalized = normalizeSoftStatTargets(targets);
      final priorVariantId = _selectedVariant?.id;
      final updated = await updateUserBuild(
        db,
        uid,
        sel.build.id,
        UpdateBuildCommand(softStatTargets: normalized),
      );
      if (updated == null) {
        return 'Build not found';
      }
      _selected = updated;
      _softStatTargets = softStatTargetsFromJson(updated.build.softStatTargets);
      _builds = await listUserBuilds(db, uid);
      await _syncComposeAfterBuildLoad(
        updated,
        preferredVariantId: priorVariantId,
      );
      _error = null;
      notifyListeners();
      return null;
    } on SoftStatTargetsException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } on UseCaseException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Save soft targets from wire-name text fields (UI).
  Future<String?> saveSoftStatTargetsFromFields(Map<String, String> fields) async {
    try {
      final targets = softStatTargetsFromFieldMap(fields);
      return saveSoftStatTargets(targets);
    } on FormatException catch (e) {
      final msg = e.message;
      _error = msg;
      notifyListeners();
      return msg;
    }
  }

  void _clearCompose() {
    _selectedVariant = null;
    _attachments = const [];
    _slotPins = const [];
    _attachableSets = const [];
    _coverage = null;
    _softStatTargets = const SoftStatTargets();
  }

  Future<void> _syncComposeAfterBuildLoad(
    BuildDetail detail, {
    String? preferredVariantId,
  }) async {
    final uid = _userId;
    if (uid == null) {
      _clearCompose();
      return;
    }
    _attachableSets = await listUserSets(db, uid);

    VariantRecord? pick;
    if (preferredVariantId != null) {
      for (final v in detail.variants) {
        if (v.id == preferredVariantId) {
          pick = v;
          break;
        }
      }
    }
    if (pick == null && detail.variants.isNotEmpty) {
      VariantRecord? def;
      for (final v in detail.variants) {
        if (v.isDefault) {
          def = v;
          break;
        }
      }
      pick = def ?? detail.variants.first;
    }

    _softStatTargets =
        softStatTargetsFromJson(detail.build.softStatTargets);

    _selectedVariant = pick;
    if (pick != null) {
      await _loadComposeForVariant(uid, detail.build.id, pick.id);
    } else {
      _attachments = const [];
      _slotPins = const [];
      _coverage = null;
    }
  }

  Future<void> _loadComposeForVariant(
    int userId,
    String buildId,
    String variantId,
  ) async {
    final atts = await getVariantAttachments(db, variantId);
    final views = <AttachmentView>[];
    for (final a in atts) {
      final set = await getSet(db, userId, a.setId);
      views.add(
        AttachmentView(
          record: a,
          setName: set?.name,
          setType: set?.type,
        ),
      );
    }
    _attachments = views;

    final expanded = await expandAttachmentsToItems(db, userId, atts);
    final pins = <SlotPinView>[];
    for (final item in expanded) {
      String? setItemId;
      String mode = AttachmentMode.live.wireName;
      for (final a in atts) {
        if (a.setId == item.setId) {
          mode = a.mode;
          break;
        }
      }
      if (mode == AttachmentMode.live.wireName) {
        final active = await listActiveSetItems(db, item.setId);
        for (final si in active) {
          if (si.slot == item.slot.wireName && si.itemHash == item.itemHash) {
            setItemId = si.id;
            break;
          }
        }
      }
      pins.add(
        SlotPinView(
          slot: item.slot.wireName,
          itemHash: item.itemHash,
          itemName: item.itemName,
          setId: item.setId,
          attachmentMode: mode,
          instanceId: item.instanceId,
          setItemId: setItemId,
        ),
      );
    }
    // Stable order by slot wire name.
    pins.sort((a, b) => a.slot.compareTo(b.slot));
    _slotPins = pins;

    // Keep selectedVariant pointer fresh from detail if available.
    final sel = _selected;
    if (sel != null) {
      for (final v in sel.variants) {
        if (v.id == variantId) {
          _selectedVariant = v;
          break;
        }
      }
      _softStatTargets =
          softStatTargetsFromJson(sel.build.softStatTargets);
    }

    // Soft coverage: display only — does not mutate attachments/pins/targets.
    await _loadSoftCoverage(userId, buildId, variantId);
  }

  Future<void> _loadSoftCoverage(
    int userId,
    String buildId,
    String variantId,
  ) async {
    try {
      _coverage = await queryVariantCoverage(
        db,
        userId,
        buildId,
        variantId,
        statEstimate: softStatEstimateOverride,
      );
    } catch (_) {
      // Soft query failure must not break compose; leave prior or null.
      _coverage = null;
    }
  }

  List<DraftSynergyType> _recordsToDrafts(
    List<SynergyTypeDesignationRecord> rows,
  ) {
    return [
      for (final r in rows) DraftSynergyType(type: r.type, subType: r.subType),
    ];
  }

  // ---------------------------------------------------------------------------
  // DART-067: Finish walkthrough Create / Capture / fill (BR-BLD-008)
  // ---------------------------------------------------------------------------

  bool _finishBusy = false;
  FinishWalkthroughStep _finishStep = FinishWalkthroughStep.overview;
  FinishCategory? _finishActiveCategory;
  String? _finishFillSlot;
  final Set<String> _finishSkipped = {};
  String? _finishMessage;

  bool get finishBusy => _finishBusy;
  FinishWalkthroughStep get finishStep => _finishStep;
  FinishCategory? get finishActiveCategory => _finishActiveCategory;
  String? get finishFillSlot => _finishFillSlot;
  Set<String> get finishSkipped => Set.unmodifiable(_finishSkipped);
  String? get finishMessage => _finishMessage;

  FinishGap? get finishActiveGap {
    final gaps = finishGaps;
    if (gaps == null) return null;
    if (_finishActiveCategory != null) {
      for (final g in gaps.gaps) {
        if (g.category == _finishActiveCategory) return g;
      }
    }
    return gaps.nextActionable;
  }

  FinishPostMutationTarget? get finishPostMutationTarget {
    final gap = finishActiveGap;
    return resolvePostMutationStep(
      ResolvePostMutationStepInput(gap: gap, preferArmorOptimize: true),
    );
  }

  FinishGap? _gapFor(FinishCategory cat) {
    final gaps = finishGaps;
    if (gaps == null) return null;
    for (final g in gaps.gaps) {
      if (g.category == cat) return g;
    }
    return null;
  }

  void openFinishCategory(FinishCategory cat) {
    _finishActiveCategory = cat;
    _finishMessage = null;
    final target = resolvePostMutationStep(
      ResolvePostMutationStepInput(
        gap: _gapFor(cat),
        preferArmorOptimize: true,
      ),
    );
    _applyFinishTarget(target, fallbackCategory: cat);
    notifyListeners();
  }

  void skipFinishCategory(FinishCategory cat) {
    _finishSkipped.add(cat.wireName);
    _finishMessage = '${finishCategoryLabel(cat)} skipped for now';
    _finishStep = FinishWalkthroughStep.overview;
    _finishActiveCategory = null;
    _finishFillSlot = null;
    notifyListeners();
  }

  void backToFinishOverview() {
    _finishStep = FinishWalkthroughStep.overview;
    _finishActiveCategory = null;
    _finishFillSlot = null;
    notifyListeners();
  }

  void openFinishFillFirstEmpty() {
    final gap = finishActiveGap;
    if (gap == null || gap.coveringSetId == null) return;
    if (gap.coveringMode != AttachmentMode.live) return;
    final slot = firstEmptyRequiredSlot(gap);
    if (slot == null) return;
    _finishFillSlot = slot;
    _finishStep = FinishWalkthroughStep.fill;
    notifyListeners();
  }

  void openFinishArmorOptimize() {
    final gap = finishActiveGap;
    if (gap == null || gap.category != FinishCategory.armor) return;
    if (gap.coveringSetId == null || gap.coveringMode != AttachmentMode.live) {
      return;
    }
    _finishStep = FinishWalkthroughStep.armorOptimize;
    _finishFillSlot = null;
    notifyListeners();
  }

  void _applyFinishTarget(
    FinishPostMutationTarget target, {
    FinishCategory? fallbackCategory,
  }) {
    final gaps = finishGaps;
    if (gaps != null && gaps.complete) {
      _finishStep = FinishWalkthroughStep.done;
      _finishActiveCategory = null;
      _finishFillSlot = null;
      return;
    }
    _finishFillSlot = target.fillSlot;
    if (target.step == FinishWalkthroughStep.overview) {
      _finishStep = FinishWalkthroughStep.overview;
      _finishActiveCategory = null;
      return;
    }
    _finishStep = target.step;
    _finishActiveCategory = target.category ?? fallbackCategory;
  }

  Future<void> _refreshSelectedCompose() async {
    final sel = _selected;
    final uid = _userId;
    final variantId = _selectedVariant?.id;
    if (sel == null || uid == null || variantId == null) return;
    final detail = await getBuildDetail(db, uid, sel.build.id);
    _selected = detail;
    if (detail != null) {
      await _syncComposeAfterBuildLoad(detail, preferredVariantId: variantId);
    }
  }

  /// One-tap Create empty set + live attach (no name/tag chrome).
  Future<String?> oneTapCreateCategory(FinishCategory category) async {
    final sel = _selected;
    final variant = _selectedVariant;
    final uid = _userId;
    if (sel == null || variant == null || uid == null) {
      return 'No variant selected';
    }
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
    _finishMessage = null;
    _error = null;
    notifyListeners();
    try {
      final type = finishCategoryToSetType(category);
      final result = await createSetAndAttach(
        db,
        uid,
        CreateSetAndAttachCommand(
          buildId: sel.build.id,
          variantId: variant.id,
          type: type,
          attachNow: true,
          optimizerConstraints: type == SetType.armor
              ? serializeOptimizerConstraints(
                  seedConstraintsFromBuild(
                    exoticArmorHash: sel.build.exoticArmorHash,
                    softStatTargets: {
                      for (final e in sel.build.softStatTargets.entries)
                        if (e.value is int) e.key: e.value as int,
                    },
                  ),
                )
              : null,
        ),
      );
      await _refreshSelectedCompose();
      _finishActiveCategory = category;
      _finishMessage = 'Created ${result.set.set.name}';
      final target = resolvePostMutationStep(
        ResolvePostMutationStepInput(
          gap: _gapFor(category),
          preferArmorOptimize: true,
        ),
      );
      _applyFinishTarget(target, fallbackCategory: category);
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      _error = e.message;
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      _error = e.toString();
      _finishMessage = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Capture resolved gear claims for [category] into a set + live attach.
  Future<String?> captureCategory(FinishCategory category) async {
    final sel = _selected;
    final variant = _selectedVariant;
    final uid = _userId;
    if (sel == null || variant == null || uid == null) {
      return 'No variant selected';
    }
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
    _finishMessage = null;
    notifyListeners();
    try {
      final claims = <CaptureClaim>[];
      final slots = category == FinishCategory.armor
          ? EquipmentSlot.armorSlots
          : category == FinishCategory.weapon
              ? EquipmentSlot.weaponSlots
              : const <EquipmentSlot>[];
      final slotSet = {for (final s in slots) s.wireName};
      for (final pin in _slotPins) {
        if (!slotSet.contains(pin.slot)) continue;
        claims.add(
          CaptureClaim(
            slot: pin.slot,
            itemHash: pin.itemHash,
            itemName: pin.itemName,
            instanceId: pin.instanceId,
          ),
        );
      }
      final result = await createSetsFromBuild(
        db,
        uid,
        CreateSetsFromBuildCommand(
          buildId: sel.build.id,
          variantId: variant.id,
          categories: [category],
          claimsByCategory: {category: claims},
          attachNow: true,
        ),
      );
      await _refreshSelectedCompose();
      final names = result.createdSets.map((s) => s.name).join(', ');
      _finishMessage = names.isEmpty ? 'Capture finished' : 'Captured $names';
      _finishActiveCategory = category;
      final target = resolvePostMutationStep(
        ResolvePostMutationStepInput(
          gap: _gapFor(category),
          preferArmorOptimize: true,
        ),
      );
      _applyFinishTarget(target, fallbackCategory: category);
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      _error = e.message;
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      _error = e.toString();
      _finishMessage = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Fill one required slot on the live covering set (catalog pick).
  Future<String?> fillFinishSlot({
    required String setId,
    required String slot,
    required int itemHash,
    required String itemName,
    String? instanceId,
    List<int> selectedPerks = const [],
  }) async {
    final uid = _userId;
    if (uid == null) return 'No user';
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
    _finishMessage = null;
    notifyListeners();
    try {
      final updated = await upsertUserSetItem(
        db,
        uid,
        setId,
        UpsertSetItemCommand(
          slot: slot,
          itemHash: itemHash,
          itemName: itemName,
          instanceId: instanceId,
          selectedPerks: selectedPerks,
          replaceExisting: true,
        ),
      );
      if (updated == null) {
        _finishBusy = false;
        return 'Set not found';
      }
      await _refreshSelectedCompose();
      _finishMessage = 'Filled $slot';
      final cat = _finishActiveCategory;
      final target = resolvePostMutationStep(
        ResolvePostMutationStepInput(
          gap: cat == null ? null : _gapFor(cat),
          preferArmorOptimize: true,
        ),
      );
      _applyFinishTarget(target, fallbackCategory: cat);
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// After armor kit apply from Finish optimizer — re-evaluate gaps.
  Future<void> afterFinishArmorApplied() async {
    await _refreshSelectedCompose();
    _finishMessage = 'Armor kit applied';
    final target = resolvePostMutationStep(
      ResolvePostMutationStepInput(
        gap: _gapFor(FinishCategory.armor),
        preferArmorOptimize: true,
      ),
    );
    _applyFinishTarget(target, fallbackCategory: FinishCategory.armor);
    notifyListeners();
  }
}
