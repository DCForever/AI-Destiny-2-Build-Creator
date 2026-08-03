import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'synergy_designation.dart';

/// Stable offline library owner when the user is signed out (DART-030/031).
const String kLocalLibraryMembershipId = 'local-library';

/// In-process orchestration for Synergy library UI (DART-031 / DART-066).
///
/// Calls [destiny2_app] synergy use cases against the host's single [AppDatabase].
class SynergiesLibraryController extends ChangeNotifier {
  SynergiesLibraryController({
    required this.db,
    required this.session,
    required this.inventorySync,
    this.catalogItems = const [],
  });

  final AppDatabase db;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

  /// Offline catalog rows for evidence picker (GAP-UI-SYN-01).
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

  /// Draft evidence links for the selected synergy (edited in UI before save).
  List<SynergyLinkWrite> _draftLinks = const [];

  int? get userId => _userId;
  List<SynergyWithLinks> get synergies => _synergies;
  List<SynergyWithLinks> get allSynergies => _allSynergies;
  SynergyWithLinks? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  String? get typeFilter => _typeFilter;
  String get searchQuery => _searchQuery;
  List<String> get typeFacets => List.unmodifiable(_typeFacets);
  List<String> get subTypeFacets => List.unmodifiable(_subTypeFacets);
  List<SynergyLinkWrite> get draftLinks => List.unmodifiable(_draftLinks);

  String designationOf(SynergyWithLinks s) =>
      formatSynergyDesignation(s.type, s.subType);

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

  /// Resolve local user (signed-in or [kLocalLibraryMembershipId]) and load list.
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
        if (next != null) {
          _draftLinks = _linksToWrites(next);
        } else {
          _draftLinks = const [];
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

  void setTypeFilter(String? type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _typeFacets = type == null ? const [] : [type];
    _reapplyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _reapplyFilters();
    notifyListeners();
  }

  void setTypeFacets(List<String> types) {
    _typeFacets = List.unmodifiable(types);
    _typeFilter = types.length == 1 ? types.first : null;
    _reapplyFilters();
    notifyListeners();
  }

  void setSubTypeFacets(List<String> subTypes) {
    _subTypeFacets = List.unmodifiable(subTypes);
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
    setTypeFacets(next);
  }

  /// Catalog search for evidence, omitting draft-linked targets (BR-SYN-011).
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

  /// Add picker hit to draft when not already linked (BR-SYN-011).
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

  /// Delete selected synergy; clears selection on success.
  Future<String?> deleteSelected() async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No synergy selected';
    }
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

  /// Create synergy; selects it on success. Returns error message or null.
  Future<String?> createSynergy({
    required String name,
    required String type,
    String? subType,
    String description = '',
    List<SynergyLinkWrite> links = const [],
  }) async {
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final created = await createUserSynergy(
        db,
        uid,
        CreateSynergyCommand(
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

  /// Update selected name/description only (never designation).
  Future<String?> updateSelectedIdentity({
    String? name,
    String? description,
  }) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No synergy selected';
    }
    try {
      final updated = await updateUserSynergy(
        db,
        uid,
        sel.id,
        UpdateSynergyCommand(
          name: name,
          description: description,
        ),
      );
      if (updated == null) {
        return 'Synergy not found';
      }
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

  /// Persist draft evidence links for the selected synergy.
  Future<String?> saveDraftLinks() async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No synergy selected';
    }
    try {
      final updated = await updateUserSynergy(
        db,
        uid,
        sel.id,
        UpdateSynergyCommand(links: List<SynergyLinkWrite>.from(_draftLinks)),
      );
      if (updated == null) {
        return 'Synergy not found';
      }
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

  /// Toggle required flag on a draft link (DBR-SYN-007–010a). Save links to persist.
  void setDraftLinkRequired(int index, bool required) {
    if (index < 0 || index >= _draftLinks.length) return;
    final cur = _draftLinks[index];
    final next = List<SynergyLinkWrite>.from(_draftLinks);
    next[index] = SynergyLinkWrite(
      id: cur.id,
      kind: cur.kind,
      displayName: cur.displayName,
      itemHash: cur.itemHash,
      perkHash: cur.perkHash,
      parentItemHash: cur.parentItemHash,
      originTraitName: cur.originTraitName,
      originTraitHash: cur.originTraitHash,
      armorSetName: cur.armorSetName,
      bonusPieces: cur.bonusPieces,
      bonusName: cur.bonusName,
      armorSetHash: cur.armorSetHash,
      required: required,
    );
    _draftLinks = next;
    notifyListeners();
  }

  /// Probes designation immutability (for tests / defensive UI). Returns error text.
  Future<String?> attemptChangeType(String newType) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No synergy selected';
    }
    try {
      await updateUserSynergy(
        db,
        uid,
        sel.id,
        UpdateSynergyCommand(hasType: true, type: newType),
      );
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
          required: l.required,
        ),
    ];
  }
}


