/// A hard-blocking constraint failure (never auto-applied away).
class HardBlock {
  const HardBlock({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HardBlock && other.code == code && other.message == message;
  }

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'HardBlock($code: $message)';
}

/// Soft warning from constraint evaluation (guidance only; never hard-blocks alone).
class SoftWarning {
  const SoftWarning({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoftWarning &&
        other.code == code &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'SoftWarning($code: $message)';
}

/// Combined constraint evaluation envelope (TS `ConstraintEvaluation`).
class ConstraintEvaluation {
  const ConstraintEvaluation({
    this.hardBlocks = const [],
    this.softWarnings = const [],
  });

  final List<HardBlock> hardBlocks;
  final List<SoftWarning> softWarnings;

  bool get isHardBlocked => hardBlocks.isNotEmpty;

  static const empty = ConstraintEvaluation();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConstraintEvaluation) return false;
    if (other.hardBlocks.length != hardBlocks.length) return false;
    if (other.softWarnings.length != softWarnings.length) return false;
    for (var i = 0; i < hardBlocks.length; i++) {
      if (other.hardBlocks[i] != hardBlocks[i]) return false;
    }
    for (var i = 0; i < softWarnings.length; i++) {
      if (other.softWarnings[i] != softWarnings[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(hardBlocks), Object.hashAll(softWarnings));
}
