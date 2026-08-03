part of 'builds_library_page.dart';

extension _BuildsLibraryComposeSection on _BuildsLibraryPageState {
  Widget _buildVariantCompose(BuildContext context) {
    final variants = _controller.variants;
    final selectedVariant = _controller.selectedVariant;
    final sets = _controller.attachableSets;
    // Keep dropdown selection valid.
    final attachValue = (_attachSetId != null &&
            sets.any((s) => s.id == _attachSetId))
        ? _attachSetId
        : (sets.isNotEmpty ? sets.first.id : null);
    if (attachValue != _attachSetId) {
      // Defer assignment out of build via post-frame if needed; for tests ok:
      _attachSetId = attachValue;
    }

    return Column(
      key: const Key('builds_variant_compose'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VARIANTS',
          style: neonDisplay(
            color: FlapPalette.of(context).foreground,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'Select a variant, attach sets, pin slots.',
          style: neonBody(
            color: FlapPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: kSpace8),
        if (variants.isEmpty)
          const Text(
            'No variants on this build.',
            key: Key('builds_variants_empty'),
          )
        else
          Wrap(
            key: const Key('builds_variants_list'),
            spacing: kSpace8,
            runSpacing: kSpace8,
            children: [
              for (final v in variants)
                ChoiceChip(
                  key: Key('builds_variant_chip_${v.id}'),
                  label: Text(
                    v.isDefault ? '${v.name} (default)' : v.name,
                  ),
                  selected: selectedVariant?.id == v.id,
                  onSelected: (_) => _controller.selectVariant(v.id),
                ),
            ],
          ),
        const SizedBox(height: kSpace8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('builds_create_variant_name'),
                controller: _createVariantNameController,
                decoration: const InputDecoration(
                  labelText: 'New variant name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _createVariant(),
              ),
            ),
            const SizedBox(width: kSpace8),
            OutlinedButton(
              key: const Key('builds_create_variant_button'),
              onPressed: _controller.loading ? null : _createVariant,
              child: const Text('Create variant'),
            ),
          ],
        ),
        if (selectedVariant != null) ...[
          const SizedBox(height: kSpace16),
          Text(
            'SLOT STRIP',
            style: neonMono(
              color: FlapPalette.of(context).muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: kSpace4),
          Text(
            'Owned instance · Wish definition · Gap empty',
            style: neonBody(
              color: FlapPalette.of(context).muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: kSpace8),
          if (_controller.slotPins.isEmpty)
            const Text(
              'No filled slots yet.',
              key: Key('builds_variant_overview_empty'),
            )
          else
            Wrap(
              key: const Key('builds_variant_overview'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pin in _controller.slotPins)
                  Chip(
                    key: Key(
                      'builds_variant_overview_${pin.slot}_${pin.setId}',
                    ),
                    avatar: Icon(
                      pin.instanceId != null && pin.instanceId!.isNotEmpty
                          ? Icons.check_circle_outline
                          : Icons.bookmark_border,
                      size: 16,
                    ),
                    label: Text(
                      '${pin.slot}: ${pin.itemName} (${pin.pinDetail})',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (selectedVariant == null)
          const Text(
            'Select a variant to attach sets.',
            key: Key('builds_attach_no_variant'),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: sets.isEmpty
                    ? const Text(
                        'No library sets yet. Create sets in the Sets library.',
                        key: Key('builds_attach_no_sets'),
                      )
                    : DropdownButtonFormField<String>(
                        key: const Key('builds_attach_set_dropdown'),
                        // ignore: deprecated_member_use
                        value: attachValue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Library set',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final s in sets)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.type})'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _attachSetId = v),
                      ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('builds_attach_set_button'),
                onPressed: _controller.loading || sets.isEmpty
                    ? null
                    : _attachSelectedSet,
                child: const Text('Attach set'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_controller.attachments.isEmpty)
            const Text(
              'No sets attached.',
              key: Key('builds_attachments_empty'),
            )
          else
            Column(
              key: const Key('builds_attachments_list'),
              children: [
                for (final a in _controller.attachments)
                  ListTile(
                    key: Key('builds_attachment_${a.record.setId}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.summary),
                    trailing: IconButton(
                      key: Key('builds_detach_${a.record.setId}'),
                      tooltip: 'Detach',
                      icon: const Icon(Icons.link_off),
                      onPressed: _controller.loading
                          ? null
                          : () => _detachSet(a.record.setId),
                    ),
                  ),
              ],
            ),
        ],
        const SizedBox(height: kSpace16),
        Text(
          'Slot pins',
          style: _sectionLabelStyle(context),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'Wishlist = definition only; instance = owned copy pin.',
          style: _bodyMutedStyle(context),
        ),
        const SizedBox(height: kSpace8),
        if (_controller.slotPins.isEmpty)
          const Text(
            'No filled slots from attachments.',
            key: Key('builds_slot_pins_empty'),
          )
        else
          Column(
            key: const Key('builds_slot_pins_list'),
            children: [
              for (final pin in _controller.slotPins)
                Card(
                  key: Key('builds_slot_pin_${pin.slot}_${pin.setId}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pin.slot} · ${pin.itemName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Chip(
                              key: Key(
                                'builds_slot_pin_label_${pin.slot}_${pin.setId}',
                              ),
                              label: Text(pin.pinDetail),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (pin.canEditPin) ...[
                          const SizedBox(height: 8),
                          if (_pinTargetKey == '${pin.slot}|${pin.setId}')
                            TextField(
                              key: Key(
                                'builds_pin_instance_${pin.slot}_${pin.setId}',
                              ),
                              controller: _pinInstanceController,
                              decoration: const InputDecoration(
                                labelText: 'Instance id (empty = wishlist)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                key: Key(
                                  'builds_pin_edit_${pin.slot}_${pin.setId}',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _pinTargetKey = '${pin.slot}|${pin.setId}';
                                    _pinInstanceController.text =
                                        pin.instanceId ?? '';
                                  });
                                },
                                child: const Text('Edit pin'),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              OutlinedButton(
                                key: Key(
                                  'builds_pin_apply_${pin.slot}_${pin.setId}',
                                ),
                                onPressed: _controller.loading
                                    ? null
                                    : () => _applyPin(pin),
                                child: const Text('Pin'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                key: Key(
                                  'builds_pin_clear_${pin.slot}_${pin.setId}',
                                ),
                                onPressed: _controller.loading
                                    ? null
                                    : () => _clearPin(pin),
                                child: const Text('Wishlist'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        if (_controller.selectedVariant != null) ...[
          _buildFinishGaps(context),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          EquipPanel(
            key: const Key('builds_equip_panel'),
            controller: _equipController,
            finishComplete: _controller.finishComplete,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          DimExportPanel(
            key: const Key('builds_dim_export_panel'),
            controller: _dimExportController,
            finishComplete: _controller.finishComplete,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
        ],
        _buildSoftGuidance(context),
      ],
    );
  }

  Widget _buildFinishGaps(BuildContext context) {
    final gaps = _controller.finishGaps;
    final activeGap = _controller.finishActiveGap;
    final step = _controller.finishStep;
    return Column(
      key: const Key('builds_finish_gaps_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'FINISH READINESS',
          style: neonDisplay(
            color: FlapPalette.of(context).foreground,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'One status · equip + export share it · soft never blocks',
          style: neonBody(
            color: FlapPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
        ListTile(
          key: const Key('finish_policy_toggle'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            _finishPolicyExpanded
                ? 'Hide how finish works'
                : 'How finish works',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          trailing: Icon(
            _finishPolicyExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() => _finishPolicyExpanded = !_finishPolicyExpanded);
          },
        ),
        if (_finishPolicyExpanded) ...[
          Text(
            kFinishGapsPolicyCaption,
            key: const Key('finish_gaps_policy'),
            style: _bodyMutedStyle(context),
          ),
          const SizedBox(height: kSpace4),
          Text(
            kFinishWalkthroughCaption,
            key: const Key('finish_walkthrough_caption'),
            style: _bodyMutedStyle(context),
          ),
          const SizedBox(height: kSpace8),
        ],
        if (gaps == null)
          const Text(
            'Select a variant to evaluate finish gaps.',
            key: Key('finish_gaps_empty'),
          )
        else ...[
          Text(
            formatFinishGapsCompleteSummary(gaps),
            key: const Key('finish_gaps_complete_summary'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: gaps.complete
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (_controller.finishMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _controller.finishMessage!,
              key: const Key('finish_walkthrough_message'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            key: const Key('finish_category_chips'),
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final gap in gaps.gaps)
                ActionChip(
                  key: Key('finish_category_chip_${gap.category.wireName}'),
                  label: Text(
                    '${finishCategoryLabel(gap.category)}'
                    '${gap.status == FinishGapStatus.satisfied ? ' ✓' : ''}'
                    '${_controller.finishSkipped.contains(gap.category.wireName) ? ' · skip' : ''}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () => _controller.openFinishCategory(gap.category),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            key: const Key('finish_gaps_list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final gap in gaps.gaps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    formatFinishGapRowSummary(gap),
                    key: Key('finish_gap_${gap.category.wireName}'),
                  ),
                ),
            ],
          ),
          if (!gaps.complete &&
              (step == FinishWalkthroughStep.overview ||
                  step == FinishWalkthroughStep.category) &&
              activeGap != null) ...[
            const SizedBox(height: 12),
            Text(
              finishCategoryLabel(activeGap.category),
              key: const Key('finish_active_category_title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (activeGap.canCapture)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key(
                    'finish_capture_${activeGap.category.wireName}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () => _controller.captureCategory(activeGap.category),
                  child: Text(
                    'Capture ${finishCategoryLabel(activeGap.category)}',
                  ),
                ),
              ),
            if (showFinishCreateActions(activeGap.status))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  key: Key(
                    'finish_create_${activeGap.category.wireName}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () =>
                          _controller.oneTapCreateCategory(activeGap.category),
                  child: Text(
                    _controller.finishBusy
                        ? 'Creating…'
                        : 'Create ${finishCategoryLabel(activeGap.category)} set & fill',
                  ),
                ),
              ),
            if (activeGap.status == FinishGapStatus.needsFill &&
                activeGap.coveringSetId != null &&
                activeGap.coveringMode == AttachmentMode.live) ...[
              if (activeGap.category == FinishCategory.armor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    key: const Key('finish_armor_improve'),
                    onPressed: _controller.finishBusy
                        ? null
                        : _controller.openFinishArmorOptimize,
                    child: const Text('Improve armor (Find kits)'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: const Key('finish_fill_first_empty'),
                  onPressed: _controller.finishBusy ||
                          activeGap.emptySlots.isEmpty
                      ? null
                      : () async {
                          _controller.openFinishFillFirstEmpty();
                          await _runFinishFillDialog();
                        },
                  child: Text(
                    activeGap.emptySlots.isEmpty
                        ? 'No empty slots'
                        : 'Fill ${activeGap.emptySlots.first}',
                  ),
                ),
              ),
            ],
            if (activeGap.status == FinishGapStatus.needsFill &&
                activeGap.coveringMode == AttachmentMode.snapshot)
              Text(
                'Covering Set is snapshot-only. Create a live Set from Finish '
                'to fill slots.',
                key: const Key('finish_snapshot_fill_blocked'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            Row(
              children: [
                TextButton(
                  key: Key('finish_skip_${activeGap.category.wireName}'),
                  onPressed: () =>
                      _controller.skipFinishCategory(activeGap.category),
                  child: const Text('Skip for now'),
                ),
                TextButton(
                  key: const Key('finish_back_overview'),
                  onPressed: _controller.backToFinishOverview,
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
          if (step == FinishWalkthroughStep.armorOptimize &&
              activeGap?.coveringSetId != null &&
              activeGap!.category == FinishCategory.armor) ...[
            const SizedBox(height: 12),
            _FinishArmorOptimizeEmbed(
              key: const Key('finish_armor_optimize_workspace'),
              services: widget.services,
              setId: activeGap.coveringSetId!,
              setName: activeGap.coveringSetName ?? activeGap.coveringSetId!,
              resolveUserId: _controller.resolveLibraryUserId,
              onApplied: () async {
                await _controller.afterFinishArmorApplied();
              },
              onManualFill: () async {
                _controller.openFinishFillFirstEmpty();
                await _runFinishFillDialog();
              },
              onBack: () {
                _controller.openFinishCategory(FinishCategory.armor);
              },
            ),
          ],
          if (step == FinishWalkthroughStep.fill &&
              activeGap?.coveringSetId != null &&
              _controller.finishFillSlot != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('finish_fill_dialog_reopen'),
              onPressed: _runFinishFillDialog,
              child: Text('Pick item for ${_controller.finishFillSlot}'),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _runFinishFillDialog() async {
    final gap = _controller.finishActiveGap;
    if (gap == null || gap.coveringSetId == null) return;
    final slot = _controller.finishFillSlot ?? firstEmptyRequiredSlot(gap);
    if (slot == null) return;
    if (gap.coveringMode != AttachmentMode.live) return;

    final pick = await showSetCatalogPicker(
      context: context,
      services: widget.services,
      targetSlot: slot,
    );
    if (pick == null || !mounted) return;
    final err = await _controller.fillFinishSlot(
      setId: gap.coveringSetId!,
      slot: slot,
      itemHash: pick.itemHash,
      itemName: pick.itemName,
      instanceId: pick.instanceId,
      selectedPerks: pick.selectedPerks,
      isExotic: pick.isExotic,
      equipmentSlot: pick.equipmentSlot,
      catalogKind: pick.catalogKind,
    );
    if (err != null && mounted) {
      setState(() => _statusMessage = err);
    }
  }

  Widget _buildSoftGuidance(BuildContext context) {
    final synergyRows = _controller.synergyCoverageRows;
    final setBonuses = _controller.setBonusSoftRows;
    final elements = _controller.elementSoftMismatches;
    final softStats = _controller.softStatWarnings;

    return Column(
      key: const Key('builds_soft_guidance'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Soft guidance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _controller.softGuidanceAdvisory,
          key: const Key('builds_soft_guidance_advisory'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Coverage chips',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_controller.selectedVariant == null)
          const Text(
            'Select a variant to evaluate soft coverage.',
            key: Key('builds_soft_coverage_no_variant'),
          )
        else if (synergyRows.isEmpty)
          const Text(
            'No designated synergy coverage rows (add library synergies matching build types).',
            key: Key('builds_soft_coverage_empty'),
          )
        else
          Wrap(
            key: const Key('builds_soft_coverage_chips'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final row in synergyRows)
                Chip(
                  key: Key(
                    'builds_soft_chip_${row.synergyId}_${row.tier.wireName}',
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: flapToneColor(
                      context,
                      coverageTierToneKey(row.tier),
                    ),
                    radius: 6,
                  ),
                  label: Text(formatSynergyCoverageChipLabel(row)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (setBonuses.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Set-bonus soft',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_set_bonuses'),
            children: [
              for (var i = 0; i < setBonuses.length; i++)
                ListTile(
                  key: Key('builds_soft_set_bonus_$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatSetBonusSoftSummary(setBonuses[i])),
                  subtitle: setBonuses[i].hint != null
                      ? Text(setBonuses[i].hint!)
                      : null,
                ),
            ],
          ),
        ],
        if (elements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Element soft mismatches',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_element_mismatches'),
            children: [
              for (var i = 0; i < elements.length; i++)
                ListTile(
                  key: Key('builds_soft_element_$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatElementSoftMismatchSummary(elements[i])),
                  subtitle: Text(elements[i].hint),
                ),
            ],
          ),
        ],
        if (softStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Soft stat warnings',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_stat_warnings'),
            children: [
              for (final row in softStats)
                ListTile(
                  key: Key('builds_soft_stat_warn_${row.stat.wireName}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatSoftStatWarningSummary(row)),
                  subtitle: Text(row.hint),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Soft stat targets',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Explicit save only — coverage never writes targets.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('builds_soft_stat_targets_fields'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stat in ArmorStatName.all)
              SizedBox(
                width: 120,
                child: TextField(
                  key: Key('builds_soft_stat_${stat.wireName}'),
                  controller: _softStatControllers[stat],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: stat.wireName,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: '1–$armorStatMax',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('builds_soft_stat_save'),
            onPressed: _controller.loading || _controller.selected == null
                ? null
                : _saveSoftStatTargets,
            child: const Text('Save soft targets'),
          ),
        ),
        if (_controller.softStatTargetsSummary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Saved: ${_controller.softStatTargetsSummary}',
            key: const Key('builds_soft_stat_saved_summary'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _saveSoftStatTargets() async {
    final fields = <String, String>{
      for (final stat in ArmorStatName.all)
        stat.wireName: _softStatControllers[stat]!.text,
    };
    final err = await _controller.saveSoftStatTargetsFromFields(fields);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved soft stat targets';
      if (err == null) {
        _boundSoftTargetsKey = null;
        _syncSoftStatFieldsFromController();
      }
    });
  }

  Future<void> _createVariant() async {
    final err = await _controller.createVariant(
      name: _createVariantNameController.text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ??
          'Created variant ${_createVariantNameController.text.trim()}';
      if (err == null) _createVariantNameController.clear();
    });
  }

  Future<void> _attachSelectedSet() async {
    final id = _attachSetId;
    if (id == null) {
      setState(() => _statusMessage = 'Pick a set to attach');
      return;
    }
    final err = await _controller.attachSet(id);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Attached set';
    });
  }

  Future<void> _detachSet(String setId) async {
    final err = await _controller.detachSet(setId);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Detached set';
    });
  }

  Future<void> _applyPin(SlotPinView pin) async {
    final key = '${pin.slot}|${pin.setId}';
    final text = _pinTargetKey == key
        ? _pinInstanceController.text
        : (pin.instanceId ?? '');
    final err = await _controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      setItemId: pin.setItemId,
      instanceId: text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Pinned ${pin.slot}';
      _pinTargetKey = null;
    });
  }

  Future<void> _clearPin(SlotPinView pin) async {
    final err = await _controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      setItemId: pin.setItemId,
      instanceId: null,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Cleared pin on ${pin.slot} (wishlist)';
      _pinTargetKey = null;
      _pinInstanceController.clear();
    });
  }
}
