part of 'builds_mock_page.dart';

extension _BuildsMockRail on _BuildsMockPageState {
  Widget _buildRail(BuildContext context) {
    final visible = _controller.visibleBuildCount;
    final total = _controller.totalBuildCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kPanelPadSm,
            kSpace8,
            kPanelPadSm,
            kSpace4,
          ),
          child: TextField(
            key: const Key('builds_mock_search'),
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Search builds',
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
            ),
            onChanged: _controller.setQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPanelPadSm),
          child: Text(
            'Showing $visible of $total builds',
            key: const Key('builds_mock_count'),
            style: neonMono(
              color: FlapPalette.of(context).muted,
              fontSize: 11,
            ),
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: kSpace4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPanelPadSm),
            child: Wrap(
              key: const Key('builds_mock_active_filters'),
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_controller.filterExoticArmor != null)
                  _activeChip(
                    key: const Key('builds_mock_chip_exotic_armor'),
                    label: _controller.filterExoticArmor!,
                    onDeleted: () => _controller.setFilterExoticArmor(null),
                  ),
                if (_controller.filterExoticWeapon != null)
                  _activeChip(
                    key: const Key('builds_mock_chip_exotic_weapon'),
                    label: _controller.filterExoticWeapon!,
                    onDeleted: () => _controller.setFilterExoticWeapon(null),
                  ),
                if (_controller.filterSubclass != null)
                  _activeChip(
                    key: const Key('builds_mock_chip_subclass'),
                    label: _controller.filterSubclass!,
                    onDeleted: () => _controller.setFilterSubclass(null),
                  ),
                if (_controller.filterSetId != null)
                  _activeChip(
                    key: const Key('builds_mock_chip_set'),
                    label: _setName(_controller.filterSetId!),
                    onDeleted: () => _controller.setFilterSetId(null),
                  ),
                if (_controller.filterReadiness != null)
                  _activeChip(
                    key: const Key('builds_mock_chip_readiness'),
                    label: _readinessChipLabel(_controller.filterReadiness!),
                    onDeleted: () => _controller.setFilterReadiness(null),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: kSpace4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPanelPadSm),
          child: Column(
            key: const Key('builds_mock_filter_grid'),
            children: [
              _filterRow(
                key: const Key('builds_mock_filter_row_0'),
                left: _filterDropdown(
                  key: const Key('builds_mock_filter_exotic_armor'),
                  label: 'Exotic armor',
                  value: _controller.filterExoticArmor,
                  options: _controller.exoticArmorOptions,
                  onChanged: _controller.setFilterExoticArmor,
                  iconKind: _FilterIconKind.exoticArmor,
                ),
                right: _filterDropdown(
                  key: const Key('builds_mock_filter_exotic_weapon'),
                  label: 'Exotic weapon',
                  value: _controller.filterExoticWeapon,
                  options: _controller.exoticWeaponOptions,
                  onChanged: _controller.setFilterExoticWeapon,
                  iconKind: _FilterIconKind.exoticWeapon,
                ),
              ),
              const SizedBox(height: 6),
              _filterRow(
                key: const Key('builds_mock_filter_row_1'),
                left: _filterDropdown(
                  key: const Key('builds_mock_filter_subclass'),
                  label: 'Subclass',
                  value: _controller.filterSubclass,
                  options: _controller.subclassOptions,
                  onChanged: _controller.setFilterSubclass,
                  iconKind: _FilterIconKind.subclass,
                ),
                right: _setFilter(),
              ),
              const SizedBox(height: 6),
              _filterRow(
                key: const Key('builds_mock_filter_row_2'),
                left: _readinessFilter(),
                right: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpace8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPanelPadSm),
          child: Text(
            'BUILDS',
            style: neonDisplay(
              color: FlapPalette.of(context).muted,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: _sidebarBuildList(context),
        ),
      ],
    );
  }

  Widget _sidebarBuildList(BuildContext context) {
    final builds = _controller.visibleBuilds;
    final dupes = buildsMockDerivedNameDuplicateIndices(
      builds: builds,
      enrich: (b) => _enrichmentCache.enrich(b, _controller.dimLoadoutFor(b)),
      loadoutFor: _controller.dimLoadoutFor,
    );
    final palette = FlapPalette.of(context);
    return ListView.builder(
      key: const Key('builds_mock_sidebar_list'),
      padding: const EdgeInsets.symmetric(horizontal: kPanelPadSm),
      itemCount: builds.length,
      itemBuilder: (context, i) {
        final build = builds[i];
        final loadout = _controller.dimLoadoutFor(build);
        final enriched = _enrichmentCache.enrich(build, loadout);
        final derived = deriveBuildsMockName(
          build: enriched,
          loadout: loadout,
          duplicateIndexWithinClass: dupes[build.id] ?? 1,
        );
        final icons = _segmentIcons(build: enriched, loadout: loadout);
        final selected = build.id == _controller.selectedId;
        return InkWell(
          key: Key('builds_mock_sidebar_${build.id}'),
          onTap: () => _controller.openBuildDetail(build.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? palette.accentDim : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuildsMockDerivedTitle(
                  name: derived,
                  iconSize: 16,
                  fontSize: 12,
                  superIconPath: icons.superIconPath,
                  exoticArmorIconPath: icons.exoticArmorIconPath,
                  exoticWeaponIconPath: icons.exoticWeaponIconPath,
                ),
                const SizedBox(height: 2),
                Text(
                  derived.sourceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonMono(color: palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _hasActiveFilters =>
      _controller.filterExoticArmor != null ||
      _controller.filterExoticWeapon != null ||
      _controller.filterSubclass != null ||
      _controller.filterSetId != null ||
      _controller.filterReadiness != null;

  String _setName(String id) {
    for (final s in _controller.fixture.sets) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  Widget _activeChip({
    required Key key,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return InputChip(
      key: key,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _filterRow({
    required Key key,
    required Widget left,
    required Widget right,
  }) {
    return Row(
      key: key,
      children: [
        Expanded(child: left),
        const SizedBox(width: 6),
        Expanded(child: right),
      ],
    );
  }

  Widget _filterDropdown({
    required Key key,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    _FilterIconKind iconKind = _FilterIconKind.none,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      // ignore: deprecated_member_use
      value: value ?? '',
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Any')),
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: _optionLabel(o, iconKind: iconKind),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _setFilter() {
    return DropdownButtonFormField<String>(
      key: const Key('builds_mock_filter_set'),
      // ignore: deprecated_member_use
      value: _controller.filterSetId ?? '',
      isExpanded: true,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'Set',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Any')),
        for (final s in _controller.fixture.sets)
          DropdownMenuItem(
            value: s.id,
            child: _optionLabel(s.name, iconKind: _FilterIconKind.set),
          ),
      ],
      onChanged: _controller.setFilterSetId,
    );
  }

  String _readinessChipLabel(MockReadiness value) {
    switch (value) {
      case MockReadiness.ready:
        return 'Ready';
      case MockReadiness.notReady:
        return 'Not ready';
      case MockReadiness.filledIn:
        return 'Filled In';
      case MockReadiness.optimized:
        return 'Optimized';
    }
  }

  String _readinessWire(MockReadiness? current) {
    if (current == null) return '';
    switch (current) {
      case MockReadiness.ready:
        return 'ready';
      case MockReadiness.notReady:
        return 'not_ready';
      case MockReadiness.filledIn:
        return 'filled_in';
      case MockReadiness.optimized:
        return 'optimized';
    }
  }

  MockReadiness? _readinessFromWire(String? v) {
    switch (v) {
      case null:
      case '':
        return null;
      case 'ready':
        return MockReadiness.ready;
      case 'not_ready':
        return MockReadiness.notReady;
      case 'filled_in':
        return MockReadiness.filledIn;
      case 'optimized':
        return MockReadiness.optimized;
      default:
        return null;
    }
  }

  Widget _readinessFilter() {
    final wire = _readinessWire(_controller.filterReadiness);
    return DropdownButtonFormField<String>(
      key: const Key('builds_mock_filter_readiness'),
      // ignore: deprecated_member_use
      value: wire,
      isExpanded: true,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'Readiness',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('Any')),
        DropdownMenuItem(value: 'ready', child: Text('Ready')),
        DropdownMenuItem(value: 'not_ready', child: Text('Not ready')),
        DropdownMenuItem(value: 'filled_in', child: Text('Filled In')),
        DropdownMenuItem(value: 'optimized', child: Text('Optimized')),
      ],
      onChanged: (v) {
        _controller.setFilterReadiness(_readinessFromWire(v));
      },
    );
  }

  Widget _optionLabel(
    String label, {
    _FilterIconKind iconKind = _FilterIconKind.none,
  }) {
    final leading = _leadingIcon(label, iconKind: iconKind);
    return Row(
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Leading filter icon, or null when nothing resolves (no letter badge).
  Widget? _leadingIcon(
    String label, {
    required _FilterIconKind iconKind,
  }) {
    switch (iconKind) {
      case _FilterIconKind.none:
        return null;
      case _FilterIconKind.subclass:
        final visual = officialElementVisual(label);
        if (visual == null) return null;
        return DestinyOfficialIcon(
          visual: visual,
          size: 14,
          semanticLabel: label,
        );
      case _FilterIconKind.exoticArmor:
      case _FilterIconKind.exoticWeapon:
        final path = resolveCatalogExoticIconPath(
          name: label,
          catalogItems: _catalogItems,
          armor: iconKind == _FilterIconKind.exoticArmor,
        );
        if (path == null || path.isEmpty) return null;
        return BungieContentIcon(
          pathOrUrl: path,
          size: 14,
          fallback: const SizedBox.shrink(),
        );
      case _FilterIconKind.set:
        final path = resolveSetFilterIconPath(
          setName: label,
          iconByLowerName: _setIconByLowerName,
        );
        if (path == null || path.isEmpty) return null;
        return BungieContentIcon(
          pathOrUrl: path,
          size: 14,
          fallback: const SizedBox.shrink(),
        );
    }
  }
}

enum _FilterIconKind {
  none,
  exoticArmor,
  exoticWeapon,
  subclass,
  set,
}
