/// Exact text taken from a source field, including blanks.
class PilotText {
  const PilotText(this.value) : present = true;

  const PilotText.absent()
      : present = false,
        value = '';

  /// False when the source omitted the field.
  final bool present;

  /// Raw source text. Empty when [present] is false or the field is blank.
  final String value;

  bool get isBlank => value.trim().isEmpty;

  @override
  bool operator ==(Object other) {
    return other is PilotText &&
        other.present == present &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(present, value);
}

const String pilotUnknownPerkToken = 'perk not specified';

const String pilotProposalSuffix = ' (proposal)';

const String pilotSyntheticBanner =
    'SYNTHETIC DEMO — NOT AN ACCOUNT-VERIFIED PERSONAL LOADOUT — '
    'NOT REAL DIM ACCEPTANCE';

const Set<String> pilotSubclassKeys = <String>{
  'arc',
  'solar',
  'void',
  'stasis',
  'strand',
  'prismatic',
};

bool pilotSameText(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

bool pilotIsSubclass(String value) {
  return pilotSubclassKeys.contains(value.trim().toLowerCase());
}

bool pilotIsUnknownPerk(String value) {
  return pilotSameText(value, pilotUnknownPerkToken);
}

/// Column text and a notes Set line that only adds " (proposal)".
bool pilotNotesRestateSet(String column, String notesSet) {
  final left = column.trim();
  final right = notesSet.trim();
  if (left.isEmpty && right.isEmpty) return true;
  if (right == left) return true;
  return right == '$left$pilotProposalSuffix';
}
