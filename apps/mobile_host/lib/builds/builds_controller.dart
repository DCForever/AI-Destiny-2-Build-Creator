import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:flutter/foundation.dart';

import 'build_format.dart';

/// Stable offline library owner when the user is signed out (DART-040 mobile).
const String kLocalLibraryMembershipId = 'local-library';

/// In-process orchestration for mobile Builds list + detail load (DART-040).
///
/// Calls [destiny2_app] list/detail use cases against the host's single
/// [AppDatabase]. Soft guidance never auto-applies (not shown in this slice).
class BuildsController extends ChangeNotifier {
  BuildsController({required this.db});

  final AppDatabase db;

  int? _userId;
  List<BuildRecord> _builds = const [];
  BuildDetail? _selected;
  String? _error;
  bool _loading = false;

  int? get userId => _userId;
  List<BuildRecord> get builds => List.unmodifiable(_builds);
  BuildDetail? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;

  String titleOf(BuildRecord b) => formatBuildListTitle(b.name);

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

  /// Resolve local library user and load builds list via shared use cases.
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _builds = await listUserBuilds(db, _userId!);
      if (_selected != null) {
        final id = _selected!.build.id;
        _selected = await getBuildDetail(db, _userId!, id);
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

  /// Load detail for [buildId] via [getBuildDetail] (Focus Swap target).
  Future<BuildDetail?> openBuild(String buildId) async {
    _error = null;
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final detail = await getBuildDetail(db, uid, buildId);
      _selected = detail;
      notifyListeners();
      return detail;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearSelection() {
    _selected = null;
    notifyListeners();
  }
}
