/// FlapBoard **layout contracts** (not widgets) — Matte Flap Ledger.
///
/// Product libraries (Sets / Synergy / Builds) are continuous ruled boards, not
/// card stacks. Hosts implement rows with CSS grid (Next/Jaspr) or Flutter
/// tables/rows using these dimensions and column templates.
///
/// See product `src/components/ui/FlapRow.tsx` and DESIGN.md “Board Not Cards”.
library;

/// Preferred library rail width (Workspace dual-pane) — logical px.
const double kFlapLibraryRailWidth = 320;

/// Zero gap between stacked flap rows (continuous board).
const double kFlapBoardRowGap = 0;

/// 1px hairline rule thickness between rows / cells.
const double kFlapRuleThickness = 1;

/// Max page frame width (DESIGN PageFrame).
const double kPageFrameMaxWidth = 1600;

/// Exotic seal size (icons on flap rows).
const double kFlapSealSize = 22;

/// Channel wash dosage target (~8–12%); hosts apply as alpha on channel color.
const double kFlapChannelWashAlpha = 0.10;

/// Badge wash fill dosage (~10–12%).
const double kFlapBadgeWashAlpha = 0.12;

/// Named cell roles for library boards (documentation + stable keys).
enum FlapCellRole {
  name,
  identity,
  type,
  tags,
  exotics,
  synergy,
  status,
  meta,
  tally,
}

/// One library board’s column layout contract.
class FlapColumnTemplate {
  const FlapColumnTemplate({
    required this.id,
    required this.columnsCss,
    required this.cellRoles,
    required this.headerLabels,
  });

  /// Stable id: `sets` | `synergy` | `builds`.
  final String id;

  /// CSS `grid-template-columns` value (also a guide for Flutter flex factors).
  final String columnsCss;

  /// Cell roles left→right matching [columnsCss] track count.
  final List<FlapCellRole> cellRoles;

  /// Default header labels (uppercase board chrome).
  final List<String> headerLabels;
}

/// Sets library: NAME · TYPE · TAGS · STATUS
const FlapColumnTemplate kFlapColumnsSets = FlapColumnTemplate(
  id: 'sets',
  columnsCss: 'minmax(0, 1.4fr) minmax(72px, 0.5fr) minmax(0, 1fr) minmax(72px, 0.45fr)',
  cellRoles: [
    FlapCellRole.name,
    FlapCellRole.type,
    FlapCellRole.tags,
    FlapCellRole.status,
  ],
  // Short headers fit default library rail (BUG-20260726-009).
  headerLabels: ['Name', 'Type', 'Tags', 'Stat'],
);

/// Synergy library: NAME · DESIGNATION · EVIDENCE · STATUS
const FlapColumnTemplate kFlapColumnsSynergy = FlapColumnTemplate(
  id: 'synergy',
  columnsCss: 'minmax(0, 1.3fr) minmax(96px, 0.55fr) minmax(0, 1fr) minmax(72px, 0.45fr)',
  cellRoles: [
    FlapCellRole.name,
    FlapCellRole.identity,
    FlapCellRole.synergy,
    FlapCellRole.status,
  ],
  headerLabels: ['Name', 'Design', 'Links', 'Stat'],
);

/// Build library: NAME · CLASS · EXOTIC · SYN · STAT
///
/// Flex weights tuned for ~320px library rail (no EXOTIC|SYN header merge).
const FlapColumnTemplate kFlapColumnsBuilds = FlapColumnTemplate(
  id: 'builds',
  columnsCss:
      'minmax(0, 1.5fr) minmax(0, 0.55fr) minmax(0, 0.45fr) minmax(0, 0.75fr) minmax(0, 0.35fr)',
  cellRoles: [
    FlapCellRole.name,
    FlapCellRole.identity,
    FlapCellRole.exotics,
    FlapCellRole.synergy,
    FlapCellRole.status,
  ],
  // Ultra-short labels for dense rail (BUG-20260726-009 residual).
  headerLabels: ['Name', 'Cls', 'Exo', 'Syn', 'Ok'],
);

/// All first-class library templates (Sets / Synergy / Builds).
const List<FlapColumnTemplate> kFlapLibraryColumnTemplates = [
  kFlapColumnsSets,
  kFlapColumnsSynergy,
  kFlapColumnsBuilds,
];

/// Lookup by [FlapColumnTemplate.id]; throws if unknown.
FlapColumnTemplate flapColumnTemplateById(String id) {
  for (final t in kFlapLibraryColumnTemplates) {
    if (t.id == id) return t;
  }
  throw ArgumentError.value(id, 'id', 'Unknown FlapBoard column template');
}

/// Layout contract bag for hosts.
class FlapBoardLayout {
  const FlapBoardLayout._();

  static const double libraryRailWidth = kFlapLibraryRailWidth;
  static const double rowGap = kFlapBoardRowGap;
  static const double ruleThickness = kFlapRuleThickness;
  static const double pageFrameMaxWidth = kPageFrameMaxWidth;
  static const double sealSize = kFlapSealSize;
  static const double channelWashAlpha = kFlapChannelWashAlpha;
  static const double badgeWashAlpha = kFlapBadgeWashAlpha;

  static const FlapColumnTemplate sets = kFlapColumnsSets;
  static const FlapColumnTemplate synergy = kFlapColumnsSynergy;
  static const FlapColumnTemplate builds = kFlapColumnsBuilds;
}
