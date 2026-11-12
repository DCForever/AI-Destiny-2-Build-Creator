part of 'builds_mock_page.dart';

extension _BuildsMockRail on _BuildsMockPageState {
  Widget _buildRail(BuildContext context) {
    final builds = _controller.visibleBuilds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kPanelPadMd,
            kSpace8,
            kPanelPadMd,
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
          padding: const EdgeInsets.symmetric(horizontal: kPanelPadMd),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _filterDropdown(
                key: const Key('builds_mock_filter_exotic_armor'),
                label: 'Exotic armor',
                value: _controller.filterExoticArmor,
                options: _controller.exoticArmorOptions,
                onChanged: _controller.setFilterExoticArmor,
              ),
              _filterDropdown(
                key: const Key('builds_mock_filter_exotic_weapon'),
                label: 'Exotic weapon',
                value: _controller.filterExoticWeapon,
                options: _controller.exoticWeaponOptions,
                onChanged: _controller.setFilterExoticWeapon,
              ),
              _filterDropdown(
                key: const Key('builds_mock_filter_subclass'),
                label: 'Subclass',
                value: _controller.filterSubclass,
                options: _controller.subclassOptions,
                onChanged: _controller.setFilterSubclass,
              ),
              _setFilter(),
              _readinessFilter(),
            ],
          ),
        ),
        const SizedBox(height: kSpace4),
        const FlapBoardHeader(template: kFlapColumnsBuilds),
        Expanded(
          child: ListView.builder(
            key: const Key('builds_mock_list'),
            itemCount: builds.length,
            itemBuilder: (context, i) => _row(builds[i]),
          ),
        ),
      ],
    );
  }

  Widget _row(MockBuild build) {
    final selected = build.id == _controller.selectedId;
    final flag = build.solipsismNotPrismatic
        ? 'Solipsism only works with Prismatic'
        : null;
    return FlapBoardRow(
      key: Key('builds_mock_row_${build.id}'),
      template: kFlapColumnsBuilds,
      selected: selected,
      onTap: () => _controller.selectBuild(build.id),
      cells: [
        FlapTextCell(text: build.name, primary: true),
        FlapTextCell(text: build.subclass),
        FlapTextCell(text: build.exoticArmor),
        FlapTextCell(text: build.exoticWeapon),
        FlapTextCell(
          text: flag ?? 'ok',
          color: flag == null ? null : Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _filterDropdown({
    required Key key,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 148,
      child: DropdownButtonFormField<String>(
        key: key,
        // ignore: deprecated_member_use
        value: value ?? '',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Any')),
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _setFilter() {
    return SizedBox(
      width: 148,
      child: DropdownButtonFormField<String>(
        key: const Key('builds_mock_filter_set'),
        // ignore: deprecated_member_use
        value: _controller.filterSetId ?? '',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Set',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Any')),
          for (final s in _controller.fixture.sets)
            DropdownMenuItem(value: s.id, child: Text(s.name)),
        ],
        onChanged: _controller.setFilterSetId,
      ),
    );
  }

  Widget _readinessFilter() {
    final current = _controller.filterReadiness;
    final wire = current == null
        ? ''
        : current == MockReadiness.ready
            ? 'ready'
            : 'not_ready';
    return SizedBox(
      width: 148,
      child: DropdownButtonFormField<String>(
        key: const Key('builds_mock_filter_readiness'),
        // ignore: deprecated_member_use
        value: wire,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Readiness',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('Any')),
          DropdownMenuItem(value: 'ready', child: Text('Ready')),
          DropdownMenuItem(value: 'not_ready', child: Text('Not ready')),
        ],
        onChanged: (v) {
          if (v == null || v.isEmpty) {
            _controller.setFilterReadiness(null);
          } else if (v == 'ready') {
            _controller.setFilterReadiness(MockReadiness.ready);
          } else {
            _controller.setFilterReadiness(MockReadiness.notReady);
          }
        },
      ),
    );
  }
}
