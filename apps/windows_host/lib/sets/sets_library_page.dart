import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    show ArmorSetStatTotals, SetItemRecord, armorBaseStatKeys;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../catalog/owned_catalog_bridge.dart';
import '../host_bootstrap.dart';
import '../optimizer/optimizer_controller.dart';
import '../optimizer/optimizer_workspace.dart';
import 'set_catalog_picker.dart';
import 'set_item_enrichment.dart';
import 'set_slot_mapping.dart';
import 'sets_library_controller.dart';

/// Sets library dual-pane (list + detail/slots) — DART-030/036 + dense board (DART-065).
class SetsLibraryPage extends StatefulWidget {
  const SetsLibraryPage({
    super.key,
    required this.services,
    this.controller,
    this.optimizerController,
    this.bridge,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final SetsLibraryController? controller;

  /// Optional injectable optimizer controller (tests inject candidates / local runner).
  final OptimizerController? optimizerController;

  /// Optional catalog bridge for enrichment (tests).
  final OwnedCatalogBridge? bridge;

  @override
  State<SetsLibraryPage> createState() => _SetsLibraryPageState();
}

class _SetsLibraryPageState extends State<SetsLibraryPage> {
  late final SetsLibraryController _controller;
  late final OptimizerController _optimizer;
  late final OwnedCatalogBridge _bridge;
  final _nameController = TextEditingController();
  final _editNameController = TextEditingController();
  final _searchController = TextEditingController();
  SetType _createType = SetType.weapon;
  String? _statusMessage;
  bool _ownController = false;
  bool _ownOptimizer = false;
  String? _boundOptimizerSetId;
  SetDetailPresentation? _presentation;
  bool _enriching = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownController = true;
      _controller = SetsLibraryController(
        db: widget.services.db,
        session: widget.services.oauthSession,
        inventorySync: widget.services.inventorySync,
      );
    }
    if (widget.optimizerController != null) {
      _optimizer = widget.optimizerController!;
    } else {
      _ownOptimizer = true;
      _optimizer = OptimizerController(
        db: widget.services.db,
        resolveUserId: () => _controller.resolveLibraryUserId(),
      );
    }
    _bridge = widget.bridge ??
        OwnedCatalogBridge(
          db: widget.services.db,
          offlineCatalog: widget.services.offlineCatalog,
          session: widget.services.oauthSession,
          inventorySync: widget.services.inventorySync,
        );
    _controller.addListener(_onController);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    if (_ownController) {
      _controller.dispose();
    }
    if (_ownOptimizer) {
      _optimizer.dispose();
    }
    _nameController.dispose();
    _editNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final sel = _controller.selected;
    if (sel == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('sets_delete_confirm_dialog'),
        title: const Text('Delete set?'),
        content: Text(
          'Delete "${sel.set.name}"? This cannot be undone.',
          key: const Key('sets_delete_confirm_message'),
        ),
        actions: [
          TextButton(
            key: const Key('sets_delete_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('sets_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await _controller.deleteSelected();
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Set deleted';
    });
  }

  void _onController() {
    final sel = _controller.selected;
    if (sel != null && _editNameController.text != sel.set.name) {
      _editNameController.text = sel.set.name;
    }
    _syncOptimizerTarget(sel);
    _scheduleEnrichment();
    if (mounted) setState(() {});
  }

  void _scheduleEnrichment() {
    final sel = _controller.selected;
    if (sel == null) {
      _presentation = null;
      return;
    }
    if (_enriching) return;
    _enriching = true;
    final setType = SetType.tryParse(sel.set.type) ?? SetType.weapon;
    final slots = slotsForSetType(setType);
    enrichSetDetailPresentation(
      detail: sel,
      bridge: _bridge,
      boardSlots: slots,
      userId: _controller.userId,
    ).then((p) {
      if (!mounted) return;
      setState(() {
        _presentation = p;
        _enriching = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _presentation = null;
        _enriching = false;
      });
    });
  }

  void _syncOptimizerTarget(SetDetail? sel) {
    if (sel == null || sel.set.type != SetType.armor.wireName) {
      if (_boundOptimizerSetId != null) {
        _boundOptimizerSetId = null;
        _optimizer.clearTargetSet();
      }
      return;
    }
    if (_boundOptimizerSetId == sel.set.id) return;
    _boundOptimizerSetId = sel.set.id;
    _optimizer.bindTargetSet(setId: sel.set.id, setName: sel.set.name);
  }

  Future<void> _create() async {
    final err = await _controller.createSet(
      name: _nameController.text,
      type: _createType,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Created ${_nameController.text.trim()}';
      if (err == null) _nameController.clear();
    });
  }

  Future<void> _saveName() async {
    final err = await _controller.updateSelected(name: _editNameController.text);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved';
    });
  }

  Future<void> _fillSlot(String slot) async {
    final pick = await showSetCatalogPicker(
      context: context,
      services: widget.services,
      targetSlot: slot,
      bridge: _bridge,
    );
    if (pick == null || !mounted) return;

    if (_controller.needsReplaceConfirm(slot)) {
      final occupant = _controller.occupantForSlot(slot);
      final name = occupant?.itemName ?? 'current item';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('sets_replace_confirm_dialog'),
          title: const Text('Replace item?'),
          content: Text(
            'Replace "$name" in this slot?',
            key: const Key('sets_replace_confirm_message'),
          ),
          actions: [
            TextButton(
              key: const Key('sets_replace_cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('sets_replace_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) {
        setState(() => _statusMessage = 'Replace cancelled');
        return;
      }
    }

    final err = await _controller.fillSlot(slot, pick);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Filled ${setSlotDisplayLabel(slot)}';
    });
  }

  Future<void> _clearSlot(String slot) async {
    final err = await _controller.clearSlot(slot);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Cleared ${setSlotDisplayLabel(slot)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sets'),
        actions: [
          IconButton(
            key: const Key('sets_reload'),
            tooltip: 'Reload library',
            onPressed: _controller.loading ? null : () => _controller.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_statusMessage != null || _controller.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _controller.error ?? _statusMessage!,
                key: const Key('sets_status'),
                style: TextStyle(
                  color: _controller.error != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          Expanded(
            child: LibraryWorkspace(
              rail: _buildRail(context),
              detail: _buildDetail(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Library',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            key: const Key('sets_create_name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'New set name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _create(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: DropdownButtonFormField<SetType>(
            key: const Key('sets_create_type'),
            // ignore: deprecated_member_use
            value: _createType,
            decoration: const InputDecoration(
              labelText: 'Type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in SetType.values)
                DropdownMenuItem(
                  value: t,
                  child: Text(t.wireName),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _createType = v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: FilledButton(
            key: const Key('sets_create_button'),
            onPressed: _controller.loading ? null : _create,
            child: const Text('Create set'),
          ),
        ),
        const Divider(height: 1),
        const FlapBoardHeader(template: kFlapColumnsSets),
        const Divider(height: 1),
        Expanded(child: _buildSetList()),
      ],
    );
  }

  Widget _buildSetsFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('sets_search'),
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: _controller.setSearchQuery,
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<SetType?>(
            key: const Key('sets_type_filters'),
            // ignore: deprecated_member_use
            value: _controller.typeFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<SetType?>(
                value: null,
                child: Text('All types', key: Key('sets_type_chip_all')),
              ),
              for (final t in SetType.values)
                DropdownMenuItem<SetType?>(
                  value: t,
                  child: Text(
                    t.wireName,
                    key: Key('sets_type_chip_${t.wireName}'),
                  ),
                ),
            ],
            onChanged: _controller.setTypeFilter,
          ),
          const SizedBox(height: 4),
          Wrap(
            key: const Key('sets_tag_filters'),
            spacing: 4,
            children: [
              for (final tag in const ['pve', 'pvp', 'solar'])
                FilterChip(
                  key: Key('sets_tag_chip_$tag'),
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  selected: _controller.tagFilters.contains(tag),
                  onSelected: (_) => _controller.toggleTagFilter(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetList() {
    if (_controller.loading && _controller.sets.isEmpty) {
      return ListView(
        key: const Key('sets_list'),
        children: [
          _buildSetsFilterHeader(),
          const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(key: Key('sets_loading')),
            ),
          ),
        ],
      );
    }
    if (_controller.sets.isEmpty) {
      return ListView(
        key: const Key('sets_list'),
        children: [
          _buildSetsFilterHeader(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No sets yet. Create one above.',
              key: Key('sets_list_empty'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      key: const Key('sets_list'),
      itemCount: _controller.sets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildSetsFilterHeader();
        final set = _controller.sets[index - 1];
        final selected = _controller.selected?.set.id == set.id;
        final itemCount = selected
            ? _controller.selected!.activeItems.length
            : null;
        return FlapBoardRow(
          key: Key('sets_list_row_${set.id}'),
          template: kFlapColumnsSets,
          selected: selected,
          onTap: () => _controller.selectSet(set.id),
          cells: [
            FlapTextCell(
              text: set.name,
              primary: true,
              textKey: Key('sets_list_name_${set.id}'),
            ),
            FlapTextCell(text: set.type),
            FlapTextCell(
              text: set.tagIds.isEmpty ? '—' : set.tagIds.join(','),
            ),
            FlapTextCell(
              text: itemCount != null ? '$itemCount filled' : '…',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context) {
    final sel = _controller.selected;
    if (sel == null) {
      return const Center(
        child: Text(
          'Select a set or create one to edit slots.',
          key: Key('sets_detail_empty'),
        ),
      );
    }

    final setType = SetType.tryParse(sel.set.type) ?? SetType.weapon;
    final slots = slotsForSetType(setType);
    final presentation = _presentation;
    final armorTotals = presentation?.armorTotals;
    final readiness = _controller.readinessOfSelected();
    final usedBy = _controller.usedByOfSelected();

    return SingleChildScrollView(
      key: const Key('sets_detail'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit set',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('sets_edit_name'),
            controller: _editNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                key: const Key('sets_detail_type'),
                label: Text(sel.set.type),
              ),
              if (sel.set.tagIds.isNotEmpty)
                for (final t in sel.set.tagIds)
                  Chip(
                    key: Key('sets_detail_tag_$t'),
                    label: Text(t),
                  ),
              FilledButton(
                key: const Key('sets_save_name'),
                onPressed: _saveName,
                child: const Text('Save name'),
              ),
              OutlinedButton(
                key: const Key('sets_delete_button'),
                onPressed: _deleteSelected,
                child: const Text('Delete'),
              ),
            ],
          ),
          if (readiness != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('sets_readiness_strip'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    key: const Key('sets_readiness_badge'),
                    label: Text(readiness.badgeLabel),
                  ),
                  if (usedBy.isEmpty)
                    const Chip(
                      key: Key('sets_used_by_unused'),
                      label: Text('Unused'),
                    )
                  else
                    for (final u in usedBy)
                      Chip(
                        key: Key('sets_used_by_${u.buildId}_${u.variantId}'),
                        label: Text(u.label),
                      ),
                  if (readiness.nextEmptySlot != null)
                    FilledButton.tonal(
                      key: const Key('sets_fill_next'),
                      onPressed: () => _fillSlot(readiness.nextEmptySlot!),
                      child: Text(
                        'Fill next · ${setSlotDisplayLabel(readiness.nextEmptySlot!)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (setType == SetType.armor && armorTotals != null) ...[
            const SizedBox(height: 16),
            _buildArmorTotalsBoard(context, armorTotals),
          ],
          const SizedBox(height: 20),
          Text(
            'Slots',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final slot in slots)
            _buildSlotRow(
              sel,
              slot,
              presentation?.rowsBySlot[slot],
            ),
          if (setType == SetType.armor)
            OptimizerWorkspace(
              key: const Key('sets_optimizer_workspace'),
              controller: _optimizer,
              onApplied: () async {
                await _controller.refresh(keepSelection: true);
                if (!mounted) return;
                setState(() {
                  _statusMessage = _optimizer.status ?? 'Optimizer applied';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildArmorTotalsBoard(BuildContext context, ArmorSetStatTotals totals) {
    return Container(
      key: const Key('sets_armor_stat_board'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Armor base-roll totals'
            '${totals.incomplete ? ' (incomplete)' : ''}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final key in armorBaseStatKeys)
                Chip(
                  key: Key('sets_armor_total_$key'),
                  label: Text(
                    '$key ${totals.statValues[key] ?? '—'}',
                  ),
                ),
              Chip(
                key: const Key('sets_armor_grand_total'),
                label: Text('Total ${totals.grandTotal}'),
              ),
            ],
          ),
          if (totals.piecesWithStats == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'No pinned armor rolls yet — pin owned instances for base stats.',
                key: const Key('sets_armor_stats_empty_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotRow(
    SetDetail detail,
    String slot,
    SetItemRowPresentation? row,
  ) {
    final items = detail.activeItems
        .where(
          (i) => i.slot == slot || i.slot.startsWith('$slot:'),
        )
        .toList();
    final filled = items.isNotEmpty;
    final item = filled ? items.first : null;

    return Container(
      key: Key('sets_slot_row_$slot'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  setSlotDisplayLabel(slot),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: filled
                    ? _buildFilledBody(slot, item!, row)
                    : Text(
                        'Empty',
                        key: Key('sets_slot_empty_$slot'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
              ),
              TextButton(
                key: Key('sets_slot_fill_$slot'),
                onPressed: () => _fillSlot(slot),
                child: Text(filled ? 'Replace' : 'Fill'),
              ),
              if (filled)
                TextButton(
                  key: Key('sets_slot_clear_$slot'),
                  onPressed: () => _clearSlot(slot),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilledBody(
    String slot,
    SetItemRecord item,
    SetItemRowPresentation? row,
  ) {
    final name = row?.itemName ?? item.itemName;
    final hash = row?.itemHash ?? item.itemHash;
    final hasInstance =
        (row?.instanceId ?? item.instanceId) != null &&
        (row?.instanceId ?? item.instanceId)!.isNotEmpty;
    final meta = row?.metaChips ??
        buildSetItemMetaChips(hasInstance: hasInstance);
    final traits = row?.traitPerks ?? const [];
    final synergies = row?.linkedSynergies ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: Key('sets_slot_filled_$slot'),
      children: [
        Text(
          '$name ($hash)',
          key: Key('sets_slot_name_$slot'),
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            for (final m in meta)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(m, style: const TextStyle(fontSize: 11)),
                key: m == 'Instance' || m == 'Wishlist'
                    ? Key('sets_slot_pin_kind_$slot')
                    : null,
              ),
          ],
        ),
        if (traits.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              for (final t in traits)
                Chip(
                  key: Key('sets_slot_trait_${slot}_${t.hash}'),
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    t.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
        if (synergies.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'LINKED SYNERGIES',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final s in synergies)
                Chip(
                  key: Key('sets_slot_synergy_${slot}_${s.id}'),
                  visualDensity: VisualDensity.compact,
                  label: Text(s.label, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
        if (row?.armorStats != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              for (final key in armorBaseStatKeys)
                if (row!.armorStats!.stats[key] != null)
                  Text(
                    '$key ${row.armorStats!.stats[key]}',
                    key: Key('sets_slot_stat_${slot}_$key'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            ],
          ),
        ] else if (row?.statsUnknown == true) ...[
          const SizedBox(height: 4),
          Text(
            hasInstance
                ? 'No armor stats on this copy — re-sync inventory.'
                : 'Wishlist — no instance rolls.',
            key: Key('sets_slot_stats_unknown_$slot'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ],
    );
  }
}
