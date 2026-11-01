import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/foundation.dart';

/// Read-only Warlock matrix list. Loads a local file and never writes it.
///
/// [ensureHttp] is the only network client this screen may use. File load
/// does not call it.
class WarlockBuildsController extends ChangeNotifier {
  WarlockBuildsController({
    GetOnlyHttpClient? http,
    String? initialPath,
  })  : _injected = http,
        path = initialPath?.trim() ?? '';

  final GetOnlyHttpClient? _injected;
  GetOnlyHttpClient? _owned;

  String path;
  String? selectedExotic;
  List<WarlockMatrixBuild> builds = const [];
  String? error;
  bool loading = false;

  bool get _ownsHttp => _injected == null;

  List<String> get exoticNames => exoticNamesIn(builds);

  List<WarlockMatrixBuild> get visibleBuilds =>
      filterWarlockBuildsByExotic(builds, selectedExotic);

  /// GET-only client. Creates one around [HttpClient] when none was injected.
  GetOnlyHttpClient ensureHttp() {
    final injected = _injected;
    if (injected != null) return injected;
    return _owned ??= GetOnlyHttpClient(HttpClient());
  }

  /// Replaces the in-memory rows. Does not touch the source file or the network.
  void adoptBuilds(List<WarlockMatrixBuild> next) {
    builds = List<WarlockMatrixBuild>.unmodifiable(next);
    error = null;
    _keepExoticSelection();
    notifyListeners();
  }

  void selectExotic(String? exoticName) {
    final trimmed = exoticName?.trim() ?? '';
    selectedExotic = trimmed.isEmpty ? null : trimmed;
    notifyListeners();
  }

  Future<void> load() async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      _fail('Enter a matrix file path.');
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _read(trimmed);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _read(String trimmed) async {
    try {
      final bytes = await readOnlyFileBytes(trimmed);
      final decoded = jsonDecode(utf8.decode(bytes));
      adoptBuilds(parseWarlockMatrix(decoded));
    } on ReadOnlyFileException catch (error) {
      _clear(error.message);
    } on FormatException catch (error) {
      _clear('Matrix file is not valid JSON (${error.message}).');
    }
  }

  void _keepExoticSelection() {
    final selected = selectedExotic;
    if (selected == null) return;
    if (!exoticNames.contains(selected)) selectedExotic = null;
  }

  void _fail(String message) {
    _clear(message);
    loading = false;
    notifyListeners();
  }

  void _clear(String message) {
    builds = const [];
    error = message;
  }

  @override
  void dispose() {
    if (_ownsHttp) _owned?.close(force: true);
    super.dispose();
  }
}
