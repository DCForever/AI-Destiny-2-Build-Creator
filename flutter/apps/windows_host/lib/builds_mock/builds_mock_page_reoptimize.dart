part of 'builds_mock_page.dart';

extension _BuildsMockReoptimize on _BuildsMockPageState {
  Widget _buildReoptimize(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('builds_mock_reoptimize'),
      padding: const EdgeInsets.all(kPanelPadMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set readiness (Ready = ≥$kMockReadyBuildCount builds & '
            '≥$kMockReadySlotUses uses per slot)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final row in _controller.readiness) _readinessTile(row),
          const SizedBox(height: 16),
          Text(
            'Proposed swaps (dry-run — local UI only)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final swap in _controller.fixture.swaps) _swapTile(swap),
        ],
      ),
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
                    onPressed: () => _controller.acceptSwap(swap.id),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: Key('builds_mock_swap_reject_${swap.id}'),
                    onPressed: () => _controller.rejectSwap(swap.id),
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
