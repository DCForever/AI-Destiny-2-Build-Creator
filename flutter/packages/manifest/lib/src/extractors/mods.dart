import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

const _itemTypeMod = 19;
const _modCatPrefix = 'enhancements.';

/// Armor 3.0 investment stat hashes (EoF naming).
const _armorStatHashToName = <int, String>{
  392767087: 'Health',
  4244567218: 'Melee',
  1735777505: 'Grenade',
  144602215: 'Super',
  1943323491: 'Class',
  2996146975: 'Weapons',
};

final _stackingTooltipRe = RegExp(
  r'multiple copies of this mod|stacked to increase the potency|diminishing returns for each additional copy',
  caseSensitive: false,
);

class ModsExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.mods;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final sandboxPerks = await loadTable('DestinySandboxPerkDefinition');
    final result = <ModRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isModItem(item)) continue;
      final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
      final slotCategory = _toModSlotCategory(cat);
      if (slotCategory == null) continue;
      final base = projectBase(item);
      result.add(
        ModRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          description: _resolveModDescription(item, sandboxPerks),
          slotCategory: slotCategory,
          energyCost: _resolveEnergyCost(item),
          statModifiers: _buildArmorStatModifiers(item),
        ),
      );
    }
    return _dedupeModVariantsByNameAndSlot(result);
  }
}

bool _isModItem(RawInventoryItem item) {
  final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
  return item.itemType == _itemTypeMod && cat.startsWith(_modCatPrefix);
}

ModSlotCategory? _toModSlotCategory(String cat) {
  if (RegExp(r'enhancements\.(v2_)?head').hasMatch(cat)) {
    return ModSlotCategory.helmet;
  }
  if (RegExp(r'enhancements\.(v2_)?arms').hasMatch(cat)) {
    return ModSlotCategory.arms;
  }
  if (RegExp(r'enhancements\.(v2_)?chest').hasMatch(cat)) {
    return ModSlotCategory.chest;
  }
  if (RegExp(r'enhancements\.(v2_)?legs').hasMatch(cat)) {
    return ModSlotCategory.legs;
  }
  if (RegExp(r'enhancements\.(v2_)?class').hasMatch(cat)) {
    return ModSlotCategory.classItem;
  }
  if (cat.contains('tuning')) return ModSlotCategory.tuning;
  if (RegExp(r'enhancements\.(v2_)?general').hasMatch(cat) ||
      RegExp(r'enhancements\.(v2_)?universal').hasMatch(cat) ||
      cat.contains('enhancements.universal')) {
    return ModSlotCategory.general;
  }
  return null;
}

int? _resolveEnergyCost(RawInventoryItem item) {
  final energyCost = item.plug?['energyCost'];
  if (energyCost is Map && energyCost['energyCost'] is num) {
    return (energyCost['energyCost'] as num).toInt();
  }
  return null;
}

Map<String, int> _buildArmorStatModifiers(RawInventoryItem item) {
  final mods = <String, int>{};
  for (final stat in item.investmentStats) {
    if (stat.isConditionallyActive || stat.value == 0) continue;
    final name = _armorStatHashToName[stat.statTypeHash];
    if (name == null) continue;
    mods[name] = (mods[name] ?? 0) + stat.value;
  }
  return mods;
}

String _resolveModDescription(RawInventoryItem item, RawTable sandboxPerks) {
  final display = item.displayProperties.description.trim();
  if (display.isNotEmpty) return display;

  final sandbox = _sandboxPerkDescriptions(item, sandboxPerks);
  if (sandbox.isNotEmpty) return sandbox.join(' ');

  final tips = _tooltipStrings(item);
  if (tips.effect.isNotEmpty) return tips.effect.join(' ');
  if (tips.stacking.isNotEmpty) return tips.stacking.join(' ');
  return '';
}

List<String> _sandboxPerkDescriptions(
  RawInventoryItem item,
  RawTable sandboxPerks,
) {
  final out = <String>[];
  final seen = <String>{};
  for (final entry in item.perks) {
    final hash = entry['perkHash'];
    if (hash is! num) continue;
    final sp = RawSandboxPerk.tryParse(getRaw(sandboxPerks, hash.toInt()));
    final d = sp?.displayProperties.description.trim() ?? '';
    if (d.isEmpty || seen.contains(d)) continue;
    seen.add(d);
    out.add(d);
  }
  return out;
}

({List<String> effect, List<String> stacking}) _tooltipStrings(
  RawInventoryItem item,
) {
  final effect = <String>[];
  final stacking = <String>[];
  for (final tip in item.tooltipNotifications) {
    final t = (tip['displayString'] as String?)?.trim() ?? '';
    if (t.isEmpty) continue;
    if (_stackingTooltipRe.hasMatch(t)) {
      stacking.add(t);
    } else {
      effect.add(t);
    }
  }
  return (effect: effect, stacking: stacking);
}

/// Keep higher energy-cost variant for same name + slot (DIM-style).
List<ModRecord> _dedupeModVariantsByNameAndSlot(List<ModRecord> items) {
  final best = <String, ModRecord>{};
  for (final item in items) {
    final key =
        '${item.name.trim().toLowerCase()}\u0000${item.slotCategory.json}';
    final prev = best[key];
    if (prev == null) {
      best[key] = item;
      continue;
    }
    final c = item.energyCost ?? -0x7fffffff;
    final p = prev.energyCost ?? -0x7fffffff;
    if (c > p) {
      best[key] = item;
    } else if (c == p && item.hash < prev.hash) {
      best[key] = item;
    }
  }
  return best.values.toList();
}
