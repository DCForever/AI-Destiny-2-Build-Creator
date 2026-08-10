import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/foundation.dart';

/// Modal lifecycle state for Sets Armor create / board / compare / optimize.
///
/// Presentation-only orchestration; host maps picks to [SetsLibraryController].
class SetsLifecycleController extends ChangeNotifier {
  SetsLifecyclePhase phase = SetsLifecyclePhase.closed;

  // Create wizard draft
  SetType createType = SetType.armor;
  GuardianClass? createClass;
  List<SetBonusCoverageGoal> createGoals = const [];
  String createName = '';
  List<String> createTags = const [];

  // Board / fill
  String? activeSetId;
  String? fillSlot;
  List<OwnedArmorCompareRow> compareRows = const [];
  List<SetsOptimizeKitRowData> optimizeKits = const [];
  String? selectedKitId;
  bool optimizeHasPins = false;

  bool get typeClassLocked {
    if (createType != SetType.armor) return true;
    return createClass != null;
  }

  String get namePreview {
    if (createType != SetType.armor || createClass == null) {
      return createName.trim();
    }
    return resolveArmorSetName(
      guardianClass: createClass!,
      goals: createGoals,
      tags: createTags,
      preferredName: createName,
    );
  }

  void openCreate() {
    phase = SetsLifecyclePhase.create;
    createType = SetType.armor;
    createClass = null;
    createGoals = const [];
    createName = '';
    createTags = const [];
    notifyListeners();
  }

  void openBoard(String setId) {
    phase = SetsLifecyclePhase.board;
    activeSetId = setId;
    fillSlot = null;
    notifyListeners();
  }

  void openOwnedCompare({
    required String setId,
    required String slot,
    required List<OwnedArmorCompareRow> rows,
  }) {
    phase = SetsLifecyclePhase.ownedCompare;
    activeSetId = setId;
    fillSlot = slot;
    compareRows = filterOwnedWithInstanceIdentity(rows);
    notifyListeners();
  }

  void openOptimize({
    required String setId,
    required List<SetsOptimizeKitRowData> kits,
    required bool hasPins,
    String? selectedId,
  }) {
    phase = SetsLifecyclePhase.optimize;
    activeSetId = setId;
    optimizeKits = kits;
    optimizeHasPins = hasPins;
    selectedKitId = selectedId ?? (kits.isNotEmpty ? kits.first.id : null);
    notifyListeners();
  }

  void close() {
    phase = SetsLifecyclePhase.closed;
    fillSlot = null;
    notifyListeners();
  }

  void setCreateType(SetType type) {
    createType = type;
    if (type != SetType.armor) {
      createClass = null;
      createGoals = const [];
    }
    notifyListeners();
  }

  void setCreateClass(GuardianClass? c) {
    createClass = c;
    notifyListeners();
  }

  void setCreateGoals(List<SetBonusCoverageGoal> goals) {
    if (!isLegalSetBonusGoalCombo(goals)) return;
    createGoals = List.unmodifiable(goals);
    notifyListeners();
  }

  void setCreateName(String name) {
    createName = name;
    notifyListeners();
  }

  void selectKit(String id) {
    selectedKitId = id;
    notifyListeners();
  }

  /// Build CreateSetCommand from draft (blank name → auto-name).
  CreateSetCommand buildCreateCommand({
    Iterable<String> existingNames = const [],
  }) {
    final name = createType == SetType.armor && createClass != null
        ? resolveArmorSetName(
            guardianClass: createClass!,
            goals: createGoals,
            tags: createTags,
            preferredName: createName,
            existingNames: existingNames,
          )
        : (createName.trim().isEmpty ? 'New ${createType.wireName} set' : createName.trim());
    return CreateSetCommand(
      name: name,
      type: createType,
      tagIds: createTags,
      guardianClass: createType == SetType.armor ? createClass : null,
      setBonusGoals: createType == SetType.armor ? createGoals : const [],
    );
  }
}

enum SetsLifecyclePhase {
  closed,
  create,
  board,
  ownedCompare,
  optimize,
}
