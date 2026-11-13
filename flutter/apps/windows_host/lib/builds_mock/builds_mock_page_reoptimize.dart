part of 'builds_mock_page.dart';

extension _BuildsMockReoptimize on _BuildsMockPageState {
  Widget _buildReoptimize(BuildContext context, {MockBuild? forBuild}) {
    final readiness = forBuild == null
        ? _controller.readiness
        : [
            for (final row in _controller.readiness)
              if (forBuild.setIds.contains(row.setId)) row,
          ];
    final swaps = forBuild == null
        ? _controller.fixture.swaps
        : [
            for (final swap in _controller.fixture.swaps)
              if (swap.buildId == forBuild.id) swap,
          ];
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('builds_mock_reoptimize'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set readiness (Ready = ≥$kMockReadyBuildCount builds & '
          '≥$kMockReadySlotUses uses per slot)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (readiness.isEmpty)
          Text(
            forBuild == null
                ? 'No readiness data loaded.'
                : 'No readiness rows for this build\'s sets.',
            key: const Key('builds_mock_ready_empty'),
            style: neonMono(color: palette.muted, fontSize: 12),
          )
        else
          for (final row in readiness) _readinessTile(row),
        const SizedBox(height: 16),
        Text(
          'Proposed swaps (dry-run — local UI only)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (swaps.isEmpty)
          Text(
            forBuild == null
                ? 'No swap proposals loaded.'
                : 'No swap proposals for this build.',
            key: const Key('builds_mock_swaps_empty'),
            style: neonMono(color: palette.muted, fontSize: 12),
          )
        else
          for (final swap in swaps) _swapTile(swap),
      ],
    );
  }

  Widget _readinessTile(MockSetReadiness row) {
    final ready = row.status == MockReadiness.ready;
    final slotSummary = kMockArmorSlots
        .map((s) => '${kMockArmorSlotLabels[s]}:${row.slotUses[s] ?? 0}')
        .join(' · ');
    return ListTile(
      key: Key('builds_mock_ready_${row.setId}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(row.setName),
      subtitle: Text(
        '${row.buildCount} builds · $slotSummary',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        ready ? 'Ready' : 'Not ready',
        key: Key('builds_mock_ready_badge_${row.setId}'),
        style: TextStyle(
          color: ready
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _swapTile(MockSwapProposal swap) {
    final decision = _controller.swapDecision(swap.id);
    return Card(
      key: Key('builds_mock_swap_${swap.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              swap.buildName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(swap.summary),
            if (swap.changesSplit)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Includes 2pc split change'),
              ),
            const SizedBox(height: 8),
            if (decision == MockSwapDecision.pending)
              Row(
                children: [
                  FilledButton(
                    key: Key('builds_mock_swap_accept_${swap.id}'),
                    onPressed: null,
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: Key('builds_mock_swap_reject_${swap.id}'),
                    onPressed: null,
                    child: const Text('Reject'),
                  ),
                ],
              )
            else
              Text(
                decision == MockSwapDecision.accepted
                    ? 'Accepted (mock)'
                    : 'Rejected (mock)',
                key: Key('builds_mock_swap_state_${swap.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
