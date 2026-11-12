import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'builds_mock_models.dart';

/// Density for the hybrid B+E loadout card.
enum BuildsMockCardDensity { tile, list, detail }

/// Hybrid loadout card: B highlights on top, E armor list + icon stats below.
///
/// Includes disabled mock actions "Fill In" and "Optimize".
class BuildsMockLoadoutCard extends StatelessWidget {
  const BuildsMockLoadoutCard({
    super.key,
    required this.loadout,
    this.selected = false,
    this.onSelect,
    this.density = BuildsMockCardDensity.tile,
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final BuildsMockCardDensity density;

  @override
  Widget build(BuildContext context) {
    if (density == BuildsMockCardDensity.list) {
      return _ListRow(
        loadout: loadout,
        selected: selected,
        onSelect: onSelect,
      );
    }
    return _TileOrDetail(
      loadout: loadout,
      selected: selected,
      onSelect: onSelect,
      dense: density == BuildsMockCardDensity.tile,
    );
  }
}

class _TileOrDetail extends StatelessWidget {
  const _TileOrDetail({
    required this.loadout,
    required this.selected,
    required this.onSelect,
    required this.dense,
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected ? palette.accent : palette.line;
    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: palette.surfaceRaised,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: kFlapRuleThickness),
          ),
          padding: EdgeInsets.all(dense ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(loadout: loadout),
              SizedBox(height: dense ? 8 : 12),
              _ExoticHighlight(loadout: loadout),
              SizedBox(height: dense ? 8 : 12),
              Text(
                loadout.loop,
                style: neonMono(color: palette.muted, fontSize: 12),
              ),
              SizedBox(height: dense ? 6 : 8),
              for (final bonus in loadout.setBonuses) ...[
                _SetBonusBlock(bonus: bonus, dense: dense),
                SizedBox(height: dense ? 4 : 6),
              ],
              _ArtifactRow(loadout: loadout, showSeason: !dense),
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
              const SizedBox(height: 10),
              Divider(height: 1, color: palette.line),
              const SizedBox(height: 8),
              Text(
                'ARMOR',
                style: neonDisplay(
                  color: palette.muted,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              _ArmorList(loadout: loadout),
              const SizedBox(height: 10),
              Text(
                'STATS',
                style: neonDisplay(
                  color: palette.muted,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              _StatsBand(loadout: loadout, layout: dense ? _StatsLayout.row : _StatsLayout.grid),
              const SizedBox(height: 12),
              _CardActions(buildId: loadout.id),
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
  });

  final MockBuild loadout;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      key: Key('builds_mock_card_${loadout.id}'),
      color: selected ? palette.accentDim : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        _SubclassDot(subclass: loadout.subclass),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loadout.loop,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: neonMono(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loadout.exoticArmor,
                      style: TextStyle(
                        color: palette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loadout.exoticWeapon,
                      style: TextStyle(
                        color: palette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loadout.artifact.name,
                      style: TextStyle(
                        color: palette.elementPrismatic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in loadout.setBonuses)
                      Text(
                        '${b.tier} ${b.setName} · ${b.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: neonMono(color: palette.muted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final s in loadout.slots)
                      Text(
                        '${(kMockArmorSlotLabels[s.slot] ?? s.slot).substring(0, 3)} ${s.statTotal}',
                        style: TextStyle(
                          color: s.isExoticSlot
                              ? palette.warning
                              : palette.muted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatsBand(loadout: loadout, layout: _StatsLayout.row),
              const SizedBox(width: 8),
              _CardActions(buildId: loadout.id, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.loadout});

  final MockBuild loadout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            loadout.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _SubclassDot(subclass: loadout.subclass),
        const SizedBox(width: 6),
        Text(
          loadout.subclass,
          style: neonDisplay(fontSize: 11, letterSpacing: 0.6),
        ),
      ],
    );
  }
}

class _SubclassDot extends StatelessWidget {
  const _SubclassDot({required this.subclass});

  final String subclass;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _subclassColor(palette, subclass),
        shape: BoxShape.circle,
      ),
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

class _ExoticHighlight extends StatelessWidget {
  const _ExoticHighlight({required this.loadout});

  final MockBuild loadout;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: _ExoticCell(
            label: 'EXOTIC ARMOR',
            value: loadout.exoticArmor,
            icon: Icons.shield_outlined,
            palette: palette,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ExoticCell(
            label: 'EXOTIC WEAPON',
            value: loadout.exoticWeapon,
            icon: Icons.gps_fixed,
            palette: palette,
          ),
        ),
      ],
    );
  }
}

class _ExoticCell extends StatelessWidget {
  const _ExoticCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.palette,
  });

  final String label;
  final String value;
  final IconData icon;
  final FlapPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: palette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: neonDisplay(
                    color: palette.muted,
                    fontSize: 8,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  value,
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
        ],
      ),
    );
  }
}

