import 'dart:async';
import 'dart:io';

/// Result of an OAuth redirect to the loopback listener.
class LoopbackCallbackResult {
  const LoopbackCallbackResult({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasCode => code != null && code!.isNotEmpty;
}

/// HTTP loopback callback server bound to **127.0.0.1 only** (DART-023).
///
/// Listens for a single OAuth redirect, serves a minimal HTML success/error
/// page, then completes [waitForCallback].
class LoopbackCallbackServer {
  LoopbackCallbackServer();

  HttpServer? _server;
  Completer<LoopbackCallbackResult>? _completer;

  /// Whether the server is currently listening.
  bool get isRunning => _server != null;

  /// Bound port after [start], or null.
  int? get port => _server?.port;

  /// Starts listening on [host]:[port] for [callbackPath] (e.g. `/callback`).
  Future<void> start({
    String host = '127.0.0.1',
    required int port,
    String callbackPath = '/callback',
  }) async {
    if (_server != null) {
      throw StateError('LoopbackCallbackServer is already running');
    }
    if (host != '127.0.0.1' && host != 'localhost') {
      throw ArgumentError.value(
        host,
        'host',
        'OAuth loopback must bind only to 127.0.0.1/localhost',
      );
    }

    final path = callbackPath.startsWith('/') ? callbackPath : '/$callbackPath';
    _completer = Completer<LoopbackCallbackResult>();
    final server = await HttpServer.bind(host, port);
    _server = server;

    server.listen((request) async {
      try {
        final uri = request.uri;
        if (uri.path != path) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Not found');
          await request.response.close();
          return;
        }

        final result = LoopbackCallbackResult(
          code: uri.queryParameters['code'],
          state: uri.queryParameters['state'],
          error: uri.queryParameters['error'],
          errorDescription: uri.queryParameters['error_description'],
        );

        request.response.headers.contentType = ContentType.html;
        request.response.statusCode = HttpStatus.ok;
        if (result.hasError) {
          request.response.write(
            '<!DOCTYPE html><html><body><h1>Sign-in failed</h1>'
            '<p>You can close this window and return to the app.</p></body></html>',
          );
        } else {
          request.response.write(
            '<!DOCTYPE html><html><body><h1>Signed in</h1>'
            '<p>You can close this window and return to Destiny 2 Build Creator.</p></body></html>',
          );
        }
        await request.response.close();

        final completer = _completer;
        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e, st) {
        final completer = _completer;
        if (completer != null && !completer.isCompleted) {
          completer.completeError(e, st);
        }
      }
    });
  }

  /// Waits for the first matching callback or fails on [timeout].
  Future<LoopbackCallbackResult> waitForCallback({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = _completer;
    if (completer == null) {
      throw StateError('LoopbackCallbackServer has not been started');
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'OAuth loopback callback timed out',
        timeout,
      ),
    );
  }

  /// Stops the server. Idempotent.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('LoopbackCallbackServer stopped before callback'),
      );
    }
  }
}

/// Parses host/port/path from a registered redirect URI for loopback bind.
({String host, int port, String path}) parseLoopbackRedirectUri(String redirectUri) {
  final uri = Uri.parse(redirectUri);
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw FormatException('Loopback redirect_uri must be http(s): $redirectUri');
  }
  final host = uri.host;
  if (host != '127.0.0.1' && host != 'localhost') {
    throw FormatException(
      'Loopback redirect_uri host must be 127.0.0.1 or localhost: $redirectUri',
    );
  }
  final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  final path = uri.path.isEmpty ? '/' : uri.path;
  return (host: host == 'localhost' ? '127.0.0.1' : host, port: port, path: path);
}
