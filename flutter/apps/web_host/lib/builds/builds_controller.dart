/// Builds list + compose for Jaspr web — thin wrap of [BuildsComposeSession].
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/jaspr.dart';

import '../compose/build_format.dart';

export 'package:destiny2_app/destiny2_app.dart'
    show AttachmentView, DraftSynergyType, SlotPinView, kLocalLibraryMembershipId;

/// Web Builds — [BuildsComposeSession] for list/compose; identity + finish host extras.
class BuildsController extends ChangeNotifier {
  BuildsController({required this.db}) {
    core = BuildsComposeSession(db: db);
    core.addListener(notifyListeners);
  }

  final AppDatabase db;
  late final BuildsComposeSession core;

  /// Optional catalog base for Manifest pickers (tests / entity loader inject).
  List<CatalogItem>? catalogItems;

  // --- Identity / hard-block host state ---
  List<DraftSynergyType> _editDraftTypes = const [];
  SubclassKit _editSubclass = const SubclassKit();
  List<String>? _pendingIdentityFields;
  List<ComposeHardBlock> _composeHardBlocks = const [];
  String? _lastForkedFromId;

  // --- Finish walkthrough host state ---
  bool _finishBusy = false;
  FinishCategory? _finishActiveCategory;
  String? _finishMessage;
  final Set<String> _finishSkipped = {};

  // --- Compose delegation ---
  int? get userId => core.userId;
  List<BuildRecord> get builds => core.builds;
  BuildDetail? get selected => core.selected;
  String? get error => core.error;
  bool get loading => core.loading;
  List<DraftSynergyType> get createDraftTypes => core.createDraftTypes;
  VariantRecord? get selectedVariant => core.selectedVariant;
  List<VariantRecord> get variants => core.variants;
  List<AttachmentView> get attachments => core.attachments;
  List<SlotPinView> get slotPins => core.slotPins;
  List<SetRecord> get attachableSets => core.attachableSets;
  CoverageQueryResult? get coverage => core.coverage;
  CoverageResult get coverageResult => core.coverageResult;
  List<SynergyCoverageRow> get synergyCoverageRows => core.synergyCoverageRows;
  List<SetBonusSoftRow> get setBonusSoftRows => core.setBonusSoftRows;
  List<ElementSoftMismatch> get elementSoftMismatches =>
      core.elementSoftMismatches;
  List<SoftStatWarningRow> get softStatWarnings => core.softStatWarnings;
  SoftStatTargets get softStatTargets => core.softStatTargets;
  String get softStatTargetsSummary => core.softStatTargetsSummary;
  bool get hasSoftMisses => core.hasSoftMisses;
  String get softGuidanceAdvisory => core.softGuidanceAdvisory;
  ThreeGateStatus? get threeGate => core.threeGate;
  FinishGapsResult? get finishGaps => core.finishGaps;
  bool get finishComplete => finishGaps?.complete ?? false;

  StatEstimate? get softStatEstimateOverride => core.softStatEstimateOverride;
  set softStatEstimateOverride(StatEstimate? v) =>
      core.softStatEstimateOverride = v;
  Map<int, String>? get coverageWeaponElementByHash =>
      core.coverageWeaponElementByHash;
  set coverageWeaponElementByHash(Map<int, String>? v) =>
      core.coverageWeaponElementByHash = v;
  Map<int, SetBonusRecord>? get coverageSetBonusByItemHash =>
      core.coverageSetBonusByItemHash;
  set coverageSetBonusByItemHash(Map<int, SetBonusRecord>? v) =>
      core.coverageSetBonusByItemHash = v;

