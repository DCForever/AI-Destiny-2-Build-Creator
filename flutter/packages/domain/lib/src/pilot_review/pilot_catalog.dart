/// A labeled synthetic exotic. Not an owned item.
class PilotSyntheticExotic {
  const PilotSyntheticExotic({
    required this.id,
    required this.exoticName,
    required this.perks,
  });

  final String id;
  final String exoticName;
  final List<String> perks;
}

/// Fixed catalog used to prove name-only matching is not enough.
const List<PilotSyntheticExotic> pilotSyntheticExotics = <PilotSyntheticExotic>[
  PilotSyntheticExotic(
    id: 'synthetic-solipsism-spirit-pair',
    exoticName: 'Solipsism',
    perks: <String>['Spirit of Apotheosis', 'Spirit of Harmony'],
  ),
  PilotSyntheticExotic(
    id: 'synthetic-solipsism-short-pair',
    exoticName: 'Solipsism',
    perks: <String>['Apotheosis', 'Harmony'],
  ),
  PilotSyntheticExotic(
    id: 'synthetic-solipsism-name-only',
    exoticName: 'Solipsism',
    perks: <String>[],
  ),
  PilotSyntheticExotic(
    id: 'synthetic-solipsism-other-pair',
    exoticName: 'Solipsism',
    perks: <String>['Spirit of Apotheosis', 'Spirit of Star-Eater'],
  ),
  PilotSyntheticExotic(
    id: 'synthetic-ergo-trait-frame-only',
    exoticName: 'Ergo Sum',
    perks: <String>['Perfect Fifth', 'Caster Frame'],
  ),
  PilotSyntheticExotic(
    id: 'synthetic-ergo-name-only',
    exoticName: 'Ergo Sum',
    perks: <String>[],
  ),
];
