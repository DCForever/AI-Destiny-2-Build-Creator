/// Builds list + compose orchestration for Jaspr web (DART-046).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/jaspr.dart';

import '../compose/build_format.dart';
import '../compose/finish_gaps_format.dart';
import '../compose/soft_guidance_format.dart';
import '../compose/variant_compose_format.dart';

/// Stable offline library owner when the user is signed out (DART-046).
const String kLocalLibraryMembershipId = 'local-library';

/// Draft synergy type for create UI.
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

  String get designationKey => formatSynergyDesignationKey(type, subType);

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

/// One expanded equipment slot pin for compose display.
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

/// In-process orchestration for web Builds list + compose spine.
///
/// Soft guidance never auto-applies; hard DBR blocks stay hard.
class BuildsController extends ChangeNotifier {
  BuildsController({required this.db});

  final AppDatabase db;

  int? _userId;
  List<BuildRecord> _builds = const [];
  BuildDetail? _selected;
  String? _error;
  bool _loading = false;

  List<DraftSynergyType> _createDraftTypes = const [];

  VariantRecord? _selectedVariant;
  List<AttachmentView> _attachments = const [];
  List<SlotPinView> _slotPins = const [];
  List<SetRecord> _attachableSets = const [];

  CoverageQueryResult? _coverage;
  SoftStatTargets _softStatTargets = const SoftStatTargets();

  /// Optional estimate for soft-stat warnings (tests may inject).
  StatEstimate? softStatEstimateOverride;

  // DART-064 identity confirm + subclass kit + hard blocks
  SubclassKit _editSubclass = const SubclassKit();
  List<DraftSynergyType> _editDraftTypes = const [];
  List<String>? _pendingIdentityFields;
  List<ComposeHardBlock> _composeHardBlocks = const [];
  String? _lastForkedFromId;

  /// Optional catalog base for Manifest pickers (tests / entity loader inject).
  List<CatalogItem>? catalogItems;