  List<DraftSynergyType> get editDraftTypes =>
      List.unmodifiable(_editDraftTypes);
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
    return formatSubclassCapacityCaption(
      aspectCount: aspects.length,
      fragmentCount: fragments.length,
      fragmentCapacity: 0,
      capacityResolved: aspects.isEmpty,
    );
  }

  String titleOf(BuildRecord b) => formatBuildListTitle(b.name);
  String synergySummaryOf(BuildRecord b) => formatSynergyDesignationList([
        for (final d in b.synergyTypes) (type: d.type, subType: d.subType),
      ]);
  String identitySummaryOf(BuildRecord b) => formatIdentitySummary(
        className: b.className,
        pinnedSuper: b.pinnedSuper,
      );

  Future<void> refresh() => core.refresh();
  Future<int> resolveLibraryUserId() => core.resolveLibraryUserId();

  Future<BuildDetail?> openBuild(String buildId) async {
    final d = await core.openBuild(buildId);
    if (d != null) {
      _editDraftTypes = [
        for (final x in d.build.synergyTypes)
          DraftSynergyType(type: x.type, subType: x.subType),
      ];
      _editSubclass = subclassKitFromJson(d.build.subclass);
      _pendingIdentityFields = null;
      _refreshComposeHardBlocks();
    } else {
      _editDraftTypes = const [];
      _editSubclass = const SubclassKit();
    }
    return d;
  }

  void clearSelection() {
    core.clearSelection();
    _editDraftTypes = const [];
    _editSubclass = const SubclassKit();
    _pendingIdentityFields = null;
  }

  void addCreateDraftType(String type, [String? subType]) =>
      core.addCreateDraftType(type, subType);
  void removeCreateDraftTypeAt(int index) =>
      core.removeCreateDraftTypeAt(index);
  void clearCreateDraftTypes() => core.clearCreateDraftTypes();

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
    final err = await core.createBuild(
      name: name,
      className: className,
      exoticArmorHash: exoticArmorHash,
      exoticArmorName: exoticArmorName,
      exoticWeaponHash: exoticWeaponHash,
      exoticWeaponName: exoticWeaponName,
      pinnedSuper: pinnedSuper,
      synergyTypes: synergyTypes,
    );
    final created = selected;
    if (err == null && created != null) {
      _editDraftTypes = [
        for (final x in created.build.synergyTypes)
          DraftSynergyType(type: x.type, subType: x.subType),
      ];
      _editSubclass = subclassKitFromJson(created.build.subclass);
      _refreshComposeHardBlocks();
    }
    return err;
  }

  Future<void> selectVariant(String? variantId) =>
      core.selectVariant(variantId);
  Future<String?> createVariant({required String name}) =>
      core.createVariant(name: name);
  Future<String?> attachSet(
    String setId, {
    AttachmentMode mode = AttachmentMode.live,
  }) =>
      core.attachSet(setId, mode: mode);
  Future<String?> detachSet(String setId) => core.detachSet(setId);
  Future<String?> pinSlot({
    required String setId,
    required String slot,
    String? instanceId,
    String? setItemId,
  }) =>
      core.pinSlot(
        setId: setId,
        slot: slot,
        instanceId: instanceId,
        setItemId: setItemId,
      );
  Future<void> refreshSoftCoverage() => core.refreshSoftCoverage();
  Future<String?> saveSoftStatTargets(SoftStatTargets targets) =>
      core.saveSoftStatTargets(targets);
  Future<String?> saveSoftStatTargetsFromFields(Map<String, String> fields) =>
      core.saveSoftStatTargetsFromFields(fields);

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
    final sel = selected;
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
    final sel = selected;
    final uid = userId;
    if (sel == null || uid == null) return 'No build selected';

    final types = _editDraftTypes.isNotEmpty
        ? _editDraftTypes
        : [
            for (final d in sel.build.synergyTypes)
              DraftSynergyType(type: d.type, subType: d.subType),
          ];
    if (types.isEmpty) {
      const msg = 'At least one synergy type is required';
      core.reportError(msg);
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
      core.reportError(msg);
      notifyListeners();
      return msg;
    }

    try {
      final priorVariantId = selectedVariant?.id;
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
      await core.reloadBuildList();
      await core.openBuild(updated.build.id);
      if (priorVariantId != null) {
        await core.selectVariant(priorVariantId);
      }
      _editSubclass = subclassKitFromJson(updated.build.subclass);
      _editDraftTypes = [
        for (final d in updated.build.synergyTypes)
          DraftSynergyType(type: d.type, subType: d.subType),
      ];
      core.reportError(null);
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      if (e.code == UseCaseErrorCode.identityConfirmRequired) {
        final fields = e.details['identityFields'];
        _pendingIdentityFields = fields is List
            ? [for (final f in fields) f.toString()]
            : const ['identity'];
        core.reportError(e.message);
        notifyListeners();
        return e.message;
      }
      core.reportError(e.message);
      notifyListeners();
      return e.message;
    } catch (e) {
      core.reportError(e.toString());
      notifyListeners();
      return e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // DART-067: Finish walkthrough Create / Capture / fill (no web optimizer)
  // ---------------------------------------------------------------------------

  bool get finishBusy => _finishBusy;
  FinishCategory? get finishActiveCategory => _finishActiveCategory;
  String? get finishMessage => _finishMessage;
  Set<String> get finishSkipped => Set.unmodifiable(_finishSkipped);

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

  void openFinishCategory(FinishCategory cat) {
    _finishActiveCategory = cat;
    _finishMessage = null;
    notifyListeners();
  }

  void skipFinishCategory(FinishCategory cat) {
    _finishSkipped.add(cat.wireName);
    _finishMessage = '${finishCategoryLabel(cat)} skipped for now';
    _finishActiveCategory = null;
    notifyListeners();
  }

  Future<String?> oneTapCreateCategory(FinishCategory category) async {
    final sel = selected;
    final variant = selectedVariant;
    final uid = userId;
    if (sel == null || variant == null || uid == null) {
      return 'No variant selected';
    }
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
    _finishMessage = null;
    notifyListeners();
    try {
      final type = finishCategoryToSetType(category);
      // BR-ATT-006: under-min scaffolds are not attachable — create name-only
      // scaffold; user fills ≥2 domain items / pieces then attaches.
      final result = await createSetAndAttach(
        db,
        uid,
        CreateSetAndAttachCommand(
          buildId: sel.build.id,
          variantId: variant.id,
          type: type,
          attachNow: false,
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
      await core.reloadSelectedCompose();
      _finishActiveCategory = category;
      _finishMessage =
          'Created ${result.set.set.name}. Add enough pieces to meet package '
          'minimum, then attach.';
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      _finishMessage = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> captureCategory(FinishCategory category) async {
    final sel = selected;
    final variant = selectedVariant;
    final uid = userId;
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
      for (final pin in slotPins) {
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
      await core.reloadSelectedCompose();
      final names = result.createdSets.map((s) => s.name).join(', ');
      _finishMessage = names.isEmpty ? 'Capture finished' : 'Captured $names';
      _finishActiveCategory = category;
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      _finishMessage = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Fill first empty required slot via hash/name (web; no catalog modal).
  Future<String?> fillFinishSlot({
    required String setId,
    required String slot,
    required int itemHash,
    required String itemName,
    String? instanceId,
  }) async {
    final uid = userId;
    if (uid == null) return 'No user';
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
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
          replaceExisting: true,
        ),
      );
      if (updated == null) {
        _finishBusy = false;
        notifyListeners();
        return 'Set not found';
      }
      await core.reloadSelectedCompose();
      _finishMessage = 'Filled $slot';
      _finishBusy = false;
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _finishBusy = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      notifyListeners();
      return e.toString();
    }
  }

  @override
  void dispose() {
    core.removeListener(notifyListeners);
    super.dispose();
  }
}
