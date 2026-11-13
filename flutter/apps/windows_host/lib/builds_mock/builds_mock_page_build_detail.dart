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
                    onPressed: () => _openFillIn(context, build),
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
              if (_savedFillInPlans[build.id] != null) ...[
                const SizedBox(height: 12),
                _SavedFillInPlan(plan: _savedFillInPlans[build.id]!),
              ],
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
                'Fill In is read-only (DIM caches). Optimize stays disabled.',
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openFillIn(BuildContext context, MockBuild build) async {
    final root = widget.storageRoot;
    final FillInCacheLoader loader = root != null
        ? defaultFillInCacheLoader(root)
        : () async => FillInCacheLoadResult.missing(
              'DIM Armor/Weapons inventory cache is missing or unreadable. '
              'Import both CSVs in Settings, then try Fill In again.',
            );
    final store =
        root == null ? null : FillInMissingListStore(root: root);
    await showFillInDialog(
      context: context,
      build: build,
      loadCaches: loader,
      saveMissingList:
          store == null ? null : (plan) => store.saveBuildPlan(plan),
      onMissingListSaved: root == null ? null : () => _loadFillInPlans(root),
    );
  }
}

class _SavedFillInPlan extends StatelessWidget {
  const _SavedFillInPlan({required this.plan});

  final FillInSavedBuildPlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('fill_in_saved_plan_${plan.buildId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved missing list',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (plan.missing.isEmpty)
              const Text('None', key: Key('fill_in_saved_missing_empty'))
            else
              Text(
                plan.missing.join('\n'),
                key: const Key('fill_in_saved_missing_list'),
              ),
            if (plan.similarWeaponName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Similar: ${plan.similarWeaponName}'
                '${plan.similarForName == null ? '' : ' (for ${plan.similarForName})'}',
                key: const Key('fill_in_saved_similar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
