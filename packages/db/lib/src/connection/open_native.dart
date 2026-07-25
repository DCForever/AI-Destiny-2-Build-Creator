import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// In-memory NativeDatabase executor (VM / Flutter desktop / mobile).
QueryExecutor openMemoryExecutor() => NativeDatabase.memory();

/// File-backed NativeDatabase executor; creates parent directories if needed.
QueryExecutor openFileExecutor(String path) {
  final file = File(path);
  final dir = file.parent;
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return NativeDatabase(file);
}
