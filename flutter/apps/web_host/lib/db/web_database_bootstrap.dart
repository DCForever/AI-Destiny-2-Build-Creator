/// Bootstrap: tab lock → open Drift only for writer (DART-043).
library;

import 'dart:async';

import 'package:destiny2_db/destiny2_db.dart';

import 'tab_lock_backend.dart';
import 'tab_writer_lock.dart';
import 'web_database_opener.dart';
import 'web_db_status.dart';

/// Owns lock + optional [AppDatabase] for the Jaspr web host.
class WebDatabaseBootstrap {
  WebDatabaseBootstrap({
    required TabLockBackend lockBackend,
    required WebDatabaseOpener opener,
    String? tabId,
  })  : _opener = opener,
        _coordinator = TabWriterCoordinator(
          backend: lockBackend,
          tabId: tabId ?? generateTabId(),
        );

  final WebDatabaseOpener _opener;
  final TabWriterCoordinator _coordinator;

  final _statusController = StreamController<WebDbSessionStatus>.broadcast();

  WebDbSessionStatus _status = WebDbSessionStatus.loadingWriter;
  AppDatabase? _database;
  Future<WebDbSessionStatus>? _startFuture;

  Stream<WebDbSessionStatus> get statusStream => _statusController.stream;
  WebDbSessionStatus get status => _status;
  AppDatabase? get database => _database;
  String get tabId => _coordinator.tabId;

  void _emit(WebDbSessionStatus next) {
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  /// Acquire writer lock; open DB only if writer.
  ///
  /// Safe to call multiple times — concurrent callers share one future.
  Future<WebDbSessionStatus> start() {
    return _startFuture ??= _startOnce();
  }

  Future<WebDbSessionStatus> _startOnce() async {
    _emit(
      WebDbSessionStatus(
        phase: WebDbPhase.loading,
        role: WebDbRole.writer,
        tabId: tabId,
      ),
    );

    try {
      final role = await _coordinator.acquire();

      if (role == WebDbRole.blocked) {
        _emit(
          WebDbSessionStatus(
            phase: WebDbPhase.ready,
            role: WebDbRole.blocked,
            tabId: tabId,
          ),
        );
        return _status;
      }

      final opened = await _opener.open();
      _database = opened.database;

      // Touch schema so migrations / ensure* run.
      await _database!.listUserTableNames();

      _emit(
        WebDbSessionStatus(
          phase: WebDbPhase.ready,
          role: WebDbRole.writer,
          storageImplementation: opened.storageImplementation,
          missingFeatures: opened.missingFeatures,
          tabId: tabId,
        ),
      );
      return _status;
    } catch (e) {
      _emit(
        WebDbSessionStatus(
          phase: WebDbPhase.error,
          role: _coordinator.role ?? WebDbRole.writer,
          errorMessage: e.toString(),
          tabId: tabId,
        ),
      );
      return _status;
    }
  }

  /// Release lock and close DB if open.
  Future<void> dispose() async {
    await _coordinator.release();
    await _database?.close();
    _database = null;
    await _statusController.close();
  }
}
