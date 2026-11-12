part of 'builds_mock_page.dart';

extension _BuildsMockPool on _BuildsMockPageState {
  Widget _buildPool(BuildContext context) {
    final palette = FlapPalette.of(context);
    final cap = _controller.inventoryCap;
    final sets = _controller.fixture.sets;
    return SingleChildScrollView(
      key: const Key('builds_mock_pool'),
      padding: const EdgeInsets.all(kPanelPadMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Armor pool (set × slot) — held vs cap $cap',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: palette.line, width: kFlapRuleThickness),
              borderRadius: BorderRadius.circular(kFlapRadius),
            ),
            child: Column(
              children: [
                _poolHeader(palette),
                for (final set in sets) _poolRow(set, palette, cap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _poolHeader(FlapPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: palette.surfaceRaised,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'SET',
              style: neonDisplay(color: palette.muted, fontSize: 9),
            ),
          ),
          for (final slot in kMockArmorSlots)
            Expanded(
              child: Text(
                (kMockArmorSlotLabels[slot] ?? slot).toUpperCase(),
                textAlign: TextAlign.center,
                style: neonDisplay(color: palette.muted, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _poolRow(MockArmorSet set, FlapPalette palette, int cap) {
    return Container(
      key: Key('builds_mock_pool_row_${set.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: palette.line.withValues(alpha: 0.55),
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(set.name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final slot in kMockArmorSlots)
            Expanded(child: _poolCell(set.id, slot, cap, palette)),
        ],
      ),
    );
  }

  Widget _poolCell(
    String setId,
    String slot,
    int cap,
    FlapPalette palette,
  ) {
    final held = _controller.fixture.heldFor(setId: setId, slot: slot);
    final over = heldExceedsCap(held, cap);
    final zero = isZeroHeldWarning(held);
    final color = over
        ? Theme.of(context).colorScheme.error
        : zero
            ? palette.muted
            : palette.foreground;
    return Column(
      key: Key('builds_mock_pool_cell_${setId}_$slot'),
      children: [
        Text(
          '$held / $cap',
          textAlign: TextAlign.center,
          style: neonMono(color: color, fontSize: 12),
        ),
        if (over)
          Text(
            moreThanCapLabel(cap),
            key: Key('builds_mock_pool_over_${setId}_$slot'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 10,
            ),
          ),
        if (zero)
          Text(
            '0 held',
            key: Key('builds_mock_pool_zero_${setId}_$slot'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
      ],
    );
  }
}
