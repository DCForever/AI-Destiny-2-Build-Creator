import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_derived_title.dart';
import 'builds_mock_gear_tables.dart';
import 'builds_mock_models.dart';
import 'builds_mock_presentation.dart';

/// Density for the hybrid B+E loadout card.
enum BuildsMockCardDensity { tile, list, detail }

/// Hybrid loadout card: compact browse tile / dense list / fuller detail.
class BuildsMockLoadoutCard extends StatelessWidget {
  const BuildsMockLoadoutCard({
    super.key,
    required this.loadout,
    required this.derivedName,
    this.selected = false,
    this.onSelect,
    this.density = BuildsMockCardDensity.tile,
    this.priorities = const [],
    this.fillInPlan,
    this.superIconPath,
    this.exoticArmorIconPath,
    this.exoticWeaponIconPath,
    this.showMods = false,
    this.modsBySlot = const {},
    this.unplacedMods = const [],
    this.subclassAbilities = const [],
    this.subclassAspects = const [],
    this.subclassFragments = const [],
    this.artifactPerks = const [],
    this.notes,
    this.showDetailExtras = false,
  });

  final MockBuild loadout;
  final BuildsMockDerivedName derivedName;
  final bool selected;
  final VoidCallback? onSelect;
  final BuildsMockCardDensity density;
  final List<BuildsMockStatPriority> priorities;
  final FillInSavedBuildPlan? fillInPlan;
  final String? superIconPath;
  final String? exoticArmorIconPath;
  final String? exoticWeaponIconPath;
  final bool showMods;
  final Map<String, List<String>> modsBySlot;
  final List<String> unplacedMods;
  final List<String> subclassAbilities;
  final List<String> subclassAspects;
  final List<String> subclassFragments;
  final List<String> artifactPerks;
  final String? notes;
  final bool showDetailExtras;

  @override
  Widget build(BuildContext context) {
    switch (density) {
      case BuildsMockCardDensity.list:
        return _BrowseCard(
          loadout: loadout,
          derivedName: derivedName,
          selected: selected,
          onSelect: onSelect,
          fillInPlan: fillInPlan,
          superIconPath: superIconPath,
          exoticArmorIconPath: exoticArmorIconPath,
          exoticWeaponIconPath: exoticWeaponIconPath,
          compact: true,
        );
      case BuildsMockCardDensity.tile:
        return _BrowseCard(
          loadout: loadout,
          derivedName: derivedName,
          selected: selected,
          onSelect: onSelect,
          fillInPlan: fillInPlan,
          superIconPath: superIconPath,
          exoticArmorIconPath: exoticArmorIconPath,
          exoticWeaponIconPath: exoticWeaponIconPath,
          compact: false,
        );
      case BuildsMockCardDensity.detail:
        return _DetailBody(
          loadout: loadout,
          derivedName: derivedName,
          selected: selected,
          onSelect: onSelect,
          fillInPlan: fillInPlan,
          superIconPath: superIconPath,
          exoticArmorIconPath: exoticArmorIconPath,
          exoticWeaponIconPath: exoticWeaponIconPath,
          showMods: showMods,
          modsBySlot: modsBySlot,
          unplacedMods: unplacedMods,
          subclassAbilities: subclassAbilities,
          subclassAspects: subclassAspects,
          subclassFragments: subclassFragments,
          artifactPerks: artifactPerks,
          notes: notes,
          showDetailExtras: showDetailExtras,
          priorities: priorities,
        );
    }
  }
}

class _BrowseCard extends StatelessWidget {
  const _BrowseCard({
    required this.loadout,
    required this.derivedName,
    required this.selected,
    required this.onSelect,
    required this.fillInPlan,
    required this.superIconPath,
    required this.exoticArmorIconPath,
    required this.exoticWeaponIconPath,
    required this.compact,
  });

