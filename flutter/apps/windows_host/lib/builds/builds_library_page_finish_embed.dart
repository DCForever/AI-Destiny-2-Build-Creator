part of 'builds_library_page.dart';

/// Embedded Armor improve workspace on Build Finish (DART-067 / GAP-UI-BUILD-04).
///
/// Confirm-only: Find kits never writes; apply requires OptimizerWorkspace confirm.
class _FinishArmorOptimizeEmbed extends StatefulWidget {
  const _FinishArmorOptimizeEmbed({
    super.key,
    required this.services,
    required this.setId,
    required this.setName,
    required this.resolveUserId,
    required this.onApplied,
    required this.onManualFill,
    required this.onBack,
  });

  final AppServices services;
  final String setId;
  final String setName;
  /// Same owner resolution as library controllers (BUG-20260726-015).
  final Future<int> Function() resolveUserId;
  final Future<void> Function() onApplied;
  final Future<void> Function() onManualFill;
  final VoidCallback onBack;

  @override
  State<_FinishArmorOptimizeEmbed> createState() =>
      _FinishArmorOptimizeEmbedState();
}

class _FinishArmorOptimizeEmbedState extends State<_FinishArmorOptimizeEmbed> {
  late final OptimizerController _optimizer;

  @override
  void initState() {
    super.initState();
    _optimizer = OptimizerController(
      db: widget.services.db,
      // Never fall back to userId 0 — match Sets optimizer / library owner.
      resolveUserId: widget.resolveUserId,
    );
    _optimizer.bindTargetSet(setId: widget.setId, setName: widget.setName);
  }

  @override
  void didUpdateWidget(covariant _FinishArmorOptimizeEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setId != widget.setId || oldWidget.setName != widget.setName) {
      _optimizer.bindTargetSet(setId: widget.setId, setName: widget.setName);
    }
  }

  @override
  void dispose() {
    _optimizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Armor improve · ${widget.setName}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Find kits never writes. Confirm apply-in-place only. Soft never auto-applies.',
          key: const Key('finish_armor_improve_policy'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OptimizerWorkspace(
          key: const Key('finish_optimizer_workspace'),
          controller: _optimizer,
          onApplied: () {
            widget.onApplied();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              key: const Key('finish_armor_manual_fill'),
              onPressed: () => widget.onManualFill(),
              child: const Text('Manual fill'),
            ),
            TextButton(
              key: const Key('finish_armor_optimize_back'),
              onPressed: widget.onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }
}

