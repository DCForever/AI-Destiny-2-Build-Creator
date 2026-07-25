import 'dart:async';
import 'dart:io';

import 'loopback_tls.dart';

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

/// Parsed loopback redirect for bind + path matching.
class LoopbackBindConfig {
  const LoopbackBindConfig({
    required this.host,
    required this.port,
    required this.path,
    required this.useTls,
  });

  final String host;
  final int port;
  final String path;
  final bool useTls;
}

/// HTTP(S) loopback callback server bound to **127.0.0.1 only** (DART-023).
///
/// Listens for a single OAuth redirect, serves a minimal HTML success/error
/// page, then completes [waitForCallback].
///
/// When [useTls] is true (redirect_uri scheme `https`), binds with a local
/// self-signed cert from [resolveLoopbackTlsMaterial].
class LoopbackCallbackServer {
  LoopbackCallbackServer({this.tlsMaterial});

  /// Optional override for tests; production resolves certs automatically.
  final LoopbackTlsMaterial? tlsMaterial;

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
    bool useTls = false,
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

    final HttpServer server;
    if (useTls) {
      final material = tlsMaterial ?? resolveLoopbackTlsMaterial();
      if (material == null) {
        throw StateError(
          'HTTPS loopback requires certs/loopback-cert.pem and '
          'certs/loopback-key.pem under the windows_host package '
          '(self-signed for 127.0.0.1).',
        );
      }
      server = await HttpServer.bindSecure(
        host,
        port,
        material.toSecurityContext(),
      );
      // ignore: avoid_print
      print('OAuth loopback HTTPS listening on https://$host:$port$path');
    } else {
      server = await HttpServer.bind(host, port);
      // ignore: avoid_print
      print('OAuth loopback HTTP listening on http://$host:$port$path');
    }
    _server = server;

    server.listen((request) async {
      try {
        final uri = request.uri;
        // Normalize trailing slash so registered vs actual path still match.
        final requestPath = uri.path.endsWith('/') && uri.path.length > 1
            ? uri.path.substring(0, uri.path.length - 1)
            : uri.path;
        final expectedPath = path.endsWith('/') && path.length > 1
            ? path.substring(0, path.length - 1)
            : path;
        // ignore: avoid_print
        print('OAuth loopback request: ${uri.path}?${uri.query}');

        if (requestPath != expectedPath) {
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
            '<p>You can close this window and return to Destiny 2 Build Creator.</p>'
            '<p>If the browser warned about the certificate, that is expected '
            'for the local self-signed HTTPS loopback.</p></body></html>',
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

/// Parses host/port/path/TLS from a registered redirect URI for loopback bind.
LoopbackBindConfig parseLoopbackRedirectUri(String redirectUri) {
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
  return LoopbackBindConfig(
    host: host == 'localhost' ? '127.0.0.1' : host,
    port: port,
    path: path,
    useTls: uri.scheme == 'https',
  );
}
