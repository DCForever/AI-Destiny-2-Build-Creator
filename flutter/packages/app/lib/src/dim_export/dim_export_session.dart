/// Shared DIM jsonOnly export orchestration (Windows + web).
library;

import 'package:destiny2_db/destiny2_db.dart' hide Build;
import 'package:destiny2_domain/destiny2_domain.dart';

import '../mappers.dart';
import '../presentation/dim_export_format.dart';
import '../variant_use_cases.dart';

typedef DimClipboardWriter = Future<void> Function(String text);

/// Shared equip-ready-gated DIM clipboard export (DART-039/047).
class DimExportSession {
  DimExportSession({
    required this.db,
    required this.clipboardWriter,
    this.loadoutIdFactory,
  });

  final AppDatabase db;
  final DimClipboardWriter clipboardWriter;
  final String Function()? loadoutIdFactory;

  final List<void Function()> _listeners = <void Function()>[];
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void notifyListeners() {
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  String? _buildId;
  String? _variantId;
  int? _userId;

  EquipReadyResult? _readiness;
  ResolvedVariantEquipment? _resolved;
  String? _buildName;
  String? _variantName;
  GuardianClass _className = GuardianClass.hunter;
  SoftStatTargets _softStatTargets = const SoftStatTargets();

  bool _loadingReadiness = false;
  bool _exporting = false;
  String? _error;
  String? _statusMessage;
  String? _lastJson;
  int _clipboardWrites = 0;

  EquipReadyResult? get readiness => _readiness;
  bool get equipReady => _readiness?.equipReady ?? false;
  List<PinStatus> get pinStatuses =>
      List.unmodifiable(_readiness?.pinStatuses ?? const []);
  bool get loadingReadiness => _loadingReadiness;
  bool get exporting => _exporting;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  String? get lastJson => _lastJson;
  int get clipboardWrites => _clipboardWrites;
  bool get hasVariant =>
      _userId != null && _buildId != null && _variantId != null;

  String get readinessSummary => _readiness == null
      ? 'Select a variant to check DIM export readiness'
      : formatDimExportReadySummary(_readiness!);

  bool get canExport => canEnableDimExportCta(
        equipReady: equipReady,
        exporting: _exporting,
        loading: _loadingReadiness,
        hasVariant: hasVariant,
      );

  String get softAdvisory => kDimExportSoftAdvisoryCaption;

  String? get jsonPreview =>
      _lastJson == null ? null : truncateDimExportPreview(_lastJson!);

  Future<void> bind({
    required int userId,
    required String buildId,
    required String variantId,
  }) async {
    _userId = userId;
    _buildId = buildId;
    _variantId = variantId;
    _lastJson = null;
    _error = null;
    _statusMessage = null;
    await refreshReadiness();
  }

  void clearBinding() {
    _userId = null;
    _buildId = null;
    _variantId = null;
    _resolved = null;
    _readiness = null;
    _buildName = null;
    _variantName = null;
    _className = GuardianClass.hunter;
    _softStatTargets = const SoftStatTargets();
    _lastJson = null;
    _error = null;
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> refreshReadiness() async {
    final userId = _userId;
    final buildId = _buildId;
    final variantId = _variantId;
    if (userId == null || buildId == null || variantId == null) {
      _readiness = null;
      _resolved = null;
      notifyListeners();
      return;
    }
    _loadingReadiness = true;
    notifyListeners();
    try {
      final build = await getBuild(db, userId, buildId);
      final variant = await getVariant(db, buildId, variantId);
      final resolved = await resolveUserVariant(db, userId, buildId, variantId);
      _resolved = resolved;
      _buildName = build?.name ?? 'Build';
      _variantName = variant?.name;
      _className =
          GuardianClass.tryParse(build?.className ?? '') ?? GuardianClass.hunter;
      _softStatTargets = softStatTargetsFromJson(build?.softStatTargets ?? {});

      if (resolved == null) {
        _readiness = const EquipReadyResult(equipReady: false);
      } else {
        final inv = await listInventoryItems(db, userId);
        final index = buildInventoryPinIndex([
          for (final row in inv)
            InventoryPinItem(
              instanceId: row.instanceId,
              itemHash: row.itemHash,
            ),
        ]);
        _readiness = computeEquipReady(resolved, index);
      }
      _error = null;
    } catch (e) {
      _error = _safe(e);
      _readiness = const EquipReadyResult(equipReady: false);
    } finally {
      _loadingReadiness = false;
      notifyListeners();
    }
  }

  Future<String?> requestExport() async {
    _error = null;
    _statusMessage = null;

    if (!hasVariant) {
      const msg = 'Select a variant to export';
      _error = msg;
      notifyListeners();
      return msg;
    }

    _exporting = true;
    notifyListeners();

    try {
      await refreshReadiness();
      final ready = _readiness;
      final resolved = _resolved;
      if (ready == null || !ready.equipReady || resolved == null) {
        final msg = formatDimExportBlockedMessage(ready);
        _error = msg;
        _exporting = false;
        notifyListeners();
        return msg;
      }

      final loadoutId = loadoutIdFactory?.call() ??
          'dim-${DateTime.now().toUtc().microsecondsSinceEpoch}';

      final payload = buildJsonOnlyDimExport(
        readiness: ready,
        input: VariantDimLoadoutInput(
          buildName: _buildName ?? 'Build',
          className: _className,
          variantName: _variantName,
          softStatTargets: _softStatTargets.isEmpty ? null : _softStatTargets,
          equipment: resolved.equipment,
          modHashes: const [],
        ),
        loadoutId: loadoutId,
      );

      final json = encodeDimExportJson(payload);
      await clipboardWriter(json);
      _clipboardWrites += 1;
      _lastJson = json;
      _statusMessage = kDimExportCopiedStatus;
      _error = null;
      _exporting = false;
      notifyListeners();
      return null;
    } on EquipReadyException catch (e) {
      final msg = e.message.isNotEmpty
          ? e.message
          : formatDimExportBlockedMessage(_readiness);
      _error = msg;
      _exporting = false;
      notifyListeners();
      return msg;
    } catch (e) {
      final msg = _safe(e);
      _error = msg;
      _exporting = false;
      notifyListeners();
      return msg;
    }
  }

  static String _safe(Object e) {
    final text = e.toString();
    if (text.length > 240) return '${text.substring(0, 240)}…';
    return text;
  }
}
