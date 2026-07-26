/// Synergies library orchestration for Jaspr web (DART-046 / DART-066).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/jaspr.dart';

import '../builds/builds_controller.dart' show kLocalLibraryMembershipId;
import '../compose/build_format.dart';

/// In-process Synergy library for the web host (list + detail manage).
class SynergiesController extends ChangeNotifier {
  SynergiesController({
    required this.db,
    this.catalogItems = const [],
  });

  final AppDatabase db;
  List<CatalogItem> catalogItems;

  int? _userId;
  List<SynergyWithLinks> _allSynergies = const [];
  List<SynergyWithLinks> _synergies = const [];
  SynergyWithLinks? _selected;
  String? _error;
  bool _loading = false;
  String? _typeFilter;
  String _searchQuery = '';
  List<String> _typeFacets = const [];
  List<String> _subTypeFacets = const [];
  List<SynergyLinkWrite> _draftLinks = const [];

  int? get userId => _userId;
  List<SynergyWithLinks> get synergies => List.unmodifiable(_synergies);
  List<SynergyWithLinks> get allSynergies => List.unmodifiable(_allSynergies);
  SynergyWithLinks? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  String? get typeFilter => _typeFilter;
  String get searchQuery => _searchQuery;
  List<String> get typeFacets => List.unmodifiable(_typeFacets);
  List<String> get subTypeFacets => List.unmodifiable(_subTypeFacets);
  List<SynergyLinkWrite> get draftLinks => List.unmodifiable(_draftLinks);

  String designationOf(SynergyWithLinks s) =>
      formatSynergyDesignationDisplay(s.type, s.subType);

  void _reapplyFilters() {
    final rows = [
      for (final s in _allSynergies)
        FilterableSynergy(
          id: s.id,
          name: s.name,
          type: s.type,
          subType: s.subType,
        ),
    ];
    final filtered = filterSynergies(
      rows,
      SynergyListFilters(
        query: _searchQuery,
        types: _typeFacets.isNotEmpty
            ? _typeFacets
            : (_typeFilter != null ? [_typeFilter!] : const []),
        subTypes: _subTypeFacets,
      ),
    );
    final byId = {for (final s in _allSynergies) s.id: s};
    _synergies = [
      for (final r in filtered)
        if (byId[r.id] != null) byId[r.id]!,
    ];
  }

  Future<void> refresh({bool keepSelection = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _allSynergies = await listUserSynergies(db, _userId!);
      _reapplyFilters();
      if (keepSelection && _selected != null) {
        final id = _selected!.id;
        final next = await getUserSynergy(db, _userId!, id);
        _selected = next;
        _draftLinks = next != null ? _linksToWrites(next) : const [];
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

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _reapplyFilters();
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _typeFacets = type == null ? const [] : [type];
    _reapplyFilters();
    notifyListeners();
  }

  void toggleTypeFacet(String type) {
    final next = List<String>.from(_typeFacets);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    _typeFacets = List.unmodifiable(next);
    _typeFilter = next.length == 1 ? next.first : null;
    _reapplyFilters();
    notifyListeners();
  }

  Future<void> selectSynergy(String? synergyId) async {
    if (synergyId == null) {
      _selected = null;
      _draftLinks = const [];
      notifyListeners();
      return;
    }
    final uid = _userId ?? await resolveLibraryUserId();
    _userId = uid;
    final row = await getUserSynergy(db, uid, synergyId);
    _selected = row;
    _draftLinks = row != null ? _linksToWrites(row) : const [];
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
      _allSynergies = await listUserSynergies(db, uid);
      _reapplyFilters();
      _selected = created;
      _draftLinks = _linksToWrites(created);
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

  Future<String?> updateSelectedIdentity({
    String? name,
    String? description,
  }) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) return 'No synergy selected';
    try {
      final updated = await updateUserSynergy(
        db,
        uid,
        sel.id,
        UpdateSynergyCommand(name: name, description: description),
      );
      if (updated == null) return 'Synergy not found';
      _selected = updated;
      _draftLinks = _linksToWrites(updated);
      _allSynergies = await listUserSynergies(db, uid);
      _reapplyFilters();
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

  void addDraftLink(SynergyLinkWrite link) {
    _draftLinks = [..._draftLinks, link];
    notifyListeners();
  }

  void removeDraftLinkAt(int index) {
    if (index < 0 || index >= _draftLinks.length) return;
    final next = List<SynergyLinkWrite>.from(_draftLinks)..removeAt(index);
    _draftLinks = next;
    notifyListeners();
  }

  Future<String?> saveDraftLinks() async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) return 'No synergy selected';
    try {
      final updated = await updateUserSynergy(
        db,
        uid,
        sel.id,
        UpdateSynergyCommand(links: List<SynergyLinkWrite>.from(_draftLinks)),
      );
      if (updated == null) return 'Synergy not found';
      _selected = updated;
      _draftLinks = _linksToWrites(updated);
      _allSynergies = await listUserSynergies(db, uid);
      _reapplyFilters();
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

  List<SynergyPickerHit> searchEvidence({
    required String linkKind,
    String query = '',
  }) {
    final hits = searchCatalogForSynergyLinks(
      catalog: catalogItems,
      linkKind: linkKind,
      query: query,
    );
    return filterOutLinkedPickerItems(hits, _draftLinks);
  }

  String? addPickerHitToDraft(SynergyPickerHit hit) {
    final write = pickerHitToLinkWrite(hit);
    if (isLinkAlreadyDrafted(write, _draftLinks)) {
      return 'Evidence already linked (BR-SYN-011)';
    }
    if (write.displayName.trim().isEmpty) {
      return 'Link display name must not be empty';
    }
    addDraftLink(write);
    return null;
  }

  Future<String?> deleteSelected() async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) return 'No synergy selected';
    try {
      final ok = await deleteUserSynergy(db, uid, sel.id);
      if (!ok) return 'Synergy not found';
      _selected = null;
      _draftLinks = const [];
      _allSynergies = await listUserSynergies(db, uid);
      _reapplyFilters();
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

  List<SynergyLinkWrite> _linksToWrites(SynergyWithLinks s) {
    return [
      for (final l in s.links)
        SynergyLinkWrite(
          id: l.id,
          kind: l.kind,
          displayName: l.displayName,
          itemHash: l.itemHash,
          perkHash: l.perkHash,
          parentItemHash: l.parentItemHash,
          originTraitName: l.originTraitName,
          originTraitHash: l.originTraitHash,
          armorSetName: l.armorSetName,
          bonusPieces: l.bonusPieces,
          bonusName: l.bonusName,
          armorSetHash: l.armorSetHash,
        ),
    ];
  }
}
