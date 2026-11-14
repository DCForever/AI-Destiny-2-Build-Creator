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
    final icons = _segmentIcons(build: displayBuild, loadout: loadout);
    final plan = _savedFillInPlans[build.id];
    final plugs = splitSubclassPlugs(loadout?.subclassPlugs ?? const []);
    final placed = placeDimMods(
      mods: loadout?.mods ?? const [],
      build: displayBuild,
      slotCategoryByModHash: _modSlotCategoryByHash,
    );
    final statsResolution = resolveBuildsMockStats(
      build: displayBuild,
      armorItems: _optimize.armorItems,
      fillInPlan: plan,
    );
    final displayWithStats = statsResolution.isAvailable
        ? displayBuild.copyWith(stats: statsResolution.stats)
        : displayBuild;
    final palette = FlapPalette.of(context);
    final applyProgress = _applyProgressByBuild[build.id];
    // Prefer DIM artifact perk names; fall back to mock artifact.perks.
    final perkNames = (loadout?.artifactPerks.isNotEmpty ?? false)
        ? [
            for (final p in loadout!.artifactPerks)
              if (p.name.trim().isNotEmpty) p.name.trim(),
          ]
        : artifactPerksFromBuild(displayBuild);

    final optimizeEnabled = buildsOptimizeEnabled(_optimize);
    final optimizeDisabledReason = buildsOptimizeDisabledReason(_optimize);

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
                onPressed: () {
                  _detailTab = 'detail';
                  _optimize.closePanel();
                  _controller.closeBuildDetail();
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BuildsMockDerivedTitle(
                  name: derived,
                  iconSize: 19,
                  fontSize: 14,
                  superIconPath: icons.superIconPath,
                  exoticArmorIconPath: icons.exoticArmorIconPath,
                  exoticWeaponIconPath: icons.exoticWeaponIconPath,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SegmentedButton<String>(
            key: const Key('builds_mock_optimize_tabs'),
            segments: const [
              ButtonSegment(value: 'detail', label: Text('Detail')),
              ButtonSegment(
                value: 'pool',
                label: Text('Armor pool'),
              ),
              ButtonSegment(
                value: 'reopt',
                label: Text('Re-optimize'),
                enabled: false,
              ),
            ],
            selected: {_detailTab == 'reopt' ? 'detail' : _detailTab},
            onSelectionChanged: (s) => _selectDetailTab(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(
            _detailTab == 'pool'
                ? 'Armor pool is read-only set coverage from the DIM Armor CSV.'
                : 'Re-optimize stays disabled — hide-vs-grey is still Daniel\'s call.',
            style: neonMono(color: palette.muted, fontSize: 10),
          ),
        ),
        Expanded(
          child: _detailTab == 'pool'
              ? BuildsArmorPoolPanel(
                  controller: _optimize,
                  guardianClass: GuardianClass.warlock,
                )
              : ListView(
                  padding: const EdgeInsets.all(kPanelPadSm),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.tonal(
                          key: Key('builds_mock_fill_in_${build.id}'),
                          onPressed: _optimize.running || _optimize.applying
                              ? null
                              : () => _runFillInOptimize(context, build),
                          child: const Text('Fill In'),
                        ),
                        OutlinedButton(
                          key: Key('builds_mock_optimize_${build.id}'),
                          onPressed: !optimizeEnabled ||
                                  _optimize.running ||
                                  _optimize.applying
                              ? null
                              : () => _runOptimizePanel(context, build),
                          child: _optimize.running
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Optimize'),
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
                            key: Key(
                              'builds_mock_apply_disabled_reason_${build.id}',
                            ),
                            style: neonMono(color: palette.muted, fontSize: 11),
                          ),
                      ],
                    ),
                    if (!optimizeEnabled && optimizeDisabledReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        optimizeDisabledReason,
                        key: const Key('builds_optimize_disabled_reason'),
                        style: neonMono(color: palette.muted, fontSize: 11),
                      ),
                    ],
                    if (_optimizeStoreError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Optimize store unreadable — fix or remove '
                        'optimize_by_build.json ($_optimizeStoreError). '
                        'The corrupt file was not overwritten.',
                        key: const Key('builds_optimize_store_error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_fillInStoreError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Fill In store unreadable — fix or remove '
                        'missing_by_build.json ($_fillInStoreError). '
                        'The corrupt file was not overwritten.',
                        key: const Key('builds_fill_in_store_error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_optimize.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _optimize.error!,
                        key: const Key('builds_optimize_error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_optimize.panelOpen &&
                        _optimize.combinations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      BuildsOptimizeResultsPanel(
                        controller: _optimize,
                        statTargets: SoftStatTargets({
                          for (final s in build.stats)
                            if (armorStatFromMockStatId(s.id) case final name?)
                              name: s.value,
                        }),
                        onUseResult: (index) =>
                            _useOptimizeResult(context, build, index),
                        onCancel: () => _optimize.closePanel(),
                      ),
                    ],
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                      loadout: displayWithStats,
                      derivedName: derived,
                      selected: true,
                      density: BuildsMockCardDensity.detail,
                      priorities: _controller.statPrioritiesFor(build),
                      fillInPlan: plan,
                      superIconPath: icons.superIconPath,
                      exoticArmorIconPath: icons.exoticArmorIconPath,
                      exoticWeaponIconPath: icons.exoticWeaponIconPath,
                      showMods: true,
                      modsBySlot: placed.bySlot,
                      unplacedMods: const [],
                      subclassAbilities: plugs.abilities,
                      subclassAspects: plugs.aspects,
                      subclassFragments: plugs.fragments,
                      artifactPerks: perkNames,
                      notes: loadout?.notes,
                      showDetailExtras: true,
                      statsUnavailableReason:
                          statsResolution.unavailableReason,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kBuildsMockDetailUndoCaption,
                      style: neonMono(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _runOptimizePanel(BuildContext context, MockBuild build) async {
    await _optimize.runOptimize(
      build: build,
      mode: BuildsOptimizeMode.panel,
    );
  }

  Future<void> _runFillInOptimize(BuildContext context, MockBuild build) async {
    if (!buildsOptimizeEnabled(_optimize)) {
      // Fall back to legacy Fill In dialog when no CSV (weapons / missing list).
      await _openLegacyFillIn(context, build);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final root = widget.storageRoot;

    // Read Fill In plan BEFORE any Optimize/Fill In write. Corrupt file →
    // visible error, stop, never overwrite.
    FillInSavedBuildPlan? priorPlan = _savedFillInPlans[build.id];
    if (root != null) {
      try {
        priorPlan =
            await FillInMissingListStore(root: root).loadForBuild(build.id);
        _clearFillInStoreError();
      } on FillInMissingListStoreException catch (e) {
        if (!mounted) return;
        _reportFillInStoreError(e.message);
        messenger.showSnackBar(
          SnackBar(
            key: const Key('builds_fill_in_store_error_toast'),
            content: Text(
              'Fill In store unreadable — fix or remove missing_by_build.json '
              '(${e.message}). Nothing was written.',
            ),
          ),
        );
        return;
      }
    }

    var updated = await _optimize.runOptimize(
      build: build,
      mode: BuildsOptimizeMode.autoApplyFirst,
    );
    if (!mounted || updated == null) return;

    // Same action: after armor #1, fill weapons the existing substitute way
    // and merge pins (B1) — not opt-in. Merge armor onto the pre-checked
    // plan in memory (do not re-read the store for corrupt handling).
    final FillInCacheLoader loader = widget.fillInCacheLoader ??
        (root != null
            ? defaultFillInCacheLoader(root)
            : () async => FillInCacheLoadResult.missing(
                  'DIM Armor/Weapons inventory cache is missing or unreadable.',
                ));
    final appliedCombo = _optimize.combinations.isNotEmpty
        ? _optimize.combinations[
            ((_optimize.appliedResultIndex ?? 1) - 1).clamp(
              0,
              _optimize.combinations.length - 1,
            )]
        : null;
    final planForWeapons = appliedCombo == null
        ? priorPlan
        : fillInPlanFromCombination(
            buildId: build.id,
            combination: appliedCombo,
            existing: priorPlan,
          );
    final weaponResult = await applyWeaponFillInAfterOptimize(
      build: updated,
      loadCaches: loader,
      existingPlan: planForWeapons,
      dimLoadout: _controller.dimLoadoutFor(updated),
    );
    if (!mounted) return;
    if (weaponResult != null) {
      updated = weaponResult.build;
      await _optimize.persistMergedFillInPlan(weaponResult.plan);
    }

    _controller.replaceBuild(updated);
    if (root != null) await _loadFillInPlans(root);
    if (!mounted) return;
    final idx = _optimize.appliedResultIndex ?? 1;
    _showOptimizeToast(messenger, idx);
  }

  Future<void> _useOptimizeResult(
    BuildContext context,
    MockBuild build,
    int index,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await _optimize.applySelectedResult(
      build: build,
      index: index,
    );
    if (!mounted || updated == null) return;
    _controller.replaceBuild(updated);
    final root = widget.storageRoot;
    if (root != null) await _loadFillInPlans(root);
    if (!mounted) return;
    _showOptimizeToast(messenger, index + 1);
  }

  void _showOptimizeToast(
    ScaffoldMessengerState messenger,
    int resultIndexOneBased,
  ) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('builds_optimize_toast'),
        content: Text(optimizeAppliedToastMessage(resultIndexOneBased)),
        action: SnackBarAction(
          key: const Key('builds_optimize_toast_undo'),
          label: 'Undo',
          onPressed: () async {
            final restored = await _optimize.undoLastApply();
            if (!mounted || restored == null) return;
            _controller.replaceBuild(restored);
            final root = widget.storageRoot;
            if (root != null) await _loadFillInPlans(root);
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _openLegacyFillIn(BuildContext context, MockBuild build) async {
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
