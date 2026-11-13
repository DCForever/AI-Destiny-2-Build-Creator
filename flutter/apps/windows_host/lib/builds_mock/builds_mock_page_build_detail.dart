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
    final displayBuild = enrichMockBuildFromDimLoadout(
      build,
      loadout: binding.loadout,
    );
    final palette = FlapPalette.of(context);
    final applyProgress = _applyProgressByBuild[build.id];
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
                  displayBuild.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                displayBuild.subclass,
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
                loadout: displayBuild,
                selected: true,
                density: BuildsMockCardDensity.detail,
                priorities: _controller.statPrioritiesFor(build),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  FilledButton(
                    key: Key('builds_mock_apply_character_${build.id}'),
                    onPressed: _applyingBuildId == build.id ||
                            _applyTarget == null
                        ? null
                        : () => _applyToCharacter(build),
                    child: Text(
                      _applyingBuildId == build.id
                          ? 'Applying…'
                          : 'Apply to character',
                    ),
                  ),
                  if (_applyTargetLabel != null)
                    Text(
                      'Applies to: $_applyTargetLabel',
                      key: Key('builds_mock_apply_target_${build.id}'),
                      style: neonMono(color: palette.muted, fontSize: 11),
                    )
                  else if (_applyDisabledReason != null)
                    Text(
                      _applyDisabledReason!,
                      key: Key('builds_mock_apply_disabled_reason_${build.id}'),
                      style: neonMono(color: palette.muted, fontSize: 11),
                    ),
                ],
              ),
              if (applyProgress != null) ...[
                const SizedBox(height: 12),
                _ApplyProgressPanel(
                  buildId: build.id,
                  progress: applyProgress,
                ),
              ],
              if (_applyErrorByBuild[build.id] != null) ...[
                const SizedBox(height: 8),
                Text(
                  _applyErrorByBuild[build.id]!,
                  key: Key('builds_mock_apply_error_${build.id}'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_savedFillInPlans[build.id] != null) ...[
                const SizedBox(height: 12),
                FillInSavedPlanCard(plan: _savedFillInPlans[build.id]!),
              ],
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
                'Fill In updates this app copy; Undo fill in restores it. '
                'Apply to character equips one item at a time and has no undo — '
                're-apply another build to change gear. Optimize stays disabled.',
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
    final dimLoadout = _controller.dimLoadoutFor(build);
    await showFillInDialog(
      context: context,
      build: build,
      loadCaches: loader,
      saveMissingList:
          store == null ? null : (plan) => store.saveBuildPlan(plan),
      onMissingListSaved: root == null ? null : () => _loadFillInPlans(root),
      existingPlan: _savedFillInPlans[build.id],
      dimLoadout: dimLoadout,
      onBuildUpdated: (updated) {
        _controller.replaceBuild(updated);
      },
    );
  }
}

class _ApplyProgressPanel extends StatelessWidget {
  const _ApplyProgressPanel({
    required this.buildId,
    required this.progress,
  });

  final String buildId;
  final ApplyToCharacterProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('builds_mock_apply_progress_$buildId'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              progress.running
                  ? progress.applyingLine
                  : (progress.summary ?? ''),
              key: Key('builds_mock_apply_summary_$buildId'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final item in progress.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  key: Key('builds_mock_apply_item_${item.id}'),
                  children: [
                    _ApplyStateIcon(state: item.state),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.reason == null
                            ? item.label
                            : '${item.label} — ${item.reason}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplyStateIcon extends StatelessWidget {
  const _ApplyStateIcon({required this.state});

  final ApplyItemState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ApplyItemState.waiting:
        return Icon(
          Icons.circle_outlined,
          size: 16,
          key: const Key('apply_state_waiting'),
          color: Theme.of(context).disabledColor,
        );
      case ApplyItemState.applying:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ApplyItemState.done:
        return Icon(
          Icons.check_circle,
          size: 16,
          key: const Key('apply_state_done'),
          color: Theme.of(context).colorScheme.primary,
        );
      case ApplyItemState.failed:
        return Icon(
          Icons.cancel,
          size: 16,
          key: const Key('apply_state_failed'),
          color: Theme.of(context).colorScheme.error,
        );
    }
  }
}

