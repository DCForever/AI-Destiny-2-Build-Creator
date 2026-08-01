import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

export 'package:destiny2_app/destiny2_app.dart'
    show
        AttachmentView,
        BuildsComposeSession,
        DraftSynergyType,
        SlotPinView,
        kLocalLibraryMembershipId;

/// Mobile Builds list + compose — thin [ChangeNotifier] over [BuildsComposeSession].
class BuildsController extends ChangeNotifier {
  BuildsController({required AppDatabase db})
      : core = BuildsComposeSession(db: db) {
    core.addListener(notifyListeners);
  }

  final BuildsComposeSession core;

  AppDatabase get db => core.db;

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
  FinishGapsResult? get finishGaps => core.finishGaps;

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

  String titleOf(BuildRecord b) => core.titleOf(b);
  String synergySummaryOf(BuildRecord b) => core.synergySummaryOf(b);
  String exoticsSummaryOf(BuildRecord b) => core.exoticsSummaryOf(b);
  String identitySummaryOf(BuildRecord b) => core.identitySummaryOf(b);

  Future<void> refresh() => core.refresh();
  Future<int> resolveLibraryUserId() => core.resolveLibraryUserId();
  Future<BuildDetail?> openBuild(String buildId) => core.openBuild(buildId);
  void clearSelection() => core.clearSelection();

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
  }) =>
      core.createBuild(
        name: name,
        className: className,
        exoticArmorHash: exoticArmorHash,
        exoticArmorName: exoticArmorName,
        exoticWeaponHash: exoticWeaponHash,
        exoticWeaponName: exoticWeaponName,
        pinnedSuper: pinnedSuper,
        synergyTypes: synergyTypes,
      );

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

  @override
  void dispose() {
    core.removeListener(notifyListeners);
    super.dispose();
  }
}
