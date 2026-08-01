import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../catalog/owned_catalog_bridge.dart';
import 'armor_base_roll_provider.dart';

/// Build dense row presentations + armor totals for a set detail (DART-065).
class SetDetailPresentation {
  const SetDetailPresentation({
    required this.rowsBySlot,
    this.armorTotals,
  });

  /// Board slot wire name → row (first active occupant).
  final Map<String, SetItemRowPresentation> rowsBySlot;
  final ArmorSetStatTotals? armorTotals;
}

/// Enrich active set items with catalog meta, traits, synergies, armor board.
///
/// Armor boards prefer base-roll from `armor_stats` plugs when [resolvePlug]
/// is provided (BR-SET-011 / DBR-STAT-008); else inventory ItemStats board.
Future<SetDetailPresentation> enrichSetDetailPresentation({
  required SetDetail detail,
  required OwnedCatalogBridge bridge,
  required List<String> boardSlots,
  int? userId,
  Map<int, String> plugNameByHash = const {},
  ArmorPlugStatResolver? resolvePlug,
  BungieManifestService? manifestService,
}) async {
  final plugResolver = resolvePlug ??
      (await createWindowsArmorBaseRollEnrichment(
        manifestService: manifestService,
      ))
          .resolvePlug;
  await bridge.refresh(reloadEntities: false);

  // Prefer library owner inventory when signed-out bridge has no membership.
  List<InventoryItemRecord> inventoryFallback = const [];
  if (userId != null) {
    inventoryFallback = await listInventoryItems(bridge.db, userId);
  }

  final catalogByHash = <int, CatalogItem>{
    for (final i in bridge.browse(const CatalogClientFilters())) i.hash: i,
  };
  // Include offline catalog base even when owned-filter annotate is empty.
  for (final i in bridge.offlineCatalog.baseItems) {
    catalogByHash.putIfAbsent(i.hash, () => i);
  }

  // Next-style: resolve perk names for plugs on items in this set.
  final invForNames = inventoryFallback.isNotEmpty
      ? inventoryFallback
      : bridge.inventory;
  final setHashes = detail.activeItems.map((i) => i.itemHash).toSet();
  final relevantInv = invForNames.where((r) => setHashes.contains(r.itemHash));
  await bridge.ensurePlugNames(collectPlugHashesFromInventory(relevantInv));
  for (final item in detail.activeItems) {
    await bridge.ensurePlugNames(item.selectedPerks);
  }

  final rowsBySlot = <String, SetItemRowPresentation>{};
  final armorPieces = <ArmorStatPieceInput>[];
  final names = {
    ...bridge.plugNameByHash,
    if (plugNameByHash.isNotEmpty) ...plugNameByHash,
  };

  for (final slot in boardSlots) {
    final items = detail.activeItems
        .where((i) => i.slot == slot || i.slot.startsWith('$slot:'))
        .toList();
    if (items.isEmpty) continue;
    final item = items.first;
    final catalog = catalogByHash[item.itemHash];
    final treatArmor = isArmorBoardSlot(item.slot) ||
        (catalog?.sourceStore?.contains('armor') ?? false);

    CatalogInstanceProjection? instance;
    if (item.instanceId != null && item.instanceId!.isNotEmpty) {
      final instances = bridge.instancesFor(
        item.itemHash,
        treatAsArmor: treatArmor,
      );
      for (final inst in instances) {
        if (inst.instanceId == item.instanceId) {
          instance = inst;
          break;
        }
      }
      if (instance == null && inventoryFallback.isNotEmpty) {
        final projected = projectInstancesForHash(
          inventoryFallback,
          item.itemHash,
          plugNameByHash: names,
          treatAsArmor: treatArmor,
        );
        for (final inst in projected) {
          if (inst.instanceId == item.instanceId) {
            instance = inst;
            break;
          }
        }
      }
    }

    final plugCards = instance?.plugCards ?? const <ResolvedPlugCard>[];
    final traits = traitPerksForDisplay(
      selectedPerks: item.selectedPerks.isNotEmpty
          ? item.selectedPerks
          : (instance?.plugHashes ?? const []),
      plugCards: plugCards,
      plugNameByHash: names,
    );

    final linked = <SetItemLinkedSynergy>[];
    if (catalog != null) {
      for (final b in bridge.badgesFor(catalog)) {
        linked.add(SetItemLinkedSynergy(id: b.id, label: b.name));
      }
    }

    ArmorBaseStatBoard? armorBoard;
    if (treatArmor) {
      Map<String, int>? plugBase;
      if (plugResolver != null) {
        // Inventory plugHashes carry equipped armor_stats roll plugs (BR-SET-011).
        final effectivePlugs = instance?.plugHashes ?? const <int>[];
        if (effectivePlugs.isNotEmpty) {
          plugBase = computeArmorBaseStatsFromPlugs(
            effectivePlugs,
            plugResolver,
          );
        }
      }
      armorBoard = preferArmorBaseRollBoard(
        plugBaseStats: plugBase,
        liveStatValues: instance?.statValues,
      );
    }
    final statsUnknown = treatArmor &&
        armorBoard == null &&
        (item.instanceId == null || item.instanceId!.isEmpty
            ? true
            : instance?.statValues == null);

    if (treatArmor) {
      armorPieces.add(
        ArmorStatPieceInput.fromBoard(
          armorBoard,
          instanceId: item.instanceId,
        ),
      );
    }

    final meta = buildSetItemMetaChips(
      isExotic: catalog?.isExotic,
      element: catalog?.element,
      ammo: catalog?.ammo,
      itemTypeName: catalog?.itemTypeName,
      frame: catalog?.frame,
      classType: catalog?.classType,
      tier: instance?.gearTier,
      tierLabel: instance?.gearTier != null ? 'Tier ${instance!.gearTier}' : null,
      power: instance?.power,
      location: instance?.location,
      hasInstance: item.instanceId != null && item.instanceId!.isNotEmpty,
    );

    rowsBySlot[slot] = SetItemRowPresentation(
      itemId: item.id,
      slot: item.slot,
      itemHash: item.itemHash,
      itemName: item.itemName,
      instanceId: item.instanceId,
      icon: catalog?.icon,
      metaChips: meta,
      traitPerks: traits,
      linkedSynergies: linked,
      armorStats: armorBoard,
      statsUnknown: statsUnknown && treatArmor,
    );
  }

  ArmorSetStatTotals? armorTotals;
  final setType = detail.set.type;
  if (setType == 'armor' || setType == 'Armor') {
    armorTotals = sumArmorSetStats(armorPieces);
  }

  return SetDetailPresentation(
    rowsBySlot: rowsBySlot,
    armorTotals: armorTotals,
  );
}
