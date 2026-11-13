part of 'builds_mock_page.dart';

extension _BuildsMockBuildDetail on _BuildsMockPageState {
  Widget _buildBuildDetail(BuildContext context) {
    final build = _controller.selected;
    if (build == null) {
      return const Center(
        child: Text(
          'Select a build',
          key: Key('builds_mock_detail_empty'),
        ),
      );
    }
    final binding = _controller.dimBindingFor(build);
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('builds_mock_build_detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
          child: Row(
            children: [
              TextButton.icon(
                key: const Key('builds_mock_detail_back'),
                onPressed: _controller.closeBuildDetail,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  build.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                build.subclass,
                style: neonDisplay(fontSize: 11, letterSpacing: 0.6),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(kPanelPadSm),
            children: [
              BuildsMockLoadoutCard(
                loadout: build,
                selected: true,
                density: BuildsMockCardDensity.detail,
                priorities: _controller.statPrioritiesFor(build),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    key: Key('builds_mock_fill_in_${build.id}'),
                    onPressed: null,
                    child: const Text('Fill In'),
                  ),
                  OutlinedButton(
                    key: Key('builds_mock_optimize_${build.id}'),
                    onPressed: null,
                    child: const Text('Optimize'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DimLoadoutDetailsPanel.fromBinding(binding),
              const SizedBox(height: 16),
              Text(
                'Armor pool',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildPool(context, forBuild: build),
              const SizedBox(height: 16),
              Text(
                'Re-optimize',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildReoptimize(context, forBuild: build),
              const SizedBox(height: 12),
              Text(
                'Actions stay disabled until a live OK — read-only.',
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
