import 'dart:convert';

import 'bungie_errors.dart';

/// Parsed Bungie Platform JSON envelope.
class BungieEnvelope {
  const BungieEnvelope({
    required this.errorCode,
    this.message,
    this.errorStatus,
    this.throttleSeconds = 0,
    this.response,
  });

  /// Bungie Success == 1.
  final int errorCode;
  final String? message;
  final String? errorStatus;
  final int throttleSeconds;

  /// Unwrapped `Response` field (often a [Map], list, number, or null).
  final Object? response;

  bool get isSuccess => errorCode == kBungieSuccessErrorCode;
}

/// Bungie Platform success code.
const int kBungieSuccessErrorCode = 1;

/// Parse a JSON string into [BungieEnvelope].
///
/// Throws [BungieParseException] when the body is not a JSON object envelope.
BungieEnvelope parseBungieEnvelope(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (e) {
    throw BungieParseException(
      'Bungie response is not valid JSON: ${e.message}',
      bodySnippet: _snippet(body),
    );
  }

  if (decoded is! Map) {
    throw BungieParseException(
      'Bungie response is not a JSON object',
      bodySnippet: _snippet(body),
    );
  }

  final map = Map<String, dynamic>.from(decoded);
  final rawCode = map['ErrorCode'];
  if (rawCode is! int) {
    throw BungieParseException(
      'Bungie envelope missing integer ErrorCode',
      bodySnippet: _snippet(body),
    );
  }

  final throttle = map['ThrottleSeconds'];
  final throttleSeconds = throttle is int
      ? throttle
      : throttle is num
          ? throttle.toInt()
          : 0;

  final message = map['Message'];
  final errorStatus = map['ErrorStatus'];

  return BungieEnvelope(
    errorCode: rawCode,
    message: message is String ? message : null,
    errorStatus: errorStatus is String ? errorStatus : null,
    throttleSeconds: throttleSeconds,
    response: map['Response'],
  );
}

String _snippet(String body, [int max = 200]) {
  if (body.length <= max) return body;
  return '${body.substring(0, max)}…';
}
