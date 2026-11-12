import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Quiet DIM link details for a build card / detail pane.
///
/// Notes and descriptions render as plain [Text] only — no markdown, HTML,
/// or tappable links. Inferred rankings are display-only.
class DimLoadoutDetailsPanel extends StatelessWidget {
  const DimLoadoutDetailsPanel({
    super.key,
    required this.status,
    this.loadout,
    this.ambiguousCount = 0,
  });

  /// Reader / match status for this card.
  final DimLoadoutsPanelStatus status;

  /// Matched compiled loadout when [status] is [DimLoadoutsPanelStatus.loaded].
  final CachedDimLoadout? loadout;

  /// Exotic-only (or multi-name) collision count when [status] is ambiguous.
  final int ambiguousCount;

  factory DimLoadoutDetailsPanel.fromBinding(DimLoadoutCardBinding binding) {
    return DimLoadoutDetailsPanel(
      status: binding.status,
      loadout: binding.loadout,
      ambiguousCount: binding.ambiguousCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      key: const Key('dim_loadout_details_panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: _body(context, palette),
    );
  }

  Widget _body(BuildContext context, FlapPalette palette) {
    if (status == DimLoadoutsPanelStatus.ambiguous) {
      return Text(
        'ambiguous ($ambiguousCount loadouts)',
        key: const Key('dim_loadout_details_ambiguous'),
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }
    if (status == DimLoadoutsPanelStatus.unreadable) {
      return Text(
        'DIM link details unreadable',
        key: const Key('dim_loadout_details_unreadable'),
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }
    if (status != DimLoadoutsPanelStatus.loaded || loadout == null) {
      return Text(
        'DIM link details not loaded',
        key: const Key('dim_loadout_details_not_loaded'),
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }

    final data = loadout!;
    final ranking = rankDimLoadoutStats(data);
    return Column(
      key: Key('dim_loadout_details_${data.shareId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIM LINK DETAILS',
          style: TextStyle(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'STAT RANKING'),
        ..._rankingLines(context, palette, ranking),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'EXOTIC'),
        Text(
          data.exotic?.name ?? '—',
          style: TextStyle(color: palette.foreground, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'SUBCLASS PLUGS'),
        ..._namedLines(palette, data.subclassPlugs),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'MODS'),
        ..._namedLines(palette, data.mods),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'ARTIFACT PERKS'),
        ..._namedLines(palette, data.artifactPerks),
        const SizedBox(height: 8),
        _sectionTitle(palette, 'NOTES'),
        Text(
          (data.notes == null || data.notes!.trim().isEmpty)
              ? '—'
              : data.notes!,
          // Plain text only — untrusted third-party notes.
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _sectionTitle(FlapPalette palette, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          color: palette.muted,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  List<Widget> _rankingLines(
    BuildContext context,
    FlapPalette palette,
    DisplayOnlyStatRanking ranking,
  ) {
    if (ranking.source == DimStatRankingSource.unknown ||
        ranking.entries.isEmpty) {
      return [
        Text(
          'unknown',
          key: const Key('dim_loadout_stat_unknown'),
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
      ];
    }
    return [
      for (final row in ranking.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            _rankLine(row),
            key: Key('dim_loadout_stat_${row.stat.wireName}'),
            style: TextStyle(color: palette.foreground, fontSize: 12),
          ),
        ),
    ];
  }

  String _rankLine(RankedDimStat row) {
    final words = row.matchedWords.isEmpty
        ? ''
        : ' · matched: ${row.matchedWords.join(', ')}';
    return '#${row.rank} ${row.stat.wireName} (${row.label})$words';
  }

  List<Widget> _namedLines(
    FlapPalette palette,
    List<CachedDimNamedHash> rows,
  ) {
    if (rows.isEmpty) {
      return [
        Text('—', style: TextStyle(color: palette.muted, fontSize: 12)),
      ];
    }
    return [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            row.name,
            style: TextStyle(color: palette.foreground, fontSize: 12),
          ),
        ),
    ];
  }
}

/// Host-facing load status for [DimLoadoutDetailsPanel].
///
/// Mirrors storage [DimLoadoutsReadStatus] without importing storage here so
/// the panel stays a thin view over domain models.
enum DimLoadoutsPanelStatus { notLoaded, unreadable, loaded, ambiguous }

/// Card-level binding from [matchCachedDimLoadout] + reader status.
class DimLoadoutCardBinding {
  const DimLoadoutCardBinding._({
    required this.status,
    this.loadout,
    this.ambiguousCount = 0,
  });

  const DimLoadoutCardBinding.notLoaded()
      : this._(status: DimLoadoutsPanelStatus.notLoaded);

  const DimLoadoutCardBinding.unreadable()
      : this._(status: DimLoadoutsPanelStatus.unreadable);

  const DimLoadoutCardBinding.matched(CachedDimLoadout loadout)
      : this._(status: DimLoadoutsPanelStatus.loaded, loadout: loadout);

  const DimLoadoutCardBinding.ambiguous(int count)
      : this._(status: DimLoadoutsPanelStatus.ambiguous, ambiguousCount: count);

  final DimLoadoutsPanelStatus status;
  final CachedDimLoadout? loadout;
  final int ambiguousCount;
}
