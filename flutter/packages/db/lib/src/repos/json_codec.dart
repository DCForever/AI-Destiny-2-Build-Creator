import 'dart:convert';

/// Parse a JSON array of numbers; invalid/missing → empty list.
List<int> parseIntJsonArray(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return const [];
    return parsed.whereType<num>().map((n) => n.toInt()).toList();
  } catch (_) {
    return const [];
  }
}

String encodeIntJsonArray(List<int> values) => jsonEncode(values);

/// Soft stat targets: product stores a JSON object string (default `{}`).
Map<String, Object?> parseSoftStatTargetsJson(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final parsed = jsonDecode(raw);
    if (parsed is Map) {
      return parsed.map((k, v) => MapEntry(k.toString(), v as Object?));
    }
    return const {};
  } catch (_) {
    return const {};
  }
}

String encodeSoftStatTargetsJson(Map<String, Object?>? targets) {
  if (targets == null || targets.isEmpty) return '{}';
  return jsonEncode(targets);
}

/// Snapshot configs JSON list (attachment mode snapshot).
List<Map<String, Object?>>? parseSnapshotConfigsJson(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return null;
    return parsed
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v as Object?)))
        .toList();
  } catch (_) {
    return null;
  }
}

String? encodeSnapshotConfigsJson(List<Map<String, Object?>>? configs) {
  if (configs == null) return null;
  return jsonEncode(configs);
}

/// Parse a JSON array of strings; invalid/missing → empty list.
List<String> parseStringJsonArray(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return const [];
    return parsed.map((e) => e.toString()).toList();
  } catch (_) {
    return const [];
  }
}

String encodeStringJsonArray(List<String> values) => jsonEncode(values);

/// Parse a JSON object map; invalid/missing → null.
Map<String, Object?>? parseJsonObjectMap(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final parsed = jsonDecode(raw);
    if (parsed is Map) {
      return parsed.map((k, v) => MapEntry(k.toString(), v as Object?));
    }
    return null;
  } catch (_) {
    return null;
  }
}

String? encodeJsonObjectMap(Map<String, Object?>? values) {
  if (values == null) return null;
  return jsonEncode(values);
}

/// Parse a JSON array of objects (e.g. socket_plugs); invalid/missing → null.
List<Map<String, Object?>>? parseJsonObjectList(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return null;
    return parsed
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v as Object?)))
        .toList();
  } catch (_) {
    return null;
  }
}

String? encodeJsonObjectList(List<Map<String, Object?>>? values) {
  if (values == null) return null;
  return jsonEncode(values);
}

/// Subclass / free-form JSON column: keep as string; normalize object→string.
String encodeJsonValue(Object? value) {
  if (value == null) return '{}';
  if (value is String) {
    // Already a JSON string — validate lightly; store as-is if parseable.
    try {
      jsonDecode(value);
      return value;
    } catch (_) {
      return jsonEncode(value);
    }
  }
  return jsonEncode(value);
}

Object? decodeJsonValue(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return raw;
  }
}
