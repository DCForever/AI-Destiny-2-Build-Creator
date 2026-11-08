/// Creator + title (+ exotic when the title alone is ambiguous).
class PilotIdentity {
  const PilotIdentity({
    required this.caseId,
    required this.creator,
    required this.buildName,
    this.requiredExotic,
  });

  final String caseId;
  final String creator;
  final String buildName;
  final String? requiredExotic;
}

/// The five contrasting records. Titles are labels, not gameplay loops.
const List<PilotIdentity> pilotIdentities = <PilotIdentity>[
  PilotIdentity(
    caseId: 'kahoona-hexbugs',
    creator: 'KahoonaBahoona',
    buildName: "Kahoona's HexBugs N Supers!",
  ),
  PilotIdentity(
    caseId: 'debs-ignition',
    creator: 'Debs Vault',
    buildName: 'My favourite Warlock  Ignition Build by debs',
  ),
  PilotIdentity(
    caseId: 'tipsy-gambit',
    creator: 'Tipsy',
    buildName: 'Gambit',
  ),
  PilotIdentity(
    caseId: 'zirak-witness',
    creator: 'zirak',
    buildName: 'Witness dps',
  ),
  PilotIdentity(
    caseId: 'suutekk-solar',
    creator: 'Suutekk',
    buildName: 'Solar',
    requiredExotic: 'Solipsism',
  ),
];

String? pilotCaseId({
  required String creator,
  required String buildName,
  required String filingExotic,
}) {
  for (final identity in pilotIdentities) {
    if (creator != identity.creator || buildName != identity.buildName) {
      continue;
    }
    final requiredExotic = identity.requiredExotic;
    if (requiredExotic != null && filingExotic != requiredExotic) continue;
    return identity.caseId;
  }
  return null;
}
