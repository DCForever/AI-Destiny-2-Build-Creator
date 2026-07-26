import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'set_slot_mapping.dart';

/// Stable offline library owner when the user is signed out (DART-030 A1).
const String kLocalLibraryMembershipId = 'local-library';

/// Result of a catalog → set-slot pick.
class SetSlotPickResult {
  const SetSlotPickResult({
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.selectedPerks = const [],
  });

  final int itemHash;
  final String itemName;
  final String? instanceId;

  /// Trait / roll perk hashes to persist (BR-ROLL-001 / GAP-UI-SETS-10).
  final List<int> selectedPerks;
}

/// In-process orchestration for Sets library UI (DART-030).
///
/// Calls [destiny2_app] set use cases against the host's single [AppDatabase].
class SetsLibraryController extends ChangeNotifier {
  SetsLibraryController({
    required this.db,
    required this.session,
    required this.inventorySync,
  });

  final AppDatabase db;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

  int? _userId;
  List<SetRecord> _sets = const [];
  SetDetail? _selected;
  String? _error;
  bool _loading = false;
  SetType? _typeFilter;

  int? get userId => _userId;
  List<SetRecord> get sets => _sets;
  SetDetail? get selected => _selected;
  String? get error => _error;
  bool get loading => _loading;
  SetType? get typeFilter => _typeFilter;

  /// Resolve local user (signed-in or [kLocalLibraryMembershipId]) and load list.
  Future<void> refresh({bool keepSelection = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userId = await resolveLibraryUserId();
      _sets = await listUserSets(db, _userId!, type: _typeFilter);
      if (keepSelection && _selected != null) {
        final id = _selected!.set.id;
        _selected = await getSetDetail(db, _userId!, id);
        if (_selected == null) {
          // Deleted or missing — clear selection.
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

  void setTypeFilter(SetType? type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    // Fire and forget; UI awaits via listener.
    refresh(keepSelection: false);
  }

  Future<int> resolveLibraryUserId() async {
    final fromSync = inventorySync.localUserId;
    if (fromSync != null) return fromSync;

    final tokens = session.tokens;
    if (session.isSignedIn && tokens != null && tokens.bungieMembershipId.isNotEmpty) {
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

  Future<void> selectSet(String? setId) async {
    if (setId == null) {
      _selected = null;
      notifyListeners();
      return;
    }
    final uid = _userId ?? await resolveLibraryUserId();
    _userId = uid;
    _selected = await getSetDetail(db, uid, setId);
    notifyListeners();
  }

  /// Create set; selects it on success. Returns error message or null.
  Future<String?> createSet({
    required String name,
    required SetType type,
  }) async {
    try {
      final uid = _userId ?? await resolveLibraryUserId();
      _userId = uid;
      final detail = await createUserSet(
        db,
        uid,
        CreateSetCommand(name: name, type: type),
      );
      _sets = await listUserSets(db, uid, type: _typeFilter);
      _selected = detail;
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

  /// Update selected set name (and optional type). Returns error or null.
  Future<String?> updateSelected({
    String? name,
    SetType? type,
  }) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No set selected';
    }
    try {
      final updated = await updateUserSet(
        db,
        uid,
        sel.set.id,
        UpdateSetCommand(name: name, type: type),
      );
      if (updated == null) {
        return 'Set not found';
      }
      _selected = updated;
      _sets = await listUserSets(db, uid, type: _typeFilter);
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

  /// Fill [slot] from a catalog pick.
  Future<String?> fillSlot(String slot, SetSlotPickResult pick) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No set selected';
    }
    final setType = SetType.tryParse(sel.set.type);
    if (setType == null || !isSlotValidForSetType(setType, slot)) {
      return 'Invalid slot for this set type';
    }
    try {
      final writeSlot = setType == SetType.mod &&
              EquipmentSlot.armorSlots.any((a) => a.wireName == slot)
          ? '$slot:${pick.itemHash}'
          : slot;

      final updated = await upsertUserSetItem(
        db,
        uid,
        sel.set.id,
        UpsertSetItemCommand(
          slot: writeSlot,
          itemHash: pick.itemHash,
          itemName: pick.itemName,
          instanceId: pick.instanceId,
          selectedPerks: pick.selectedPerks,
          replaceExisting: true,
        ),
      );
      if (updated == null) {
        return 'Set not found';
      }
      _selected = updated;
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

  /// Soft-remove the active item occupying [slot] (or exact item id when provided).
  Future<String?> clearSlot(String slot, {String? itemId}) async {
    final sel = _selected;
    final uid = _userId;
    if (sel == null || uid == null) {
      return 'No set selected';
    }
    try {
      final active = sel.activeItems;
      final match = itemId != null
          ? active.where((i) => i.id == itemId).toList()
          : active.where((i) => _slotMatches(i.slot, slot)).toList();
      if (match.isEmpty) {
        return 'Slot is empty';
      }
      SetDetail? updated = sel;
      for (final item in match) {
        updated = await removeUserSetItem(db, uid, sel.set.id, item.id);
      }
      _selected = updated;
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

  bool _slotMatches(String itemSlot, String boardSlot) {
    if (itemSlot == boardSlot) return true;
    // mod keys: helmet:123 → board helmet
    if (itemSlot.startsWith('$boardSlot:')) return true;
    return false;
  }

  /// Active item occupying [slot] (first match), if any.
  SetItemRecord? occupantForSlot(String slot) {
    final sel = _selected;
    if (sel == null) return null;
    for (final i in sel.activeItems) {
      if (_slotMatches(i.slot, slot) || i.slot == slot) return i;
    }
    return null;
  }

  /// Whether filling [slot] requires BR-SLOT-006 replace confirm.
  bool needsReplaceConfirm(String slot) {
    return slotNeedsReplaceConfirm(slotOccupied: occupantForSlot(slot) != null);
  }
}
