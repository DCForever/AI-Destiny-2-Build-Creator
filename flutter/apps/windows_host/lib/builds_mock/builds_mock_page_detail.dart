part of 'builds_mock_page.dart';

extension _BuildsMockDetail on _BuildsMockPageState {
  Widget _buildDetail(BuildContext context) {
    final build = _controller.selected;
    if (build == null) {
      return const Center(
        child: Text(
          'Select a build',
          key: Key('builds_mock_detail_empty'),
        ),
      );
    }
    final palette = FlapPalette.of(context);
    return SingleChildScrollView(
      key: const Key('builds_mock_detail'),
      padding: const EdgeInsets.all(kPanelPadMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            build.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${build.subclass} · ${build.exoticArmor} · ${build.exoticWeapon}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (build.solipsismNotPrismatic) ...[
            const SizedBox(height: 8),
            Text(
              'Solipsism only works with Prismatic',
              key: const Key('builds_mock_solipsism_flag'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (build.splitWhy != null) ...[
            const SizedBox(height: 8),
            Text(
              build.splitWhy!,
              key: const Key('builds_mock_split_why'),
              style: neonMono(color: palette.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SetsArmorBoard(
            key: const Key('builds_mock_armor_board'),
            slots: _slotsFor(build),
            showEnergyMods: false,
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                key: Key('builds_mock_open_dim'),
                onPressed: null,
                child: Text('Open in DIM'),
              ),
              OutlinedButton(
                key: Key('builds_mock_propose_swap'),
                onPressed: null,
                child: Text('Propose swap'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<SetsArmorSlotData> _slotsFor(MockBuild build) {
    return [
      for (final slot in kMockArmorSlots) _slotData(build, slot),
    ];
  }

  SetsArmorSlotData _slotData(MockBuild build, String slotWire) {
    MockSlotAssignment? assignment;
    for (final s in build.slots) {
      if (s.slot == slotWire) {
        assignment = s;
        break;
      }
    }
    final label = kMockArmorSlotLabels[slotWire] ?? slotWire;
    if (assignment == null) {
      return SetsArmorSlotData(slotWire: slotWire, slotLabel: label);
    }
    final held = assignment.isExoticSlot
        ? 1
        : _controller.fixture.heldFor(
            setId: assignment.setId,
            slot: slotWire,
          );
    final warnings = <String>[];
    if (!assignment.isExoticSlot && isZeroHeldWarning(held)) {
      warnings.add('0 held copies');
    }
    if (!assignment.isExoticSlot &&
        heldExceedsCap(held, _controller.inventoryCap)) {
      warnings.add(moreThanCapLabel(_controller.inventoryCap));
    }
    final setName = assignment.isExoticSlot
        ? 'Exotic'
        : (_controller.fixture.setById(assignment.setId)?.name ??
            assignment.setId);
    final mods = warnings.isEmpty ? setName : '${warnings.join(' · ')} · $setName';
    return SetsArmorSlotData(
      slotWire: slotWire,
      slotLabel: label,
      itemName: assignment.pieceName,
      isExotic: assignment.isExoticSlot,
      setBonusKey: assignment.isExoticSlot ? null : assignment.setId,
      modsLabel: mods,
    );
  }
}
