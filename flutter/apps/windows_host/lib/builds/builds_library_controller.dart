import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'build_identity_format.dart';

export 'package:destiny2_app/destiny2_app.dart'
    show AttachmentView, DraftSynergyType, SlotPinView, kLocalLibraryMembershipId;

/// Windows Builds library — [BuildsComposeSession] for list/compose;
/// identity confirm + finish walkthrough remain host extras.
class BuildsLibraryController extends ChangeNotifier {
  BuildsLibraryController({
    required this.db,
    required this.session,
    required this.inventorySync,
  }) {
    core = BuildsComposeSession(
      db: db,
      userIdResolver: _resolveLibraryUserIdImpl,
    );
    core.addListener(notifyListeners);
  }

  final AppDatabase db;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;
  late final BuildsComposeSession core;

  // --- Identity / hard-block host state ---
  List<DraftSynergyType> _editDraftTypes = const [];
  SubclassKit _editSubclass = const SubclassKit();
  List<String>? _pendingIdentityFields;
  Map<String, Object?>? _pendingIdentityPayload;
  List<ComposeHardBlock> _composeHardBlocks = const [];
  String? _lastForkedFromId;
  List<CatalogItem>? catalogItems;

  // --- Finish walkthrough host state ---
  bool _finishBusy = false;
  FinishWalkthroughStep _finishStep = FinishWalkthroughStep.overview;
  FinishCategory? _finishActiveCategory;
  String? _finishFillSlot;
  final Set<String> _finishSkipped = {};
  String? _finishMessage;

