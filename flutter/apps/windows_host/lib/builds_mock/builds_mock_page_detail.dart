part of 'builds_mock_page.dart';

extension _BuildsMockDetail on _BuildsMockPageState {
  static const double _kGridTwoColBreakpoint = 900;

  Widget _buildBrowse(BuildContext context) {
    final builds = _controller.visibleBuilds;
    return Column(
      key: const Key('builds_mock_detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Expanded(child: _cardLayoutBody(context, builds)),
      ],
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
            mainAxisExtent: 176,
          ),
          itemCount: builds.length,
          itemBuilder: (context, i) {
            final build = builds[i];
            return BuildsMockLoadoutCard(
              loadout: build,
              selected: build.id == _controller.selectedId,
              density: BuildsMockCardDensity.tile,
              priorities: _controller.statPrioritiesFor(build),
              onSelect: () => _controller.openBuildDetail(build.id),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<MockBuild> builds) {
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('builds_mock_card_list'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: palette.surfaceRaised,
          child: Row(
            children: [
              _listHeader('BUILD', flex: 3),
              _listHeader('EXOTICS', flex: 2),
              _listHeader('STATS', flex: 2),
              _listHeader('ARTIFACT', flex: 1),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('builds_mock_list'),
            itemCount: builds.length,
            itemBuilder: (context, i) {
              final build = builds[i];
              return BuildsMockLoadoutCard(
                loadout: build,
                selected: build.id == _controller.selectedId,
                density: BuildsMockCardDensity.list,
                priorities: _controller.statPrioritiesFor(build),
                onSelect: () => _controller.openBuildDetail(build.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _listHeader(String label, {required int flex}) {
    final palette = FlapPalette.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: neonDisplay(
          color: palette.muted,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