  int? get userId => _userId;
  List<BuildRecord> get builds => List.unmodifiable(_builds);
  BuildDetail? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  List<DraftSynergyType> get createDraftTypes =>
      List.unmodifiable(_createDraftTypes);

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
  List<DraftSynergyType> get editDraftTypes =>
      List.unmodifiable(_editDraftTypes);
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
    final resolved = aspects.isEmpty;
    return formatSubclassCapacityCaption(
      aspectCount: aspects.length,
      fragmentCount: fragments.length,
      fragmentCapacity: 0,
      capacityResolved: resolved,
    );
  }

  void setEditSubclass(SubclassKit kit) {
    _editSubclass = kit;
    _refreshComposeHardBlocks();
    notifyListeners();
  }

  void cancelIdentityConfirm() {
    _pendingIdentityFields = null;
    notifyListeners();
  }

  void _refreshComposeHardBlocks({
    int? exoticArmorHash,
    int? exoticWeaponHash,
    int? synergyCount,
  }) {
    final sel = _selected;
    final kit = _editSubclass;
    final aspects = kit.aspects
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    final fragments = kit.fragments
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    final armor = exoticArmorHash ?? sel?.build.exoticArmorHash;
    final weapon = exoticWeaponHash ?? sel?.build.exoticWeaponHash;
    _composeHardBlocks = evaluateComposeHardBlocks(
      ComposeHardBlockInput(
        exoticWeaponHashes: [if (weapon != null) weapon],
        exoticArmorHashes: [if (armor != null) armor],
        aspectCount: aspects.length,
        fragmentCount: fragments.length,
        fragmentCapacity: 0,
        capacityResolved: aspects.isEmpty,
        synergyTypeCount: synergyCount ??
            (_editDraftTypes.isNotEmpty
                ? _editDraftTypes.length
                : (sel?.build.synergyTypes.length ?? 0)),
      ),
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

  String titleOf(BuildRecord b) => formatBuildListTitle(b.name);

  String synergySummaryOf(BuildRecord b) => formatSynergyDesignationList([
        for (final d in b.synergyTypes) (type: d.type, subType: d.subType),
      ]);

  String identitySummaryOf(BuildRecord b) => formatIdentitySummary(
        className: b.className,
        pinnedSuper: b.pinnedSuper,
      );

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _builds = await listUserBuilds(db, _userId!);
      if (_selected != null) {
        final id = _selected!.build.id;
        final priorVariantId = _selectedVariant?.id;
        final next = await getBuildDetail(db, _userId!, id);
        _selected = next;
        if (next != null) {
          await _syncComposeAfterBuildLoad(
            next,
            preferredVariantId: priorVariantId,
          );
        } else {
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
    final local = await ensureUser(
      db,
      bungieMembershipId: kLocalLibraryMembershipId,
      membershipType: 0,
      displayName: 'Local library',
    );
    return local.id;
  }

  Future<BuildDetail?> openBuild(String buildId) async {
    _error = null;
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final detail = await getBuildDetail(db, uid, buildId);
      _selected = detail;
      if (detail != null) {
        _editSubclass = subclassKitFromJson(detail.build.subclass);
        _editDraftTypes = [
          for (final d in detail.build.synergyTypes)
            DraftSynergyType(type: d.type, subType: d.subType),
        ];
        _pendingIdentityFields = null;
        _refreshComposeHardBlocks();
        await _syncComposeAfterBuildLoad(detail);
      } else {
        _clearCompose();
      }
      notifyListeners();
      return detail;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update identity with DBR-ID-008 Confirm/Fork + subclass kit (DART-064).
  Future<String?> updateSelectedIdentity({
    String? name,
    SubclassKit? subclass,
    bool setExoticArmor = false,
    int? exoticArmorHash,
    String? exoticArmorName,
    bool setExoticWeapon = false,
    int? exoticWeaponHash,
    String? exoticWeaponName,
    bool setPinnedSuper = false,
    String? pinnedSuper,
    IdentityAction? identityAction,
  }) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) return 'No build selected';

    final types = _editDraftTypes.isNotEmpty
        ? _editDraftTypes
        : [
            for (final d in sel.build.synergyTypes)
              DraftSynergyType(type: d.type, subType: d.subType),
          ];
    if (types.isEmpty) {
      const msg = 'At least one synergy type is required';
      _error = msg;
      notifyListeners();
      return msg;
    }
    final kit = subclass ?? _editSubclass;
    _editSubclass = kit;
    _refreshComposeHardBlocks(
      exoticArmorHash: setExoticArmor ? exoticArmorHash : null,
      exoticWeaponHash: setExoticWeapon ? exoticWeaponHash : null,
      synergyCount: types.length,
    );
    if (identitySaveHardBlocked &&
        (identityAction == null || identityAction == IdentityAction.confirm)) {
      final msg = _composeHardBlocks.map((b) => b.message).join('; ');
      _error = msg;
      notifyListeners();
      return msg;
    }

    try {
      final priorVariantId = _selectedVariant?.id;
      final updated = await updateUserBuild(
        db,
        uid,
        sel.build.id,
        UpdateBuildCommand(
          name: name,
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
        ),
      );
      if (updated == null) return 'Build not found';
      _pendingIdentityFields = null;
      _lastForkedFromId = updated.forkedFromId;
      _selected = updated;
      _editSubclass = subclassKitFromJson(updated.build.subclass);
      _editDraftTypes = [
        for (final d in updated.build.synergyTypes)
          DraftSynergyType(type: d.type, subType: d.subType),
      ];
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

  void clearSelection() {
    _selected = null;
    _clearCompose();
    notifyListeners();
  }

  void addCreateDraftType(String type, [String? subType]) {
    final draft = DraftSynergyType(type: type.trim(), subType: subType);
    if (draft.type.isEmpty) return;
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

    _softStatTargets = softStatTargetsFromJson(detail.build.softStatTargets);

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
    pins.sort((a, b) => a.slot.compareTo(b.slot));
    _slotPins = pins;

    final sel = _selected;
    if (sel != null) {
      for (final v in sel.variants) {
        if (v.id == variantId) {
          _selectedVariant = v;
          break;
        }
      }
      _softStatTargets = softStatTargetsFromJson(sel.build.softStatTargets);
    }

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
      _coverage = null;
    }
  }
}
