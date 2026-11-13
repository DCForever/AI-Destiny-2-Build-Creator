import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'builds_mock_models.dart';

/// Density for the hybrid B+E loadout card.
enum BuildsMockCardDensity { tile, list, detail }

/// Hybrid loadout card: compact browse tile / dense list / fuller detail.
///
/// Browse tiles omit Fill In / Optimize; detail screen hosts those disabled.
class BuildsMockLoadoutCard extends StatelessWidget {
  const BuildsMockLoadoutCard({
    super.key,
    required this.loadout,
    this.selected = false,
    this.onSelect,
    this.density = BuildsMockCardDensity.tile,
    this.priorities = const [],
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final BuildsMockCardDensity density;
  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    switch (density) {
      case BuildsMockCardDensity.list:
        return _ListRow(
          loadout: loadout,
          selected: selected,
          onSelect: onSelect,
          priorities: priorities,
        );
      case BuildsMockCardDensity.tile:
        return _CompactTile(
          loadout: loadout,
          selected: selected,
          onSelect: onSelect,
          priorities: priorities,
        );
      case BuildsMockCardDensity.detail:
        return _DetailCard(
          loadout: loadout,
          selected: selected,
          onSelect: onSelect,
          priorities: priorities,
        );
    }
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.loadout,
    required this.selected,
    required this.onSelect,
    required this.priorities,
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected ? palette.accent : palette.line;
    final perkCount = loadout.artifact.perks.length;
    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: palette.surfaceRaised,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: kFlapRuleThickness),
          ),
          padding: const EdgeInsets.all(kPanelPadSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loadout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _SubclassBadge(subclass: loadout.subclass),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                loadout.exoticArmor.isEmpty ? '—' : loadout.exoticArmor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                loadout.exoticWeapon.isEmpty ? '—' : loadout.exoticWeapon,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _PrioritiesRow(priorities: priorities),
              const SizedBox(height: 4),
              Text(
                '$perkCount artifact perk${perkCount == 1 ? '' : 's'}',
                key: Key('builds_mock_artifact_count_${loadout.id}'),
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
              if (loadout.solipsismNotPrismatic) ...[
                const SizedBox(height: 4),
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
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.loadout,
    required this.selected,
    required this.onSelect,
    required this.priorities,
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final perkCount = loadout.artifact.perks.length;
    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: selected ? palette.accentDim : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loadout.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        _SubclassBadge(subclass: loadout.subclass),
                      ],
                    ),
                    if (loadout.solipsismNotPrismatic)
                      Text(
                        'Solipsism only works with Prismatic',
                        key: Key('builds_mock_solipsism_flag_${loadout.id}'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loadout.exoticArmor.isEmpty ? '—' : loadout.exoticArmor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loadout.exoticWeapon.isEmpty ? '—' : loadout.exoticWeapon,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _PrioritiesRow(priorities: priorities),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text(
                  '$perkCount perk${perkCount == 1 ? '' : 's'}',
                  key: Key('builds_mock_artifact_count_${loadout.id}'),
                  style: neonMono(color: palette.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.loadout,
    required this.selected,
    required this.onSelect,
    required this.priorities,
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected ? palette.accent : palette.line;
    final perkCount = loadout.artifact.perks.length;
    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: palette.surfaceRaised,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: kFlapRuleThickness),
          ),
          padding: const EdgeInsets.all(kPanelPadSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loadout.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _SubclassBadge(subclass: loadout.subclass),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Exotic armor: ${loadout.exoticArmor.isEmpty ? '—' : loadout.exoticArmor}',
                style: TextStyle(
                  color: palette.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Exotic weapon: ${loadout.exoticWeapon.isEmpty ? '—' : loadout.exoticWeapon}',
                style: TextStyle(
                  color: palette.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _PrioritiesRow(priorities: priorities),
              const SizedBox(height: 6),
              Text(
                '$perkCount artifact perk${perkCount == 1 ? '' : 's'}'
                '${loadout.artifact.name == '—' ? '' : ' · ${loadout.artifact.name}'}',
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
              if (loadout.loop.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  loadout.loop,
                  style: neonMono(color: palette.muted, fontSize: 12),
                ),
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
}

class _SubclassBadge extends StatelessWidget {
  const _SubclassBadge({required this.subclass});

  final String subclass;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final color = _subclassColor(palette, subclass);
    return Container(
      key: Key('builds_mock_subclass_badge_$subclass'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            subclass,
            style: neonDisplay(
              color: color,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritiesRow extends StatelessWidget {
  const _PrioritiesRow({required this.priorities});

  final List<BuildsMockStatPriority> priorities;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (priorities.isEmpty) {
      return Text(
        'No stat priorities',
        style: neonMono(color: palette.muted, fontSize: 11),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final p in priorities)
          Text(
            p.inferred ? '${p.label} (inferred)' : p.label,
            style: neonMono(color: palette.foreground, fontSize: 11),
          ),
      ],
    );
  }
}

Color _subclassColor(FlapPalette palette, String subclass) {
  switch (subclass.toLowerCase()) {
    case 'solar':
      return palette.elementSolar;
    case 'arc':
      return palette.elementArc;
    case 'void':
      return palette.elementVoid;
    case 'stasis':
      return palette.elementStasis;
    case 'strand':
      return palette.elementStrand;
    case 'prismatic':
      return palette.elementPrismatic;
    default:
      return palette.muted;
  }
}
