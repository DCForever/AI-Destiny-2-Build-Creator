/// Pure armor set-bonus catalog row for soft coverage matching.
///
/// Mirrors the evaluator-facing fields of TS `SetBonusRecord` (no icon/searchName required).
class SetBonusRecord {
  const SetBonusRecord({
    required this.hash,
    required this.name,
    this.perks = const [],
  });

  final int hash;
  final String name;
  final List<SetBonusPerk> perks;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetBonusRecord) return false;
    if (other.hash != hash || other.name != name) return false;
    if (other.perks.length != perks.length) return false;
    for (var i = 0; i < perks.length; i++) {
      if (other.perks[i] != perks[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(hash, name, Object.hashAll(perks));
}

/// One set-bonus threshold (e.g. 2pc / 4pc).
class SetBonusPerk {
  const SetBonusPerk({
    required this.requiredCount,
    required this.name,
  });

  final int requiredCount;
  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetBonusPerk &&
        other.requiredCount == requiredCount &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(requiredCount, name);
}
