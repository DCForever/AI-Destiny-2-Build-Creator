import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flap_element.dart';
import 'flap_palette.dart';
import 'neon_fonts.dart';

/// One column in a DIM-style perk grid (equipped + alternates).
class PerkColumnView {
  const PerkColumnView({
    required this.label,
    required this.options,
    this.kind,
  });

  final String label;
  final String? kind;
  final List<PerkOptionView> options;
}

class PerkOptionView {
  const PerkOptionView({
    required this.hash,
    required this.displayName,
    this.equipped = false,
  });

  final int hash;
  final String displayName;
  final bool equipped;
}

/// Build perk columns from stored socket plugs (DART-052 shape).
///
/// Prefer [columnLabel] / [columnKind]; list equipped + reusable hashes.
/// Falls back to flat [plugCards] when sockets are missing.
List<PerkColumnView> buildPerkColumns({
  List<Map<String, Object?>>? socketPlugs,
  List<ResolvedPlugCard> plugCards = const [],
  Map<int, String> plugNameByHash = const {},
}) {
  if (socketPlugs != null && socketPlugs.isNotEmpty) {
    final cols = <PerkColumnView>[];
    for (final raw in socketPlugs) {
      final kind = raw['columnKind'] as String?;
      final label = (raw['columnLabel'] as String?)?.trim();
      final equippedRaw = raw['equippedPlugHash'];
      final equipped = equippedRaw is int
          ? equippedRaw
          : equippedRaw is num
              ? equippedRaw.toInt()
              : null;
      final reusable = <int>[];
      final rawReusable = raw['reusablePlugHashes'];
      if (rawReusable is List) {
        for (final e in rawReusable) {
          final h = e is int
              ? e
              : e is num
                  ? e.toInt()
                  : int.tryParse('$e');
          if (h != null && h != 0) reusable.add(h);
        }
      }
      final hashes = <int>[];
      if (equipped != null && equipped != 0) hashes.add(equipped);
      for (final h in reusable) {
        if (!hashes.contains(h)) hashes.add(h);
      }
      if (hashes.isEmpty) continue;
      final colLabel = (label != null && label.isNotEmpty)
          ? label
          : (kind != null && kind.isNotEmpty)
              ? _titleCase(kind)
              : 'Plug';
      cols.add(
        PerkColumnView(
          label: colLabel,
          kind: kind,
          options: [
            for (final h in hashes)
              PerkOptionView(
                hash: h,
                displayName: plugNameByHash[h] ??
                    _nameFromCards(plugCards, h) ??
                    '#$h',
                equipped: h == equipped,
              ),
          ],
        ),
      );
    }
    if (cols.isNotEmpty) return List.unmodifiable(cols);
  }

  // Flat cards → single "Perks" column or group by columnLabel.
  if (plugCards.isEmpty) return const [];
  final byLabel = <String, List<ResolvedPlugCard>>{};
  for (final c in plugCards) {
    final key = (c.columnLabel != null && c.columnLabel!.isNotEmpty)
        ? c.columnLabel!
        : (c.isTrait ? 'Trait' : 'Perk');
    byLabel.putIfAbsent(key, () => []).add(c);
  }
  return [
    for (final e in byLabel.entries)
      PerkColumnView(
        label: e.key,
        options: [
          for (final c in e.value)
            PerkOptionView(
              hash: c.hash,
              displayName: c.displayName,
              equipped: true,
            ),
        ],
      ),
  ];
}

