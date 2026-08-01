/// Injectable browser navigation / location helpers (DART-045).
///
/// Production assigns `window.location`; tests record URLs without leaving VM.
library;

/// Reads and navigates the browser location for OAuth redirects.
abstract class WebAuthNavigator {
  /// Current page URI (path + query), used on callback.
  Uri get currentUri;

  /// Full page navigation (authorize URL or post-callback Settings).
  void assign(String url);

  /// Origin for default redirect URI (e.g. `https://app.example`).
  String get origin;
}

/// In-memory navigator for unit tests.
class MemoryWebAuthNavigator implements WebAuthNavigator {
  MemoryWebAuthNavigator({
    Uri? currentUri,
    this.origin = 'https://127.0.0.1:8080',
  }) : _currentUri = currentUri ?? Uri.parse('https://127.0.0.1:8080/settings');

  Uri _currentUri;
  final List<String> assigned = [];

  @override
  Uri get currentUri => _currentUri;

  set currentUri(Uri value) => _currentUri = value;

  @override
  final String origin;

  @override
  void assign(String url) {
    assigned.add(url);
    _currentUri = Uri.parse(url);
  }
}
