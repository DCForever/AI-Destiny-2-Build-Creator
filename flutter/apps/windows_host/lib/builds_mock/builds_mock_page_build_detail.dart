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
    final loadout = binding.loadout;
    final displayBuild = _enrichmentCache.enrich(build, loadout);
    final dupes = buildsMockDerivedNameDuplicateIndices(
      builds: _controller.visibleBuilds,
      enrich: (b) => _enrichmentCache.enrich(b, _controller.dimLoadoutFor(b)),
      loadoutFor: _controller.dimLoadoutFor,
    );
    final derived = deriveBuildsMockName(
      build: displayBuild,
      loadout: loadout,
      duplicateIndexWithinClass: dupes[build.id] ?? 1,
    );
    final plan = _savedFillInPlans[build.id];
    final plugs = splitSubclassPlugs(loadout?.subclassPlugs ?? const []);
    final placed = placeDimMods(
      mods: loadout?.mods ?? const [],
      build: displayBuild,
    );
    final palette = FlapPalette.of(context);
    final applyProgress = _applyProgressByBuild[build.id];
    // Prefer DIM artifact perk names; fall back to mock artifact.perks.
    final perkNames = (loadout?.artifactPerks.isNotEmpty ?? false)
        ? [
            for (final p in loadout!.artifactPerks)
              if (p.name.trim().isNotEmpty) p.name.trim(),
          ]
        : artifactPerksFromBuild(displayBuild);

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
                child: BuildsMockDerivedTitle(
                  name: derived,
                  iconSize: 16,
                  fontSize: 14,
                  superIconPath: dimLoadoutSuperIconPath(loadout),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: IgnorePointer(
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
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(
            'Armor pool and Re-optimize are disabled — coming with Optimize.',
            style: neonMono(color: palette.muted, fontSize: 10),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(kPanelPadSm),
            children: [
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
              if (plan != null) ...[
                const SizedBox(height: 8),
                Text(
                  fillInSavedPlanTitle(plan),
                  key: const Key('fill_in_saved_title'),
                  style: neonMono(color: palette.muted, fontSize: 12),
                ),
              ],
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
              if (binding.status == DimLoadoutsPanelStatus.ambiguous) ...[
                const SizedBox(height: 8),
                Text(
                  'ambiguous (${binding.ambiguousCount} loadouts)',
                  key: const Key('dim_loadout_details_ambiguous'),
                  style: neonMono(color: palette.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              BuildsMockLoadoutCard(
                loadout: displayBuild,
                derivedName: derived,
                selected: true,
                density: BuildsMockCardDensity.detail,
                priorities: _controller.statPrioritiesFor(build),
                fillInPlan: plan,
                superIconPath: dimLoadoutSuperIconPath(loadout),
                showMods: true,
                modsBySlot: placed.bySlot,
                unplacedMods: placed.unplaced,
                subclassAbilities: plugs.abilities,
                subclassAspects: plugs.aspects,
                subclassFragments: plugs.fragments,
                artifactPerks: perkNames,
                notes: loadout?.notes,
                showDetailExtras: true,
              ),
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
    final FillInCacheLoader loader = widget.fillInCacheLoader ??
        (root != null
            ? defaultFillInCacheLoader(root)
            : () async => FillInCacheLoadResult.missing(
                  'DIM Armor/Weapons inventory cache is missing or unreadable. '
                  'Import both CSVs in Settings, then try Fill In again.',
                ));
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

List<String> artifactPerksFromBuild(MockBuild build) {
  return [
    for (final p in build.artifact.perks)
      if (p.trim().isNotEmpty && p.trim() != '—') p.trim(),
  ];
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
