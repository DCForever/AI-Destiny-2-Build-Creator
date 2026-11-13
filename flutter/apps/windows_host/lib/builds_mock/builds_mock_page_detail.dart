part of 'builds_mock_page.dart';

extension _BuildsMockDetail on _BuildsMockPageState {
  static const double _kGridTwoColBreakpoint = 900;

  Widget _buildBrowse(BuildContext context) {
    final builds = _controller.visibleBuilds;
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('builds_mock_detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _disabledOptimizeTabs(palette),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SegmentedButton<BuildsMockCardLayout>(
            key: const Key('builds_mock_card_layout'),
            segments: const [
              ButtonSegment(
                value: BuildsMockCardLayout.grid,
                label: Text('Grid'),
                icon: Icon(Icons.grid_view_outlined, size: 16),
              ),
              ButtonSegment(
                value: BuildsMockCardLayout.list,
                label: Text('List'),
                icon: Icon(Icons.view_list_outlined, size: 16),
              ),
            ],
            selected: {_controller.cardLayout},
            onSelectionChanged: (s) => _controller.setCardLayout(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(
            'Armor pool and Re-optimize are disabled — coming with Optimize '
            '(no inventory data yet).',
            key: const Key('builds_mock_optimize_tabs_hint'),
            style: neonMono(color: palette.muted, fontSize: 10),
          ),
        ),
        Expanded(child: _cardLayoutBody(context, builds)),
      ],
    );
  }

  Widget _disabledOptimizeTabs(FlapPalette palette) {
    return IgnorePointer(
      child: SegmentedButton<String>(
        key: const Key('builds_mock_optimize_tabs'),
        segments: const [
          ButtonSegment(value: 'detail', label: Text('Detail')),
          ButtonSegment(
            value: 'pool',
            label: Text('Armor pool'),
            enabled: false,
          ),
          ButtonSegment(
            value: 'reopt',
            label: Text('Re-optimize'),
            enabled: false,
          ),
        ],
        selected: const {'detail'},
        onSelectionChanged: (_) {},
        emptySelectionAllowed: false,
      ),
    );
  }

  Widget _cardLayoutBody(BuildContext context, List<MockBuild> builds) {
    switch (_controller.cardLayout) {
      case BuildsMockCardLayout.grid:
        return _buildGrid(builds);
      case BuildsMockCardLayout.list:
        return _buildList(builds);
    }
  }

  Widget _buildGrid(List<MockBuild> builds) {
    final dupes = _derivedNameDupes(builds);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < _kGridTwoColBreakpoint ? 2 : 3;
        return GridView.builder(
          key: Key('builds_mock_card_grid_$cols'),
          padding: const EdgeInsets.all(kPanelPadSm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: kPanelPadSm,
            crossAxisSpacing: kPanelPadSm,
            mainAxisExtent: 420,
          ),
          itemCount: builds.length,
          itemBuilder: (context, i) {
            final build = builds[i];
            return _browseCardFor(
              build,
              density: BuildsMockCardDensity.tile,
              duplicateIndex: dupes[build.id] ?? 1,
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<MockBuild> builds) {
    final dupes = _derivedNameDupes(builds);
    return ListView.builder(
      key: const Key('builds_mock_card_list'),
      padding: const EdgeInsets.all(kPanelPadSm),
      itemCount: builds.length,
      itemBuilder: (context, i) {
        final build = builds[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _browseCardFor(
            build,
            density: BuildsMockCardDensity.list,
            duplicateIndex: dupes[build.id] ?? 1,
          ),
        );
      },
    );
  }

  Widget _browseCardFor(
    MockBuild build, {
    required BuildsMockCardDensity density,
    required int duplicateIndex,
  }) {
    final loadout = _controller.dimLoadoutFor(build);
    final enriched = _enrichmentCache.enrich(build, loadout);
    final derived = deriveBuildsMockName(
      build: enriched,
      loadout: loadout,
      duplicateIndexWithinClass: duplicateIndex,
    );
    final icons = _segmentIcons(build: enriched, loadout: loadout);
    return BuildsMockLoadoutCard(
      loadout: enriched,
      derivedName: derived,
      selected: build.id == _controller.selectedId,
      density: density,
      priorities: _controller.statPrioritiesFor(build),
      fillInPlan: _savedFillInPlans[build.id],
      superIconPath: icons.superIconPath,
      exoticArmorIconPath: icons.exoticArmorIconPath,
      exoticWeaponIconPath: icons.exoticWeaponIconPath,
      onSelect: () => _controller.openBuildDetail(build.id),
    );
  }

  Map<String, int> _derivedNameDupes(List<MockBuild> builds) {
    return buildsMockDerivedNameDuplicateIndices(
      builds: builds,
      enrich: (b) => _enrichmentCache.enrich(b, _controller.dimLoadoutFor(b)),
      loadoutFor: _controller.dimLoadoutFor,
    );
  }
}
