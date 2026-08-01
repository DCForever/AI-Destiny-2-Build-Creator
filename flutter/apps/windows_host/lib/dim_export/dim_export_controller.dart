import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Injectable clipboard writer (tests capture text without OS clipboard).
typedef DimClipboardWriter = Future<void> Function(String text);

Future<void> defaultDimClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Host adapter: [DimExportSession] + Flutter [ChangeNotifier] (DART-039).
class DimExportController extends ChangeNotifier {
  DimExportController({
    required AppDatabase db,
    DimClipboardWriter? clipboardWriter,
    String Function()? loadoutIdFactory,
  }) : core = DimExportSession(
          db: db,
          clipboardWriter: clipboardWriter ?? defaultDimClipboardWriter,
          loadoutIdFactory: loadoutIdFactory,
        ) {
    core.addListener(notifyListeners);
  }

  final DimExportSession core;

  EquipReadyResult? get readiness => core.readiness;
  bool get equipReady => core.equipReady;
  List<PinStatus> get pinStatuses => core.pinStatuses;
  bool get loadingReadiness => core.loadingReadiness;
  bool get exporting => core.exporting;
  String? get error => core.error;
  String? get statusMessage => core.statusMessage;
  String? get lastJson => core.lastJson;
  int get clipboardWrites => core.clipboardWrites;
  bool get hasVariant => core.hasVariant;
  String get readinessSummary => core.readinessSummary;
  bool get canExport => core.canExport;

  Future<void> bind({
    required int userId,
    required String buildId,
    required String variantId,
  }) =>
      core.bind(userId: userId, buildId: buildId, variantId: variantId);

  void clearBinding() => core.clearBinding();
  Future<void> refreshReadiness() => core.refreshReadiness();
  Future<String?> requestExport() => core.requestExport();

  @override
  void dispose() {
    core.removeListener(notifyListeners);
    super.dispose();
  }
}
