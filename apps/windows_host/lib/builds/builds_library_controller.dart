import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'build_identity_format.dart';

/// Stable offline library owner when the user is signed out (DART-030/031/032).
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

/// In-process orchestration for Builds library UI (DART-032).
///
/// Calls [destiny2_app] build use cases against the host's single [AppDatabase].
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

  int? get userId => _userId;
  List<BuildRecord> get builds => _builds;
  BuildDetail? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  List<DraftSynergyType> get createDraftTypes =>
      List.unmodifiable(_createDraftTypes);
  List<DraftSynergyType> get editDraftTypes =>
      List.unmodifiable(_editDraftTypes);

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
        final next = await getBuildDetail(db, _userId!, id);
        _selected = next;
        if (next != null) {
          _editDraftTypes = _recordsToDrafts(next.build.synergyTypes);
        } else {
          _editDraftTypes = const [];
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
      notifyListeners();
      return;
    }
    final uid = _userId ?? await resolveLibraryUserId();
    _userId = uid;
    final row = await getBuildDetail(db, uid, buildId);
    _selected = row;
    _editDraftTypes =
        row != null ? _recordsToDrafts(row.build.synergyTypes) : const [];
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

  /// Update selected build identity (name, synergy types, pins).
  Future<String?> updateSelectedIdentity({
    String? name,
    GuardianClass? className,
    List<DraftSynergyType>? synergyTypes,
    bool setExoticArmor = false,
    int? exoticArmorHash,
    String? exoticArmorName,
    bool setExoticWeapon = false,
    int? exoticWeaponHash,
    String? exoticWeaponName,
    bool setPinnedSuper = false,
    String? pinnedSuper,
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
    try {
      final updated = await updateUserBuild(
        db,
        uid,
        sel.build.id,
        UpdateBuildCommand(
          name: name,
          className: className,
          synergyTypes: [for (final d in types) d.toDomain()],
          setExoticArmor: setExoticArmor,
          exoticArmorHash: exoticArmorHash,
          exoticArmorName: exoticArmorName,
          setExoticWeapon: setExoticWeapon,
          exoticWeaponHash: exoticWeaponHash,
          exoticWeaponName: exoticWeaponName,
          setPinnedSuper: setPinnedSuper,
          pinnedSuper: pinnedSuper,
        ),
      );
      if (updated == null) {
        return 'Build not found';
      }
      _selected = updated;
      _editDraftTypes = _recordsToDrafts(updated.build.synergyTypes);
      _builds = await listUserBuilds(db, uid);
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

  List<DraftSynergyType> _recordsToDrafts(
    List<SynergyTypeDesignationRecord> rows,
  ) {
    return [
      for (final r in rows) DraftSynergyType(type: r.type, subType: r.subType),
    ];
  }
}
