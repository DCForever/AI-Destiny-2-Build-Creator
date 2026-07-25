import 'package:destiny2_app/destiny2_app.dart' show SetDetail;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import 'set_catalog_picker.dart';
import 'set_slot_mapping.dart';
import 'sets_library_controller.dart';

/// Sets library dual-pane (list + detail/slots) — DART-030.
class SetsLibraryPage extends StatefulWidget {
  const SetsLibraryPage({
    super.key,
    required this.services,
    this.controller,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final SetsLibraryController? controller;

  @override
  State<SetsLibraryPage> createState() => _SetsLibraryPageState();
}

class _SetsLibraryPageState extends State<SetsLibraryPage> {
  late final SetsLibraryController _controller;
  final _nameController = TextEditingController();
  final _editNameController = TextEditingController();
  SetType _createType = SetType.weapon;
  String? _statusMessage;
  bool _ownController = false;

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
    _controller.addListener(_onController);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    if (_ownController) {
      _controller.dispose();
    }
    _nameController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  void _onController() {
    final sel = _controller.selected;
    if (sel != null && _editNameController.text != sel.set.name) {
      _editNameController.text = sel.set.name;
    }
    if (mounted) setState(() {});
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
    );
    if (pick == null || !mounted) return;
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: kFlapLibraryRailWidth,
                  child: _buildRail(context),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildDetail(context)),
              ],
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
        // Create form
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
        // Column header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < kFlapColumnsSets.headerLabels.length; i++)
                Expanded(
                  flex: i == 0 ? 2 : 1,
                  child: Text(
                    kFlapColumnsSets.headerLabels[i].toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildSetList()),
      ],
    );
  }

  Widget _buildSetList() {
    if (_controller.loading && _controller.sets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('sets_loading')),
      );
    }
    if (_controller.sets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No sets yet. Create one above.',
            key: Key('sets_list_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('sets_list'),
      itemCount: _controller.sets.length,
      itemBuilder: (context, index) {
        final set = _controller.sets[index];
        final selected = _controller.selected?.set.id == set.id;
        final itemCount = selected
            ? _controller.selected!.activeItems.length
            : null;
        return InkWell(
          key: Key('sets_list_row_${set.id}'),
          onTap: () => _controller.selectSet(set.id),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: kFlapRuleThickness,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    set.name,
                    key: Key('sets_list_name_${set.id}'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    set.type,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    set.tagIds.isEmpty ? '—' : set.tagIds.join(','),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    itemCount != null ? '$itemCount filled' : '…',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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
          Row(
            children: [
              Chip(
                key: const Key('sets_detail_type'),
                label: Text(sel.set.type),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('sets_save_name'),
                onPressed: _saveName,
                child: const Text('Save name'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Slots',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final slot in slots) _buildSlotRow(sel, slot),
        ],
      ),
    );
  }

  Widget _buildSlotRow(SetDetail detail, String slot) {
    final items = detail.activeItems
        .where(
          (i) =>
              i.slot == slot ||
              i.slot.startsWith('$slot:'),
        )
        .toList();
    final filled = items.isNotEmpty;
    final item = filled ? items.first : null;

    return Container(
      key: Key('sets_slot_row_$slot'),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              setSlotDisplayLabel(slot),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: filled
                ? Text(
                    '${item!.itemName} (${item.itemHash})'
                    '${item.instanceId != null ? ' · inst ${item.instanceId}' : ' · wishlist'}',
                    key: Key('sets_slot_filled_$slot'),
                    overflow: TextOverflow.ellipsis,
                  )
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
    );
  }
}
