import 'dart:async';

/// Coalesces scroll-spy probes so group `RenderBox` walks are not every frame.
///
/// GAP-PERF-02: leading emit, then at most one trailing emit after [interval];
/// [flush] forces an immediate probe (use on [ScrollEndNotification]).
class CatalogScrollSpyThrottle {
  CatalogScrollSpyThrottle({
    this.interval = const Duration(milliseconds: 80),
    required this.onProbe,
  });

  /// Quiet window after a leading probe before a trailing re-probe is allowed.
  final Duration interval;

  /// Invoked to walk anchors and notify the host (may no-op if key unchanged).
  final void Function() onProbe;

  Timer? _timer;
  bool _trailingPending = false;

  /// Schedule a probe for scroll motion (updates).
  void onScrollUpdate() {
    if (_timer?.isActive ?? false) {
      _trailingPending = true;
      return;
    }
    onProbe();
    _timer = Timer(interval, _onWindowElapsed);
  }

  /// Force probe now (scroll end / dispose flush).
  void flush() {
    _timer?.cancel();
    _timer = null;
    _trailingPending = false;
    onProbe();
  }

  void _onWindowElapsed() {
    _timer = null;
    if (_trailingPending) {
      _trailingPending = false;
      onProbe();
      // Open a new quiet window after trailing so a burst still coalesces.
      _timer = Timer(interval, _onWindowElapsed);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _trailingPending = false;
  }
}
