part of 'builds_mock_page.dart';

extension _BuildsMockDetail on _BuildsMockPageState {
  Widget _buildDetail(BuildContext context) {
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
              ButtonSegment(
                value: BuildsMockCardLayout.detail,
                label: Text('Detail'),
                icon: Icon(Icons.view_agenda_outlined, size: 16),
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
      case BuildsMockCardLayout.detail:
        return _buildSelectedDetail(context, builds);
    }
  }

  Widget _buildGrid(List<MockBuild> builds) {
    return GridView.builder(
      key: const Key('builds_mock_card_grid'),
      padding: const EdgeInsets.all(kPanelPadMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 620,
      ),
      itemCount: builds.length,
      itemBuilder: (context, i) {
        final build = builds[i];
        return SingleChildScrollView(
          child: BuildsMockLoadoutCard(
            loadout: build,
            selected: build.id == _controller.selectedId,
            density: BuildsMockCardDensity.tile,
            onSelect: () => _controller.selectBuild(build.id),
          ),
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
              _listHeader('BUILD / LOOP', flex: 3),
              _listHeader('EXOTICS / ARTIFACT', flex: 2),
              _listHeader('SET BONUSES', flex: 3),
              _listHeader('ARMOR Σ', flex: 2),
              const SizedBox(width: 120, child: Text('')),
              const SizedBox(width: 100, child: Text('')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: builds.length,
            itemBuilder: (context, i) {
              final build = builds[i];
              return BuildsMockLoadoutCard(
                loadout: build,
                selected: build.id == _controller.selectedId,
                density: BuildsMockCardDensity.list,
                onSelect: () => _controller.selectBuild(build.id),
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

  Widget _buildSelectedDetail(BuildContext context, List<MockBuild> builds) {
    MockBuild? build = _controller.selected;
    if (build != null && builds.every((b) => b.id != build!.id)) {
      build = builds.isEmpty ? null : builds.first;
    }
    if (build == null) {
      return const Center(
        child: Text(
          'Select a build',
          key: Key('builds_mock_detail_empty'),
        ),
      );
    }
    return SingleChildScrollView(
      key: const Key('builds_mock_card_detail'),
      padding: const EdgeInsets.all(kPanelPadMd),
      child: BuildsMockLoadoutCard(
        loadout: build,
        selected: true,
        density: BuildsMockCardDensity.detail,
      ),
    );
  }
}
