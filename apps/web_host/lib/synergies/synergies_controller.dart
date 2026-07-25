/// Synergies library orchestration for Jaspr web (DART-046).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:jaspr/jaspr.dart';

import '../builds/builds_controller.dart' show kLocalLibraryMembershipId;
import '../compose/build_format.dart';

/// In-process Synergy library for the web host.
class SynergiesController extends ChangeNotifier {
  SynergiesController({required this.db});

  final AppDatabase db;

  int? _userId;
  List<SynergyWithLinks> _synergies = const [];
  SynergyWithLinks? _selected;
  String? _error;
  bool _loading = false;
  String? _typeFilter;

  int? get userId => _userId;
  List<SynergyWithLinks> get synergies => List.unmodifiable(_synergies);
  SynergyWithLinks? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  String? get typeFilter => _typeFilter;

  String designationOf(SynergyWithLinks s) =>
      formatSynergyDesignationKey(s.type, s.subType);

  Future<void> refresh({bool keepSelection = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _synergies = await listUserSynergies(db, _userId!, type: _typeFilter);
      if (keepSelection && _selected != null) {
        final id = _selected!.id;
        _selected = await getUserSynergy(db, _userId!, id);
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

  Future<void> selectSynergy(String? synergyId) async {
    if (synergyId == null) {
      _selected = null;
      notifyListeners();
      return;
    }
    final uid = _userId ?? await resolveLibraryUserId();
    _userId = uid;
    _selected = await getUserSynergy(db, uid, synergyId);
    notifyListeners();
  }

  Future<String?> createSynergy({
    required String name,
    required String type,
    String? subType,
    String description = '',
    List<SynergyLinkWrite> links = const [],
    String? id,
  }) async {
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final created = await createUserSynergy(
        db,
        uid,
        CreateSynergyCommand(
          id: id,
          name: name,
          type: type,
          subType: subType,
          description: description,
          links: links,
        ),
      );
      _synergies = await listUserSynergies(db, uid, type: _typeFilter);
      _selected = created;
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
}
