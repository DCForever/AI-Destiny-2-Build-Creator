import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'types/services.dart';

/// Default [ManifestHttpGet] using [HttpClient] with UTF-8 body decode.
///
/// Hosts may inject a mock for tests. Prefer reusing a single [HttpClient]
/// across calls when constructing for a long-lived host process.
ManifestHttpGet createUtf8ManifestHttpGet({HttpClient? client}) {
  final http = client ?? HttpClient();
  return (Uri uri, {Map<String, String>? headers}) async {
    final request = await http.getUrl(uri);
    if (headers != null) {
      headers.forEach(request.headers.set);
    }
    final response = await request.close();
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = Uint8List.fromList(builder.takeBytes());
    return ManifestHttpResponse(
      statusCode: response.statusCode,
      body: utf8.decode(bytes),
    );
  };
}

/// Alias kept for readability at call sites.
ManifestHttpGet createDefaultManifestHttpGet({HttpClient? client}) =>
    createUtf8ManifestHttpGet(client: client);
