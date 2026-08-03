part of 'builds_library_page.dart';

extension _BuildsLibraryDetailSection on _BuildsLibraryPageState {
  Widget _buildDetail(BuildContext context) {
    final sel = _controller.selected;
    if (sel == null) {
      return LibraryDetailEmpty(
        key: const Key('builds_detail_empty'),
        icon: Icons.construction_outlined,
        title: 'No build selected',
        body: _controller.builds.isEmpty
            ? 'Expand New build on the left, pick class + synergy, then Create build. Identity, variants, and finish gaps open here next.'
            : 'Select a build on the board to edit identity, attach sets, and advance finish gaps.',
      );
    }
    final b = sel.build;
    final palette = FlapPalette.of(context);
    final synergyText = _controller.synergySummaryOf(b);
    final displayName = _editNameController.text.trim().isNotEmpty
        ? _editNameController.text.trim()
        : (b.name.trim().isNotEmpty ? b.name.trim() : 'Untitled build');
    final finish = _controller.finishGaps;
    final finishLabel = finish == null
        ? 'Finish · —'
        : (finish.complete
            ? 'Finish · complete'
            : 'Finish · ${finish.nextActionable?.category.wireName ?? 'gaps'}');

    // docs/ui-mocks/build-basics.html — loadout console: topbar · steps · zones.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final identityColumn = _buildIdentityZone(context);
        final loadoutColumn = NeonZone(
          key: const Key('builds_zone_loadout'),
          padding: const EdgeInsets.all(kSpace12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _zoneHead(
                context,
                title: 'Loadout pins',
                sub: 'Instance = owned · Wish = definition only',
              ),
              const SizedBox(height: kSpace12),
              _buildVariantCompose(context),
            ],
          ),
        );