class _SetBonusBlock extends StatelessWidget {
  const _SetBonusBlock({required this.bonus, required this.dense});

  final MockSetBonus bonus;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: dense ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_outlined, size: 14, color: palette.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${bonus.pieces}pc ${bonus.setName}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.line),
                ),
                child: Text(
                  bonus.tier,
                  style: neonMono(color: palette.muted, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            bonus.text,
            style: neonMono(color: palette.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ArtifactRow extends StatelessWidget {
  const _ArtifactRow({required this.loadout, required this.showSeason});

  final MockBuild loadout;
  final bool showSeason;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 14, color: palette.elementPrismatic),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            loadout.artifact.name,
            style: TextStyle(
              color: palette.elementPrismatic,
              fontSize: 12,
            ),
          ),
        ),
        if (showSeason) ...[
          Text(
            ' · ${loadout.artifact.season}',
            style: neonMono(color: palette.muted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _ArmorList extends StatelessWidget {
  const _ArmorList({required this.loadout});

  final MockBuild loadout;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Column(
      children: [
        for (final slot in loadout.slots)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: palette.line,
                  width: kFlapRuleThickness,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    kMockArmorSlotLabels[slot.slot] ?? slot.slot,
                    style: neonMono(color: palette.muted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    slot.pieceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: slot.isExoticSlot
                          ? palette.warning
                          : palette.foreground,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  slot.isExoticSlot
                      ? 'Exotic'
                      : _setDisplayName(slot.setId),
                  style: neonMono(color: palette.muted, fontSize: 11),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${slot.statTotal}',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _setDisplayName(String setId) {
    switch (setId) {
      case 'set_techsec':
        return 'Techsec';
      case 'set_walk':
        return "Walker's Bond";
      case 'set_aion':
        return 'Aion Renewal';
      case 'set_brazen':
        return 'Brazen Gambit';
      default:
        return setId;
    }
  }
}

enum _StatsLayout { row, grid }

class _StatsBand extends StatelessWidget {
  const _StatsBand({required this.loadout, required this.layout});

  final MockBuild loadout;
  final _StatsLayout layout;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (layout == _StatsLayout.grid) {
      return Row(
        children: [
          for (final s in loadout.stats)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: palette.line,
                    width: kFlapRuleThickness,
                  ),
                ),
                child: Column(
                  children: [
                    MockStatStrokeIcon(
                      id: s.id,
                      color: palette.accent,
                      size: 14,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.value}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final s in loadout.stats)
          Tooltip(
            message: s.label,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MockStatStrokeIcon(
                  id: s.id,
                  color: palette.accent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.value}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.buildId, this.compact = false});

  final String buildId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fillIn = FilledButton.tonal(
      key: Key('builds_mock_fill_in_$buildId'),
      onPressed: null,
      child: const Text('Fill In'),
    );
    final optimize = OutlinedButton(
      key: Key('builds_mock_optimize_$buildId'),
      onPressed: null,
      child: const Text('Optimize'),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          fillIn,
          const SizedBox(height: 4),
          optimize,
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [fillIn, optimize],
    );
  }
}

/// Stroke stand-in icons for the six EoF armor stats (no downloaded Destiny art).
class MockStatStrokeIcon extends StatelessWidget {
  const MockStatStrokeIcon({
    super.key,
    required this.id,
    required this.color,
    this.size = 14,
  });

  final MockStatId id;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StatIconPainter(id: id, color: color),
    );
  }
}

class _StatIconPainter extends CustomPainter {
  _StatIconPainter({required this.id, required this.color});

  final MockStatId id;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final s = size.shortestSide;
    switch (id) {
      case MockStatId.health:
        final path = Path()
          ..moveTo(s * 0.5, s * 0.18)
          ..cubicTo(s * 0.32, s * 0.02, s * 0.08, s * 0.18, s * 0.12, s * 0.4)
          ..cubicTo(s * 0.18, s * 0.62, s * 0.4, s * 0.78, s * 0.5, s * 0.9)
          ..cubicTo(s * 0.6, s * 0.78, s * 0.82, s * 0.62, s * 0.88, s * 0.4)
          ..cubicTo(s * 0.92, s * 0.18, s * 0.68, s * 0.02, s * 0.5, s * 0.18);
        canvas.drawPath(path, paint);
      case MockStatId.melee:
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.22, s * 0.28, s * 0.56, s * 0.52),
          Radius.circular(s * 0.12),
        );
        canvas.drawRRect(r, paint);
        canvas.drawLine(
          Offset(s * 0.35, s * 0.28),
          Offset(s * 0.35, s * 0.16),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.5, s * 0.28),
          Offset(s * 0.5, s * 0.12),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.65, s * 0.28),
          Offset(s * 0.65, s * 0.16),
          paint,
        );
      case MockStatId.grenade:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.58),
            width: s * 0.52,
            height: s * 0.58,
          ),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.38, s * 0.3),
          Offset(s * 0.62, s * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.5, s * 0.3),
          Offset(s * 0.5, s * 0.16),
          paint,
        );
      case MockStatId.superAbility:
        final path = Path()
          ..moveTo(s * 0.5, s * 0.08)
          ..lineTo(s * 0.58, s * 0.38)
          ..lineTo(s * 0.9, s * 0.38)
          ..lineTo(s * 0.64, s * 0.56)
          ..lineTo(s * 0.74, s * 0.88)
          ..lineTo(s * 0.5, s * 0.7)
          ..lineTo(s * 0.26, s * 0.88)
          ..lineTo(s * 0.36, s * 0.56)
          ..lineTo(s * 0.1, s * 0.38)
          ..lineTo(s * 0.42, s * 0.38)
          ..close();
        canvas.drawPath(path, paint);
      case MockStatId.classAbility:
        final outer = Path()
          ..moveTo(s * 0.5, s * 0.1)
          ..lineTo(s * 0.9, s * 0.5)
          ..lineTo(s * 0.5, s * 0.9)
          ..lineTo(s * 0.1, s * 0.5)
          ..close();
        final inner = Path()
          ..moveTo(s * 0.5, s * 0.3)
          ..lineTo(s * 0.7, s * 0.5)
          ..lineTo(s * 0.5, s * 0.7)
          ..lineTo(s * 0.3, s * 0.5)
          ..close();
        canvas.drawPath(outer, paint);
        canvas.drawPath(inner, paint);
      case MockStatId.weapons:
        canvas.drawLine(
          Offset(s * 0.15, s * 0.75),
          Offset(s * 0.7, s * 0.2),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.7, s * 0.2),
          Offset(s * 0.85, s * 0.35),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.85, s * 0.75),
          Offset(s * 0.3, s * 0.2),
          paint,
        );
        canvas.drawLine(
          Offset(s * 0.3, s * 0.2),
          Offset(s * 0.15, s * 0.35),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _StatIconPainter oldDelegate) {
    return oldDelegate.id != id || oldDelegate.color != color;
  }
}
