/// Session status for Jaspr web Drift / OPFS bootstrap (DART-043).
library;

/// Product role for this browser tab.
enum WebDbRole {
  /// Exclusive writer — may open Drift and mutate.
  writer,

  /// Another tab holds the writer; this tab does not open a write session.
  blocked,
}

/// High-level lifecycle for Settings UX.
enum WebDbPhase {
  loading,
  ready,
  error,
}

/// Immutable snapshot shown on Settings and used by bootstrap.
class WebDbSessionStatus {
  const WebDbSessionStatus({
    required this.phase,
    required this.role,
    this.storageImplementation,
    this.missingFeatures = const [],
    this.errorMessage,
    this.tabId,
  });

  final WebDbPhase phase;
  final WebDbRole role;

  /// Drift `chosenImplementation` name when known (e.g. `opfsLocks`).
  final String? storageImplementation;

  /// Feature names Drift reported as missing (optional UX detail).
  final List<String> missingFeatures;

  final String? errorMessage;
  final String? tabId;

  bool get isWriter => role == WebDbRole.writer;
  bool get isBlocked => role == WebDbRole.blocked;
  bool get isReady => phase == WebDbPhase.ready;
  bool get hasError => phase == WebDbPhase.error;

  /// Stable Settings panel lines (tests assert on these).
  String get roleLabel {
    switch (role) {
      case WebDbRole.writer:
        return 'Role: writer';
      case WebDbRole.blocked:
        return 'Role: blocked';
    }
  }

  String get summaryLine {
    if (phase == WebDbPhase.loading) {
      return 'Database: opening…';
    }
    if (phase == WebDbPhase.error) {
      return 'Database: error — ${errorMessage ?? 'unknown'}';
    }
    if (role == WebDbRole.blocked) {
      return 'Database: blocked — another tab holds the writer lock. '
          'Close other tabs of this app to write here.';
    }
    final storage = storageImplementation ?? 'unknown';
    return 'Database: ready (writer) · storage: $storage';
  }

  WebDbSessionStatus copyWith({
    WebDbPhase? phase,
    WebDbRole? role,
    String? storageImplementation,
    List<String>? missingFeatures,
    String? errorMessage,
    String? tabId,
  }) {
    return WebDbSessionStatus(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      storageImplementation:
          storageImplementation ?? this.storageImplementation,
      missingFeatures: missingFeatures ?? this.missingFeatures,
      errorMessage: errorMessage ?? this.errorMessage,
      tabId: tabId ?? this.tabId,
    );
  }

  static const loadingWriter = WebDbSessionStatus(
    phase: WebDbPhase.loading,
    role: WebDbRole.writer,
  );
}