String? _nameFromCards(List<ResolvedPlugCard> cards, int hash) {
  for (final c in cards) {
    if (c.hash == hash) return c.displayName;
  }
  return null;
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .split(RegExp(r'[_\s]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

/// Which richness sections exist for this surface.
enum ItemRichnessSection {
  definition,
  stats,
  perks,
  tags,
  advanced,
}

/// Collapsible item dossier — denser than a DIM roll card; sections hide.
///
/// Design: Matte Flap Ledger “Item Dossier”
/// (`.impeccable/flutter/item-richness/item-dossier.html`).
class ItemRichnessPanel extends StatefulWidget {
  const ItemRichnessPanel({
    super.key,
    this.definition,
    this.instance,
    this.kindLabel,
    this.plugNameByHash = const {},
    this.initialOpen = const {
      ItemRichnessSection.perks,
      ItemRichnessSection.stats,
    },
    this.onCopyMessage,
  });

  final CatalogItem? definition;
  final CatalogInstanceProjection? instance;
  final String? kindLabel;
  final Map<int, String> plugNameByHash;

  /// Sections open on first paint (Scan preset ≈ perks + stats).
  final Set<ItemRichnessSection> initialOpen;

  final ValueChanged<String>? onCopyMessage;

  @override
  State<ItemRichnessPanel> createState() => _ItemRichnessPanelState();
}

class _ItemRichnessPanelState extends State<ItemRichnessPanel> {
  late Set<ItemRichnessSection> _open;

  @override
  void initState() {
    super.initState();
    _open = {...widget.initialOpen};
  }

  void _toggle(ItemRichnessSection s) {
    setState(() {
      if (_open.contains(s)) {
        _open.remove(s);
      } else {
        _open.add(s);
      }
    });
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'scan':
          _open = {
            if (widget.instance?.armorStats != null) ItemRichnessSection.stats,
            if (_hasPerks) ItemRichnessSection.perks,
          };
        case 'roll':
          _open = {
            ItemRichnessSection.definition,
            if (widget.instance?.armorStats != null) ItemRichnessSection.stats,
            if (_hasPerks) ItemRichnessSection.perks,
            ItemRichnessSection.tags,
          };
        case 'all':
          _open = ItemRichnessSection.values.toSet();
        case 'none':
          _open = {};
      }
    });
  }

  bool get _hasPerks {
    final inst = widget.instance;
    if (inst == null) return false;
    return (inst.socketPlugs != null && inst.socketPlugs!.isNotEmpty) ||
        inst.plugCards.isNotEmpty ||
        inst.plugHashes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final inst = widget.instance;
    final theme = Theme.of(context);
    final columns = buildPerkColumns(
      socketPlugs: inst?.socketPlugs,
      plugCards: inst?.plugCards ?? const [],
      plugNameByHash: widget.plugNameByHash,
    );

    // mainAxisSize.min: safe as ListView child (no nested vertical viewport).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _IdentityStrip(
          definition: def,
          instance: inst,
          kindLabel: widget.kindLabel,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            key: const Key('item_richness_presets'),
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final p in const [
                ('scan', 'Scan'),
                ('roll', 'Full roll'),
                ('all', 'Expand all'),
                ('none', 'Collapse'),
              ])
                OutlinedButton(
                  key: Key('item_richness_preset_${p.$1}'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _applyPreset(p.$1),
                  child: Text(p.$2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (def != null)
          _FlapSection(
            sectionKey: 'definition',
            title: 'Definition',
            tally: 'frame · intrinsic',
            open: _open.contains(ItemRichnessSection.definition),
            onToggle: () => _toggle(ItemRichnessSection.definition),
            child: _DefinitionBody(definition: def),
          ),
        if (inst?.armorStats != null && inst!.armorStats!.hasAny)
          _FlapSection(
            sectionKey: 'stats',
            title: 'Base stats',
            tally: 'EoF six · total',
            open: _open.contains(ItemRichnessSection.stats),
            onToggle: () => _toggle(ItemRichnessSection.stats),
            child: _ArmorStatsBody(board: inst.armorStats!),
          ),
        if (columns.isNotEmpty || (inst?.plugHashes.isNotEmpty ?? false))
          _FlapSection(
            sectionKey: 'perks',
            title: 'Perks',
            tally: columns.isNotEmpty
                ? '${columns.length} col · copy roll'
                : '${inst!.plugHashes.length} plugs',
            open: _open.contains(ItemRichnessSection.perks),
            onToggle: () => _toggle(ItemRichnessSection.perks),
            child: columns.isNotEmpty
                ? _PerkGrid(columns: columns)
                : Text(
                    '${inst!.plugHashes.length} plugs (names not resolved yet)',
                    style: theme.textTheme.bodySmall,
                  ),
          ),
        if (inst != null)
          _FlapSection(
            sectionKey: 'tags',
            title: 'Tags & location',
            tally: inst.rollTags.isEmpty
                ? inst.location
                : '${inst.rollTags.length} tags',
            open: _open.contains(ItemRichnessSection.tags),
            onToggle: () => _toggle(ItemRichnessSection.tags),
            child: _TagsBody(instance: inst),
          ),
        _FlapSection(
          sectionKey: 'advanced',
          title: 'Advanced',
          tally: 'ids · hashes',
          open: _open.contains(ItemRichnessSection.advanced),
          onToggle: () => _toggle(ItemRichnessSection.advanced),
          child: _AdvancedBody(
            definition: def,
            instance: inst,
            onCopyMessage: widget.onCopyMessage,
          ),
        ),
      ],
    );
  }
}

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    this.definition,
    this.instance,
    this.kindLabel,
  });

  final CatalogItem? definition;
  final CatalogInstanceProjection? instance;
  final String? kindLabel;

  @override
  Widget build(BuildContext context) {
    final name = definition?.name ?? 'Item';
    final element = definition?.element;
    final chips = <Widget>[
      if (kindLabel != null && kindLabel!.isNotEmpty)
        _MetaChip(kindLabel!),
      if (definition?.itemTypeName != null)
        _MetaChip(definition!.itemTypeName!),
      if (definition?.frame != null && definition!.frame!.isNotEmpty)
        _MetaChip(definition!.frame!),
      if (definition?.isExotic == true) const _MetaChip('Exotic'),
      if (instance != null) ...[
        if (instance!.isMasterwork) const _MetaChip('MW', warn: true),
        if (instance!.isCrafted) const _MetaChip('Crafted', ok: true),
        if (instance!.gearTier != null)
          _MetaChip('Tier ${instance!.gearTier}'),
        if (definition != null && definition!.ownedCount > 0)
          _MetaChip('Owned ×${definition!.ownedCount}', lamp: true),
      ],
    ];

    final elColor = flapElementColor(context, element);
    final exotic = definition?.isExotic == true;
    final palette = FlapPalette.of(context);

    return Container(
      key: const Key('item_richness_identity'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: exotic
            ? LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(kRarityExotic).withValues(alpha: 0.18),
                  Color(kRarityExotic).withValues(alpha: 0.06),
                  palette.surface.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.35, 0.7],
              )
            : null,
        border: Border(
          left: BorderSide(
            color: elColor ?? palette.line,
            width: 3,
          ),
          bottom: BorderSide(
            color: palette.line,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (definition?.slot != null || kindLabel != null)
            Text(
              [
                if (kindLabel != null) kindLabel!,
                if (definition?.slot != null) definition!.slot!,
              ].join(' · ').toUpperCase(),
              style: neonMono(
                color: palette.muted,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
          Text(
            name,
            // Catalog tests look for this key on owned instance detail.
            key: instance != null
                ? const Key('instance_panel_title')
                : null,
            style: neonDisplay(
              color: exotic ? Color(kRarityExotic) : palette.foreground,
              fontSize: 16,
              letterSpacing: 0.04 * 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (instance != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'PWR ',
                        style: neonMono(
                          color: palette.muted,
                          fontSize: 10,
                        ),
                      ),
                      TextSpan(
                        text: '${instance!.power}',
                        style: neonMono(
                          color: palette.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (element != null)
                _MetaChip(element, elementColor: elColor),
              ...chips,
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(
    this.label, {
    this.lamp = false,
    this.warn = false,
    this.ok = false,
    this.elementColor,
  });

  final String label;
  final bool lamp;
  final bool warn;
  final bool ok;
  final Color? elementColor;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    Color border = palette.line;
    Color fg = palette.foreground;
    Color? bg;
    if (elementColor != null) {
      border = elementColor!;
      fg = elementColor!;
    } else if (lamp) {
      border = palette.accent;
      fg = palette.accentStrong;
      bg = palette.accentDim;
    } else if (warn) {
      border = palette.warning;
      fg = palette.warning;
    } else if (ok) {
      border = palette.success;
      fg = palette.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: kFlapRuleThickness),
        borderRadius: BorderRadius.circular(kRadiusMax),
      ),
      child: Text(
        label.toUpperCase(),
        style: neonMono(
          color: fg,
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FlapSection extends StatelessWidget {
  const _FlapSection({
    required this.sectionKey,
    required this.title,
    required this.tally,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String sectionKey;
  final String title;
  final String tally;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('item_richness_section_$sectionKey'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('item_richness_toggle_$sectionKey'),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    tally,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: open
                        ? const Color(0xFF4EC4BC)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _DefinitionBody extends StatelessWidget {
  const _DefinitionBody({this.definition});

  final CatalogItem? definition;

  @override
  Widget build(BuildContext context) {
    final d = definition;
    if (d == null) {
      return Text(
        'No definition metadata.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.description != null && d.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              d.description!,
              key: const Key('item_richness_description'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        _kv(context, 'Slot', d.slot),
        _kv(context, 'Frame', d.frame),
        _kv(context, 'Ammo', d.ammo),
        _kv(context, 'Class', d.classType),
        _kv(context, 'Type', d.itemTypeName),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(child: Text(v, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ArmorStatsBody extends StatelessWidget {
  const _ArmorStatsBody({required this.board});

  final ArmorBaseStatBoard board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Avoid GridView inside outer ListView (unbounded height / paint glitches).
    final keys = armorBaseStatKeys;
    Widget cell(String key) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(0.5),
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                key.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${board.stats[key] ?? '—'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'IBM Plex Mono',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const Key('item_richness_armor_stats'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [for (var i = 0; i < 3; i++) cell(keys[i])]),
        Row(children: [for (var i = 3; i < 6; i++) cell(keys[i])]),
        if (board.total != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${board.total}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'IBM Plex Mono',
                    color: const Color(0xFF6FD4CD),
                  ),
                ),
              ],
            ),
          ),
        if (board.incomplete)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Some stats missing on this copy.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _PerkGrid extends StatelessWidget {
  const _PerkGrid({required this.columns});

  final List<PerkColumnView> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LayoutBuilder: column width tracks detail pane (avoids fixed 148 overflow).
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final colW = (maxW / 2).clamp(120.0, 160.0);
        return Wrap(
          key: const Key('item_richness_perk_grid'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final col in columns)
              SizedBox(
                width: colW,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          col.label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      for (final opt in col.options)
                        Container(
                          key: Key(
                            'item_richness_perk_${col.label}_${opt.hash}',
                          ),
                          decoration: BoxDecoration(
                            color: opt.equipped
                                ? const Color(0x244EC4BC)
                                : null,
                            border: Border(
                              left: BorderSide(
                                color: opt.equipped
                                    ? const Color(0xFF4EC4BC)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              bottom: BorderSide(
                                color: theme.dividerColor,
                                width: kFlapRuleThickness,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: opt.equipped
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: opt.equipped
                                        ? null
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (opt.equipped)
                                Text(
                                  'EQ',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: const Color(0xFF4EC4BC),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TagsBody extends StatelessWidget {
  const _TagsBody({required this.instance});

  final CatalogInstanceProjection instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instance.rollTags.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final t in instance.rollTags)
                _MetaChip(t),
            ],
          )
        else
          Text(
            'No roll tags.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Location: ${instance.location}',
          style: theme.textTheme.bodySmall,
        ),
        if (instance.bucket.isNotEmpty)
          Text(
            'Bucket: ${instance.bucket}',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _AdvancedBody extends StatelessWidget {
  const _AdvancedBody({
    this.definition,
    this.instance,
    this.onCopyMessage,
  });

  final CatalogItem? definition;
  final CatalogInstanceProjection? instance;
  final ValueChanged<String>? onCopyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'IBM Plex Mono',
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instance != null)
          SelectableText(
            'instanceId: ${instance!.instanceId}',
            style: mono,
          ),
        if (definition != null)
          SelectableText(
            'itemHash: ${definition!.hash}',
            style: mono,
          ),
        if (instance?.characterId != null)
          SelectableText(
            'characterId: ${instance!.characterId}',
            style: mono,
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (instance != null)
              OutlinedButton(
                key: const Key('item_richness_copy_instance'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: instance!.instanceId),
                  );
                  onCopyMessage?.call('Copied instance id');
                },
                child: const Text('Copy instance'),
              ),
            if (definition != null)
              OutlinedButton(
                key: const Key('item_richness_copy_hash'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '${definition!.hash}'),
                  );
                  onCopyMessage?.call(
                    'Copied definition hash ${definition!.hash}',
                  );
                },
                child: const Text('Copy hash'),
              ),
          ],
        ),
      ],
    );
  }
}
