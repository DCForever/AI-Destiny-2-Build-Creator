part of 'builds_library_page.dart';

extension _BuildsLibraryRailSection on _BuildsLibraryPageState {
  Widget _buildRail(BuildContext context) {
    // Intent plate: class + synergy → primary Create; secondary Add type.
    // Offstage create keys stay mounted for widget tests / controller wiring.
    final draftTypes = _controller.createDraftTypes;
    final draftSummary = draftTypes.isEmpty
        ? 'Next: class + synergy type → Create'
        : '${displayGuardianClass(_createClass)} · '
            '${draftTypes.map((d) => displaySynergyDraft(d.type, d.subType)).join(', ')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            key: const Key('builds_create_toggle'),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kPanelPadMd,
              vertical: kSpace2,
            ),
            title: Text(
              'New build',
              style: _sectionTitleStyle(context),
            ),
            subtitle: Text(
              _createExpanded
                  ? '1 Class · 2 Synergy · 3 Create'
                  : draftSummary,
              style: _bodyMutedStyle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              _createExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _createExpandedOverride = !_createExpanded;
              });
            },
          ),
        ),
        if (_createExpanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kPanelPadMd,
                  0,
                  kPanelPadMd,
                  kSpace8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '1 · Class',
                      key: const Key('builds_create_step_class'),
                      style: _sectionLabelStyle(context),
                    ),
                    const SizedBox(height: kSpace4),
                    Wrap(
                      key: const Key('builds_create_class'),
                      spacing: kSpace6,
                      runSpacing: kSpace4,
                      children: [
                        for (final c in GuardianClass.values)
                          FilterChip(
                            key: Key('builds_create_class_${c.wireName}'),
                            label: Text(displayGuardianClass(c)),
                            selected: _createClass == c,
                            onSelected: (_) {
                              setState(() => _createClass = c);
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: kSpace12),
                    Text(
                      '2 · Synergy types',
                      key: const Key('builds_create_step_synergy'),
                      style: _sectionLabelStyle(context),
                    ),
                    const SizedBox(height: kSpace4),
                    DropdownButtonFormField<String>(
                      key: const Key('builds_create_synergy_type'),
                      // ignore: deprecated_member_use
                      value: _createTypeWire,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final t in creatableSynergyTypeWires)
                          DropdownMenuItem(
                            value: t,
                            child: Text(displaySynergyTypeWire(t)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _createTypeWire = v);
                      },
                    ),
                    const SizedBox(height: kSpace6),
                    TextField(
                      key: const Key('builds_create_synergy_subtype'),
                      controller: _createSubTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Subtype (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: kSpace6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('builds_create_add_synergy'),
                        onPressed: () {
                          _controller.addCreateDraftType(
                            _createTypeWire,
                            _createSubTypeController.text,
                          );
                          _createSubTypeController.clear();
                        },
                        child: const Text('Add another type'),
                      ),
                    ),
                    if (draftTypes.isNotEmpty) ...[
                      const SizedBox(height: kSpace6),
                      Wrap(
                        key: const Key('builds_create_synergy_chips'),
                        spacing: kSpace4,
                        runSpacing: kSpace4,
                        children: [
                          for (var i = 0; i < draftTypes.length; i++)
                            InputChip(
                              key: Key('builds_create_synergy_chip_$i'),
                              label: Text(
                                displaySynergyDraft(
                                  draftTypes[i].type,
                                  draftTypes[i].subType,
                                ),
                              ),
                              onDeleted: () =>
                                  _controller.removeCreateDraftTypeAt(i),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: kSpace4),
                        child: Text(
                          'Pick a type and Create (auto-adds), or Add another type for several.',
                          key: const Key('builds_create_types_hint'),
                          style: _bodyMutedStyle(context),
                        ),
                      ),
                    const SizedBox(height: kSpace12),
                    Text(
                      '3 · Name & create',
                      key: const Key('builds_create_step_name'),
                      style: _sectionLabelStyle(context),
                    ),
                    const SizedBox(height: kSpace4),
                    TextField(
                      key: const Key('builds_create_name'),
                      controller: _createNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _create(),
                    ),
                    const SizedBox(height: kSpace12),
                    FilledButton(
                      key: const Key('builds_create_button'),
                      onPressed: _controller.loading ? null : _create,
                      child: const Text('Create build'),
                    ),
                    const SizedBox(height: kSpace4),
                    Text(
                      'Opens identity & variants in the detail pane.',
                      style: _bodyMutedStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Keep create pin fields mounted for tests even when form is collapsed.
        Offstage(
          offstage: true,
          child: Column(
            children: [
              TextField(
                key: const Key('builds_create_armor_hash'),
                controller: _createArmorHashController,
              ),
              TextField(
                key: const Key('builds_create_armor_name'),
                controller: _createArmorNameController,
              ),
              TextField(
                key: const Key('builds_create_weapon_hash'),
                controller: _createWeaponHashController,
              ),
              TextField(
                key: const Key('builds_create_weapon_name'),
                controller: _createWeaponNameController,
              ),
              TextField(
                key: const Key('builds_create_pinned_super'),
                controller: _createPinnedSuperController,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const FlapBoardHeader(template: kFlapColumnsBuilds),
        const Divider(height: 1),
        Expanded(child: _buildBuildList()),
      ],
    );
  }

  Widget _buildBuildList() {
    if (_controller.loading && _controller.builds.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('builds_loading')),
      );
    }
    if (_controller.builds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No builds yet. Create one above.',
            key: Key('builds_list_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('builds_list'),
      itemCount: _controller.builds.length,
      itemBuilder: (context, index) {
        final b = _controller.builds[index];
        final selected = _controller.selected?.build.id == b.id;
        final identity = _controller.identitySummaryOf(b);
        final synergy = _controller.synergySummaryOf(b);
        final exotics = _controller.exoticsSummaryOf(b);
        return FlapBoardRow(
          key: Key('builds_list_row_${b.id}'),
          template: kFlapColumnsBuilds,
          selected: selected,
          onTap: () => _controller.selectBuild(b.id),
          cells: [
            FlapTextCell(
              text: b.name,
              primary: true,
              textKey: Key('builds_list_name_${b.id}'),
            ),
            FlapInkCell(
              text: identity,
              elementHint: synergy,
              textKey: Key('builds_list_identity_${b.id}'),
            ),
            FlapInkCell(
              text: exotics,
              elementHint: synergy,
              asSeal: true,
            ),
            FlapInkCell(
              text: synergy.isEmpty ? '—' : synergy,
              elementHint: synergy,
              textKey: Key('builds_list_synergy_${b.id}'),
            ),
            const FlapTextCell(text: 'ok'),
          ],
        );
      },
    );
  }

}