  // --- Compose delegation ---
  AppDatabase get database => db;
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
    final cap = _resolveFragmentCapacityLocal(aspects);
    return formatSubclassCapacityCaption(
      aspectCount: aspects.length,
      fragmentCount: fragments.length,
      fragmentCapacity: cap.capacity,
      capacityResolved: cap.resolved,
    );
  }

  String synergySummaryOf(BuildRecord b) => formatSynergyDesignationList([
        for (final d in b.synergyTypes) (type: d.type, subType: d.subType),
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

  Future<int> _resolveLibraryUserIdImpl() async {
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

  Future<int> resolveLibraryUserId() => core.resolveLibraryUserId();

  Future<void> refresh({bool keepSelection = true}) async {
    if (!keepSelection) {
      core.clearSelection();
      _editDraftTypes = const [];
      _editSubclass = const SubclassKit();
    }
    final priorVariant = selectedVariant?.id;
    await core.refresh();
    final row = selected;
    if (row != null) {
      _editDraftTypes = _recordsToDrafts(row.build.synergyTypes);
      _editSubclass = subclassKitFromJson(row.build.subclass);
      _refreshComposeHardBlocks();
      if (priorVariant != null) {
        await core.selectVariant(priorVariant);
      }
    }
    _syncCoverageIndexesFromCatalog();
  }

  Future<void> selectBuild(String? buildId) async {
    if (buildId == null) {
      core.clearSelection();
      _editDraftTypes = const [];
      _editSubclass = const SubclassKit();
      _pendingIdentityFields = null;
      _pendingIdentityPayload = null;
      notifyListeners();
      return;
    }
    await core.openBuild(buildId);
    final row = selected;
    _editDraftTypes =
        row != null ? _recordsToDrafts(row.build.synergyTypes) : const [];
    _editSubclass = row != null
        ? subclassKitFromJson(row.build.subclass)
        : const SubclassKit();
    _pendingIdentityFields = null;
    _pendingIdentityPayload = null;
    if (row != null) {
      _refreshComposeHardBlocks();
      _syncCoverageIndexesFromCatalog();
    }
  }

  void addCreateDraftType(String type, [String? subType]) =>
      core.addCreateDraftType(type, subType);
  void removeCreateDraftTypeAt(int index) =>
      core.removeCreateDraftTypeAt(index);
  void clearCreateDraftTypes() => core.clearCreateDraftTypes();

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
      _editDraftTypes = _recordsToDrafts(created.build.synergyTypes);
      _editSubclass = subclassKitFromJson(created.build.subclass);
      _refreshComposeHardBlocks();
    }
    return err;
  }

  Future<void> selectVariant(String? variantId) => core.selectVariant(variantId);
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
  Future<void> refreshSoftCoverage() {
    _syncCoverageIndexesFromCatalog();
    return core.refreshSoftCoverage();
  }

  Future<String?> saveSoftStatTargets(SoftStatTargets targets) =>
      core.saveSoftStatTargets(targets);
  Future<String?> saveSoftStatTargetsFromFields(Map<String, String> fields) =>
      core.saveSoftStatTargetsFromFields(fields);

  void _syncCoverageIndexesFromCatalog() {
    final items = catalogItems;
    if (items == null) return;
    core.coverageWeaponElementByHash = {
      for (final item in items)
        if ((item.element ?? '').isNotEmpty) item.hash: item.element!,
    };
  }

  List<DraftSynergyType> _recordsToDrafts(
    List<SynergyTypeDesignationRecord> rows,
  ) {
    return [
      for (final r in rows) DraftSynergyType(type: r.type, subType: r.subType),
    ];
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
    final sel = selected;
    final uid = userId;
    if (sel == null || uid == null) {
      return 'No build selected';
    }
    final types = synergyTypes ?? _editDraftTypes;
    if (types.isEmpty) {
      const msg = 'At least one synergy type is required';
      core.reportError(msg);
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
        core.reportError(msg);
        notifyListeners();
        return msg;
      }
    }

    try {
      final priorVariantId = selectedVariant?.id;
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
      await core.reloadBuildList();
      await core.openBuild(updated.build.id);
      if (priorVariantId != null) {
        await core.selectVariant(priorVariantId);
      }
      _editDraftTypes = _recordsToDrafts(updated.build.synergyTypes);
      _editSubclass = subclassKitFromJson(updated.build.subclass);
      core.reportError(null);
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
    final sel = selected;
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

  /// One-tap Create empty set + live attach (no name/tag chrome).
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
    core.reportError(null);
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
      await core.reloadSelectedCompose();
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
      core.reportError(e.message);
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      core.reportError(e.toString());
      _finishMessage = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  /// Capture resolved gear claims for [category] into a set + live attach.
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
      core.reportError(e.message);
      _finishMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      core.reportError(e.toString());
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
    bool isExotic = false,
    String? equipmentSlot,
    String? catalogKind,
  }) async {
    final uid = userId;
    if (uid == null) return 'No user';
    if (_finishBusy) return 'Busy';
    _finishBusy = true;
    _finishMessage = null;
    notifyListeners();
    try {
      final detail = await getSetDetail(db, uid, setId);
      final setType = SetType.tryParse(detail?.set.type ?? '');
      final kind = catalogKind ??
          (setType == SetType.armor || setType == SetType.mod
              ? 'armor'
              : 'weapons');
      final candidateMeta = setItemMetaFromCatalog(
        isExotic: isExotic,
        slot: equipmentSlot,
        kind: kind,
        name: itemName,
      );
      final known = <int, SetItemMeta>{
        for (final row in detail?.activeItems ?? const [])
          row.itemHash: SetItemMeta(
            kind: SetItemKind.unknown,
            name: row.itemName,
          ),
        itemHash: candidateMeta,
      };
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
          itemMeta: candidateMeta,
          knownItemMeta: known,
        ),
      );
      if (updated == null) {
        _finishBusy = false;
        return 'Set not found';
      }
      await core.reloadSelectedCompose();
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
      core.reportError(e.message);
      notifyListeners();
      return e.message;
    } catch (e) {
      _finishBusy = false;
      core.reportError(e.toString());
      notifyListeners();
      return e.toString();
    }
  }

  /// After armor kit apply from Finish optimizer — re-evaluate gaps.
  Future<void> afterFinishArmorApplied() async {
    await core.reloadSelectedCompose();
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
  @override
  void dispose() {
    core.removeListener(notifyListeners);
    super.dispose();
  }
}