  final MockBuild loadout;
  final BuildsMockDerivedName derivedName;
  final bool selected;
  final VoidCallback? onSelect;
  final FillInSavedBuildPlan? fillInPlan;
  final String? superIconPath;
  final String? exoticArmorIconPath;
  final String? exoticWeaponIconPath;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected ? palette.accent : palette.line;
    final filled = buildsMockHasFillIn(fillInPlan) ||
        loadout.slots.any((s) => s.filledIn);
    final loop = loadout.loop.trim();
    final bonuses = displaySetBonusesFor(loadout);
    final artifactName = loadout.artifact.name.trim();
    final showArtifact =
        artifactName.isNotEmpty && artifactName != '—' && artifactName.toLowerCase() != 'none';

    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: palette.surfaceRaised,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: kFlapRuleThickness),
          ),
          padding: EdgeInsets.all(compact ? 10 : kPanelPadSm),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BuildsMockDerivedTitle(
                  name: derivedName,
                  iconSize: compact ? 16 : 18,
                  fontSize: compact ? 12 : 13,
                  superIconPath: superIconPath,
                  exoticArmorIconPath: exoticArmorIconPath,
                  exoticWeaponIconPath: exoticWeaponIconPath,
                ),
                const SizedBox(height: 2),
                Text(
                  derivedName.sourceName,
                  key: Key('builds_mock_source_name_${loadout.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonMono(color: palette.muted, fontSize: 11),
                ),
                if (!filled) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Tag(
                      key: Key('builds_mock_not_filled_${loadout.id}'),
                      label: 'Not filled in yet',
                      tone: _TagTone.warn,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ExoticTile(
                        label: 'EXOTIC ARMOR',
                        name: loadout.exoticArmor,
                        iconPath: exoticArmorIconPath,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ExoticTile(
                        label: 'EXOTIC WEAPON',
                        name: loadout.exoticWeapon,
                        iconPath: exoticWeaponIconPath,
                      ),
                    ),
                  ],
                ),
                if (loop.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    loop,
                    key: Key('builds_mock_loop_${loadout.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: neonMono(color: palette.foreground, fontSize: 11),
                  ),
                ],
                if (bonuses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  BuildsMockSetBonusBoxes(bonuses: bonuses),
                ],
                if (showArtifact) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: palette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          artifactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'ARMOR',
                  style: neonDisplay(
                    color: palette.muted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                BuildsMockArmorTable(
                  rows: buildsMockArmorRows(build: loadout, plan: fillInPlan),
                ),
                const SizedBox(height: 6),
                Text(
                  'WEAPONS',
                  style: neonDisplay(
                    color: palette.muted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                BuildsMockWeaponTable(
                  rows: buildsMockWeaponRows(build: loadout, plan: fillInPlan),
                ),
                const SizedBox(height: 6),
                Text(
                  'STATS',
                  style: neonDisplay(
                    color: palette.muted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                BuildsMockStatsRow(stats: loadout.stats),
                if (loadout.solipsismNotPrismatic) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Solipsism only works with Prismatic',
                    key: Key('builds_mock_solipsism_flag_${loadout.id}'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.loadout,
    required this.derivedName,
    required this.selected,
    required this.onSelect,
    required this.fillInPlan,
    required this.superIconPath,
    required this.exoticArmorIconPath,
    required this.exoticWeaponIconPath,
    required this.showMods,
    required this.modsBySlot,
    required this.unplacedMods,
    required this.subclassAbilities,
    required this.subclassAspects,
    required this.subclassFragments,
    required this.artifactPerks,
    required this.notes,
    required this.showDetailExtras,
    required this.priorities,
  });

  final MockBuild loadout;
  final BuildsMockDerivedName derivedName;
  final bool selected;
  final VoidCallback? onSelect;
  final FillInSavedBuildPlan? fillInPlan;
  final String? superIconPath;
  final String? exoticArmorIconPath;
  final String? exoticWeaponIconPath;
  final bool showMods;
  final Map<String, List<String>> modsBySlot;
  final List<String> unplacedMods;
  final List<String> subclassAbilities;
  final List<String> subclassAspects;
  final List<String> subclassFragments;
  final List<String> artifactPerks;
  final String? notes;
  final bool showDetailExtras;
  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final filled = buildsMockHasFillIn(fillInPlan) ||
        loadout.slots.any((s) => s.filledIn);
    final loop = loadout.loop.trim();
    final bonuses = displaySetBonusesFor(loadout);
    final artifactName = loadout.artifact.name.trim();
    final showArtifact =
        artifactName.isNotEmpty && artifactName != '—' && artifactName.toLowerCase() != 'none';
    final element = derivedName.elementLabel ?? loadout.subclass;
    final classLabel = derivedName.classLabel;

    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: palette.surfaceRaised,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? palette.accent : palette.line,
              width: kFlapRuleThickness,
            ),
          ),
          padding: const EdgeInsets.all(kPanelPadSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BuildsMockDerivedTitle(
                name: derivedName,
                iconSize: 22,
                fontSize: 16,
                superIconPath: superIconPath,
                exoticArmorIconPath: exoticArmorIconPath,
                exoticWeaponIconPath: exoticWeaponIconPath,
              ),
              const SizedBox(height: 3),
              Text(
                derivedName.sourceName,
                style: neonMono(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Tag(
                    key: Key(
                      filled
                          ? 'builds_mock_filled_tag_${loadout.id}'
                          : 'builds_mock_not_filled_${loadout.id}',
                    ),
                    label: filled ? 'Filled in' : 'Not filled in yet',
                    tone: filled ? _TagTone.ok : _TagTone.warn,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filled
                          ? ''
                          : 'Showing the DIM link as this build.',
                      style: neonMono(color: palette.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (loadout.slots.any(
                (s) => s.filledIn && s.pieceName.trim().isNotEmpty,
              )) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in loadout.slots)
                      if (s.filledIn && s.pieceName.trim().isNotEmpty)
                        Chip(
                          key: Key(
                            'builds_mock_filled_in_${loadout.id}_${s.slot}',
                          ),
                          label: Text('Filled in · ${s.pieceName.trim()}'),
                          visualDensity: VisualDensity.compact,
                        ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ExoticTile(
                      label: 'EXOTIC ARMOR',
                      name: loadout.exoticArmor,
                      iconPath: exoticArmorIconPath,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExoticTile(
                      label: 'EXOTIC WEAPON',
                      name: loadout.exoticWeapon,
                      iconPath: exoticWeaponIconPath,
                    ),
                  ),
                ],
              ),
              if (loop.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(loop, style: neonMono(fontSize: 12)),
              ],
              if (bonuses.isNotEmpty) ...[
                const SizedBox(height: 10),
                BuildsMockSetBonusBoxes(bonuses: bonuses),
              ],
              if (showArtifact) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: palette.accent),
                    const SizedBox(width: 8),
                    Text(artifactName, style: TextStyle(color: palette.accent)),
                  ],
                ),
              ],
              _section(
                'Subclass${classLabel == null ? '' : ' · $element $classLabel'}',
              ),
              if (subclassAbilities.isNotEmpty)
                _plugBlock(palette, 'Abilities', subclassAbilities),
              if (subclassAspects.isNotEmpty) ...[
                const SizedBox(height: 6),
                _plugBlock(palette, 'Aspects', subclassAspects),
              ],
              if (subclassFragments.isNotEmpty) ...[
                const SizedBox(height: 6),
                _plugBlock(palette, 'Fragments', subclassFragments),
              ],
              _section('Armor'),
              BuildsMockArmorTable(
                rows: buildsMockArmorRows(
                  build: loadout,
                  plan: fillInPlan,
                  modsBySlot: showMods ? modsBySlot : const {},
                ),
                showMods: showMods,
              ),
              _section('Weapons'),
              BuildsMockWeaponTable(
                rows: buildsMockWeaponRows(build: loadout, plan: fillInPlan),
              ),
              if (showMods) ...[
                _section('Mods'),
                if (unplacedMods.isNotEmpty)
                  _plugBlock(palette, 'Unplaced mods', unplacedMods),
                if (unplacedMods.isEmpty &&
                    modsBySlot.values.every((m) => m.isEmpty))
                  Text(
                    'No mods',
                    style: neonMono(color: palette.muted, fontSize: 12),
                  ),
              ],
              if (artifactPerks.isNotEmpty) ...[
                _section('Artifact perks'),
                _plugBlock(
                  palette,
                  'Perks · ${artifactPerks.length}',
                  artifactPerks,
                ),
              ],
              _section('Stats'),
              BuildsMockStatsRow(stats: loadout.stats),
              if (priorities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    priorities
                        .map((p) => p.inferred ? '${p.label} (inferred)' : p.label)
                        .join(' · '),
                    style: neonMono(color: palette.muted, fontSize: 10),
                  ),
                ),
              if (notes != null && notes!.trim().isNotEmpty) ...[
                _section('Notes'),
                Text(notes!.trim(), style: neonMono(fontSize: 12)),
              ],
              if (loadout.solipsismNotPrismatic) ...[
                const SizedBox(height: 8),
                Text(
                  'Solipsism only works with Prismatic',
                  key: Key('builds_mock_solipsism_flag_${loadout.id}'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: neonDisplay(fontSize: 9, letterSpacing: 1),
      ),
    );
  }

  Widget _plugBlock(FlapPalette palette, String label, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: neonMono(color: palette.muted, fontSize: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final item in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.line),
                    color: palette.surface,
                  ),
                  child: Text(item, style: neonMono(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExoticTile extends StatelessWidget {
  const _ExoticTile({
    required this.label,
    required this.name,
    this.iconPath,
  });

  final String label;
  final String name;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final display = name.trim();
    final show = display.isNotEmpty &&
        display != '—' &&
        display.toLowerCase() != 'none';
    final path = iconPath?.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: neonDisplay(
              color: palette.muted,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (show && path != null && path.isNotEmpty) ...[
                BungieContentIcon(
                  key: Key('builds_mock_exotic_tile_icon_$label'),
                  pathOrUrl: path,
                  size: 18,
                  semanticLabel: display,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  show ? display : '—',
                  key: Key('builds_mock_exotic_tile_$label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: show ? palette.warning : palette.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TagTone { ok, warn }

class _Tag extends StatelessWidget {
  const _Tag({super.key, required this.label, required this.tone});

  final String label;
  final _TagTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final color = tone == _TagTone.ok ? palette.success : palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
