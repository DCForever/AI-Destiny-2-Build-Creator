import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'types/services.dart';

/// Default [ManifestHttpGet] using [HttpClient] with UTF-8 body decode.
ManifestHttpGet createUtf8ManifestHttpGet({Object? client}) {
  final http = client is HttpClient ? client : HttpClient();
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