        final body = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 9, child: identityColumn),
                  const SizedBox(width: kSpace12),
                  Expanded(flex: 14, child: loadoutColumn),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identityColumn,
                  const SizedBox(height: kSpace12),
                  loadoutColumn,
                ],
              );

        return SingleChildScrollView(
          key: const Key('builds_detail'),
          padding: const EdgeInsets.fromLTRB(kSpace12, kSpace8, kSpace12, kSpace16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Topbar (mock .topbar) ---
              NeonZone(
                padding: const EdgeInsets.fromLTRB(
                  kSpace12,
                  kSpace10,
                  kSpace12,
                  kSpace12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName.toUpperCase(),
                                key: const Key('builds_detail_title'),
                                style: neonDisplay(
                                  color: palette.foreground,
                                  fontSize: 15,
                                  letterSpacing: 0.06 * 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: kSpace8),
                              Text(
                                'What this build is — class, synergy, optional pins.',
                                key: const Key('builds_identity_summary_label'),
                                style: neonBody(
                                  color: palette.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: kSpace8),
                              Wrap(
                                spacing: kSpace6,
                                runSpacing: kSpace6,
                                children: [
                                  KeyedSubtree(
                                    key: const Key('builds_detail_class'),
                                    child: NeonMetaPill(
                                      b.className,
                                      tone: NeonPillTone.accent,
                                    ),
                                  ),
                                  KeyedSubtree(
                                    key: const Key('builds_detail_synergy_types'),
                                    child: NeonMetaPill(
                                      synergyText.isEmpty
                                          ? '(no synergy)'
                                          : synergyText,
                                    ),
                                  ),
                                  if (b.pinnedSuper != null &&
                                      b.pinnedSuper!.trim().isNotEmpty)
                                    KeyedSubtree(
                                      key: const Key(
                                        'builds_detail_pinned_super',
                                      ),
                                      child: NeonMetaPill(
                                        'Super: ${b.pinnedSuper}',
                                      ),
                                    ),
                                  if (b.exoticArmorName != null ||
                                      b.exoticArmorHash != null)
                                    KeyedSubtree(
                                      key: const Key(
                                        'builds_detail_exotic_armor',
                                      ),
                                      child: NeonMetaPill(
                                        b.exoticArmorName ??
                                            'Armor ${b.exoticArmorHash}',
                                        tone: NeonPillTone.exotic,
                                      ),
                                    ),
                                  if (b.exoticWeaponName != null ||
                                      b.exoticWeaponHash != null)
                                    KeyedSubtree(
                                      key: const Key(
                                        'builds_detail_exotic_weapon',
                                      ),
                                      child: NeonMetaPill(
                                        b.exoticWeaponName ??
                                            'Weapon ${b.exoticWeaponHash}',
                                        tone: NeonPillTone.exotic,
                                      ),
                                    ),
                                  NeonMetaPill(
                                    finishLabel,
                                    tone: finish?.complete == true
                                        ? NeonPillTone.ok
                                        : NeonPillTone.warn,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: kSpace8),
                        FilledButton(
                          key: const Key('builds_save_identity'),
                          onPressed: _controller.loading ||
                                  _controller.identitySaveHardBlocked ||
                                  _controller.identityConfirmRequired
                              ? null
                              : () => _saveIdentity(),
                          child: const Text('Save identity'),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSpace4),
                    Text(
                      'Soft coverage never blocks Save. Hard Destiny limits still do.',
                      key: const Key('builds_save_identity_hint'),
                      style: neonBody(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpace12),
              // --- Step rail (mock .steps) ---
              Text(
                '1 Identity → 2 Loadout → 3 Finish readiness → 4 Variants',
                key: const Key('builds_identity_next_step'),
                style: neonMono(
                  color: palette.muted,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: kSpace8),
              NeonSegmentedTabs(
                dense: true,
                selectedId: '$_buildDetailStep',
                onSelected: (id) {
                  final step = int.tryParse(id) ?? 1;
                  setState(() {
                    _buildDetailStep = step;
                    if (step == 1) {
                      // keep identity open
                    } else if (step == 2) {
                      _optionalPinsExpanded = true;
                    } else if (step == 4) {
                      // compose is always below
                    }
                  });
                },
                options: const [
                  NeonSegmentOption(id: '1', label: '1 Identity'),
                  NeonSegmentOption(id: '2', label: '2 Loadout'),
                  NeonSegmentOption(id: '3', label: '3 Finish'),
                  NeonSegmentOption(id: '4', label: '4 Variants'),
                ],
              ),
              const SizedBox(height: kSpace12),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _zoneHead(
    BuildContext context, {
    required String title,
    required String sub,
  }) {
    final palette = FlapPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: neonDisplay(
              color: palette.foreground,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Text(
          sub.toUpperCase(),
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  /// Identity zone — name, synergy, optional pins, kit, save hard-blocks.
  Widget _buildIdentityZone(BuildContext context) {
    final palette = FlapPalette.of(context);
    return NeonZone(
      key: const Key('builds_zone_identity'),
      padding: const EdgeInsets.all(kSpace12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _zoneHead(
            context,
            title: 'Identity',
            sub: 'Required before clean save',
          ),
          const SizedBox(height: kSpace12),
          Text(
            'NAME',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: kSpace4),
          TextField(
            key: const Key('builds_edit_name'),
            controller: _editNameController,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: kSpace12),
          Text(
            'SYNERGY TYPES',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: kSpace6),
          if (_controller.editDraftTypes.isEmpty)
            const Text(
              'No synergy types (required before save).',
              key: Key('builds_edit_synergy_empty'),
            )
          else
            Wrap(
              key: const Key('builds_edit_synergy_chips'),
              spacing: kSpace4,
              runSpacing: kSpace4,
              children: [
                for (var i = 0; i < _controller.editDraftTypes.length; i++)
                  InputChip(
                    key: Key('builds_edit_synergy_chip_$i'),
                    label: Text(
                      displaySynergyDraft(
                        _controller.editDraftTypes[i].type,
                        _controller.editDraftTypes[i].subType,
                      ),
                    ),
                    onDeleted: () => _controller.removeEditDraftTypeAt(i),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          const SizedBox(height: kSpace6),
          if (!_synergyAddExpanded)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('builds_edit_add_synergy_open'),
                onPressed: () => setState(() => _synergyAddExpanded = true),
                child: const Text('+ Add type'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('builds_edit_synergy_type'),
                    // ignore: deprecated_member_use
                    value: _editTypeWire,
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
                      setState(() => _editTypeWire = v);
                    },
                  ),
                ),
                const SizedBox(width: kSpace8),
                Expanded(
                  child: TextField(
                    key: const Key('builds_edit_synergy_subtype'),
                    controller: _editSubTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Subtype',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: kSpace8),
                OutlinedButton(
                  key: const Key('builds_edit_add_synergy'),
                  onPressed: () {
                    _controller.addEditDraftType(
                      _editTypeWire,
                      _editSubTypeController.text,
                    );
                    _editSubTypeController.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          if (!_synergyAddExpanded)
            Offstage(
              offstage: true,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('builds_edit_synergy_type'),
                    // ignore: deprecated_member_use
                    value: _editTypeWire,
                    items: [
                      for (final t in creatableSynergyTypeWires)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (_) {},
                  ),
                  TextField(
                    key: const Key('builds_edit_synergy_subtype'),
                    controller: _editSubTypeController,
                  ),
                  OutlinedButton(
                    key: const Key('builds_edit_add_synergy'),
                    onPressed: () {},
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: kSpace12),
          _buildOptionalPinsSection(context),
          const SizedBox(height: kSpace8),
          _buildSubclassKitSection(context),
          if (_controller.composeHardBlocks.isNotEmpty) ...[
            const SizedBox(height: kSpace12),
            Container(
              key: const Key('builds_hard_blocks'),
              padding: const EdgeInsets.all(kPanelPadSm),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final block in _controller.composeHardBlocks)
                    Text(
                      '${block.code}: ${block.message}',
                      key: Key('builds_hard_block_${block.code}'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_controller.identityConfirmRequired) ...[
            const SizedBox(height: kSpace12),
            Container(
              key: const Key('builds_identity_confirm_panel'),
              padding: const EdgeInsets.all(kPanelPadSm),
              decoration: BoxDecoration(
                border: Border.all(color: palette.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Identity change requires Confirm (in-place) or Fork (new build). '
                    'Fields: ${_controller.pendingIdentityFields?.join(', ')}',
                    key: const Key('builds_identity_confirm_message'),
                  ),
                  const SizedBox(height: kSpace8),
                  Wrap(
                    spacing: kSpace8,
                    runSpacing: kSpace8,
                    children: [
                      FilledButton(
                        key: const Key('builds_identity_confirm'),
                        onPressed: _controller.loading ||
                                _controller.identitySaveHardBlocked
                            ? null
                            : () => _saveIdentity(
                                  identityAction: IdentityAction.confirm,
                                ),
                        child: const Text('Confirm in-place'),
                      ),
                      OutlinedButton(
                        key: const Key('builds_identity_fork'),
                        onPressed: _controller.loading
                            ? null
                            : () => _saveIdentity(
                                  identityAction: IdentityAction.fork,
                                ),
                        child: const Text('Fork as new build'),
                      ),
                      TextButton(
                        key: const Key('builds_identity_cancel'),
                        onPressed: () {
                          _controller.cancelIdentityConfirm();
                          setState(() {
                            _boundSelectionId = null;
                            _statusMessage = 'Identity change cancelled';
                            _onController();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _optionalPinsSummary {
    final parts = <String>[];
    final armor = _editArmorNameController.text.trim();
    final weapon = _editWeaponNameController.text.trim();
    final superName = _editPinnedSuperController.text.trim();
    if (armor.isNotEmpty) parts.add(armor);
    if (weapon.isNotEmpty) parts.add(weapon);
    if (superName.isNotEmpty) parts.add(superName);
    if (parts.isEmpty) return 'None yet — expand to pin exotic armor, weapon, or Super';
    return parts.join(' · ');
  }

  String get _subclassKitSummary {
    final kit = _controller.editSubclass;
    if (kit.aspects.isEmpty && kit.fragments.isEmpty) {
      return 'None yet — expand to add aspects/fragments';
    }
    final a = kit.aspects.isEmpty ? '0 aspects' : '${kit.aspects.length} aspects';
    final f =
        kit.fragments.isEmpty ? '0 fragments' : '${kit.fragments.length} fragments';
    return '$a · $f';
  }

  Widget _buildOptionalPinsBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('builds_edit_armor_name'),
                controller: _editArmorNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Exotic armor',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: kSpace8),
            OutlinedButton(
              key: const Key('builds_pick_exotic_armor'),
              onPressed: () => _openManifestPick(
                kind: ManifestPickKind.exoticArmor,
                onPick: (p) {
                  setState(() {
                    _editArmorHashController.text = '${p.hash}';
                    _editArmorNameController.text = p.name;
                    _optionalPinsExpanded = true;
                  });
                },
              ),
              child: const Text('Search'),
            ),
            IconButton(
              key: const Key('builds_clear_exotic_armor'),
              tooltip: 'Clear exotic armor',
              onPressed: () {
                setState(() {
                  _editArmorHashController.clear();
                  _editArmorNameController.clear();
                });
              },
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
        Offstage(
          offstage: true,
          child: TextField(
            key: const Key('builds_edit_armor_hash'),
            controller: _editArmorHashController,
          ),
        ),
        const SizedBox(height: kSpace8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('builds_edit_weapon_name'),
                controller: _editWeaponNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Exotic weapon (optional)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: kSpace8),
            OutlinedButton(
              key: const Key('builds_pick_exotic_weapon'),
              onPressed: () => _openManifestPick(
                kind: ManifestPickKind.exoticWeapon,
                onPick: (p) {
                  setState(() {
                    _editWeaponHashController.text = '${p.hash}';
                    _editWeaponNameController.text = p.name;
                    _optionalPinsExpanded = true;
                  });
                },
              ),
              child: const Text('Search'),
            ),
          ],
        ),
        Offstage(
          offstage: true,
          child: TextField(
            key: const Key('builds_edit_weapon_hash'),
            controller: _editWeaponHashController,
          ),
        ),
        const SizedBox(height: kSpace8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('builds_edit_pinned_super'),
                controller: _editPinnedSuperController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Pinned Super',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: kSpace8),
            OutlinedButton(
              key: const Key('builds_pick_super'),
              onPressed: () => _openManifestPick(
                kind: ManifestPickKind.superAbility,
                onPick: (p) {
                  setState(() {
                    _editPinnedSuperController.text = p.name;
                    _optionalPinsExpanded = true;
                  });
                },
              ),
              child: const Text('Search'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionalPinsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            key: const Key('builds_optional_pins_toggle'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              '2 · Optional pins',
              style: _sectionTitleStyle(context),
            ),
            subtitle: Text(
              _optionalPinsSummary,
              key: const Key('builds_optional_pins_summary'),
              style: _bodyMutedStyle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              _optionalPinsExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () =>
                setState(() => _optionalPinsExpanded = !_optionalPinsExpanded),
          ),
        ),
        if (_optionalPinsExpanded) _buildOptionalPinsBody(context),
        // Always mount pick/field keys for tests and controller wiring.
        if (!_optionalPinsExpanded)
          Offstage(offstage: true, child: _buildOptionalPinsBody(context)),
      ],
    );
  }

  Widget _buildSubclassKitBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _controller.subclassCapacityCaption,
          key: const Key('builds_subclass_capacity'),
          style: _bodyMutedStyle(context),
        ),
        const SizedBox(height: kSpace8),
        Text(
          'Aspects: ${_controller.editSubclass.aspects.isEmpty ? '(none)' : _controller.editSubclass.aspects.join(', ')}',
          key: const Key('builds_subclass_aspects'),
        ),
        const SizedBox(height: kSpace6),
        Wrap(
          spacing: kSpace8,
          runSpacing: kSpace8,
          children: [
            OutlinedButton(
              key: const Key('builds_pick_aspect'),
              onPressed: () => _openManifestPick(
                kind: ManifestPickKind.aspect,
                onPick: (p) {
                  final kit = _controller.editSubclass;
                  final next = [
                    ...kit.aspects.where((a) => a != p.name),
                    p.name,
                  ];
                  _controller.setEditSubclass(
                    SubclassKit(
                      aspects: next,
                      fragments: kit.fragments,
                      superAbility: kit.superAbility,
                      melee: kit.melee,
                      grenade: kit.grenade,
                      classAbility: kit.classAbility,
                      name: kit.name,
                    ),
                  );
                  setState(() => _subclassKitExpanded = true);
                },
              ),
              child: const Text('Add aspect'),
            ),
            OutlinedButton(
              key: const Key('builds_pick_fragment'),
              onPressed: () => _openManifestPick(
                kind: ManifestPickKind.fragment,
                onPick: (p) {
                  final kit = _controller.editSubclass;
                  final next = [
                    ...kit.fragments.where((a) => a != p.name),
                    p.name,
                  ];
                  _controller.setEditSubclass(
                    SubclassKit(
                      aspects: kit.aspects,
                      fragments: next,
                      superAbility: kit.superAbility,
                      melee: kit.melee,
                      grenade: kit.grenade,
                      classAbility: kit.classAbility,
                      name: kit.name,
                    ),
                  );
                  setState(() => _subclassKitExpanded = true);
                },
              ),
              child: const Text('Add fragment'),
            ),
            TextButton(
              key: const Key('builds_clear_kit_pieces'),
              onPressed: () {
                _controller.setEditSubclass(
                  SubclassKit(
                    superAbility: _controller.editSubclass.superAbility,
                    melee: _controller.editSubclass.melee,
                    grenade: _controller.editSubclass.grenade,
                    classAbility: _controller.editSubclass.classAbility,
                    name: _controller.editSubclass.name,
                  ),
                );
              },
              child: const Text('Clear aspects/fragments'),
            ),
          ],
        ),
        const SizedBox(height: kSpace6),
        Text(
          'Fragments: ${_controller.editSubclass.fragments.isEmpty ? '(none)' : _controller.editSubclass.fragments.join(', ')}',
          key: const Key('builds_subclass_fragments'),
        ),
      ],
    );
  }

  Widget _buildSubclassKitSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            key: const Key('builds_subclass_kit_toggle'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              '2 · Subclass kit',
              key: const Key('builds_subclass_kit_title'),
              style: _sectionTitleStyle(context),
            ),
            subtitle: Text(
              _subclassKitSummary,
              key: const Key('builds_subclass_kit_summary'),
              style: _bodyMutedStyle(context),
            ),
            trailing: Icon(
              _subclassKitExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () =>
                setState(() => _subclassKitExpanded = !_subclassKitExpanded),
          ),
        ),
        if (_subclassKitExpanded) _buildSubclassKitBody(context),
        if (!_subclassKitExpanded)
          Offstage(offstage: true, child: _buildSubclassKitBody(context)),
      ],
    );
  }

}
