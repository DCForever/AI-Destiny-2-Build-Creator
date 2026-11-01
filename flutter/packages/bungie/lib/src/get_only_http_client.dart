import 'dart:io';

/// Thrown when a caller asks [GetOnlyHttpClient] for a method other than GET.
class GetOnlyHttpException implements Exception {
  GetOnlyHttpException(this.method);

  final String method;

  @override
  String toString() => 'Refused HTTP $method; only GET is allowed.';
}

/// Wraps the app's [HttpClient] and refuses every method except GET.
///
/// [inner] is the same `dart:io` [HttpClient] the Bungie transport opens.
/// Non-GET calls throw before [inner] is asked to open a request.
class GetOnlyHttpClient {
  GetOnlyHttpClient(this.inner);

  final HttpClient inner;

  /// Opens a GET request. Any other [method] throws [GetOnlyHttpException].
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (method.toUpperCase() != 'GET') {
      throw GetOnlyHttpException(method);
    }
    return inner.openUrl('GET', url);
  }

  /// GET [url] through [inner].
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  /// Closes the wrapped client.
  void close({bool force = false}) => inner.close(force: force);
}
