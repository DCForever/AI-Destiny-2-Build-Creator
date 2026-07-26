import 'package:destiny2_app/destiny2_app.dart'
    show buildCatalogDenseMetaChips, selectedPerksFromInstance;
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../catalog/owned_catalog_bridge.dart';
import '../host_bootstrap.dart';
import '../widgets/entity_icon.dart';
import 'set_slot_mapping.dart';
import 'sets_library_controller.dart';


/// Modal catalog pick for filling a set slot (All | Owned) — DART-030.
class SetCatalogPicker extends StatefulWidget {
  const SetCatalogPicker({
    super.key,
    required this.services,
    required this.targetSlot,
    this.bridge,
    this.title,
  });

  final AppServices services;
  final String targetSlot;
  final OwnedCatalogBridge? bridge;
  final String? title;

  @override
  State<SetCatalogPicker> createState() => _SetCatalogPickerState();
}

class _SetCatalogPickerState extends State<SetCatalogPicker> {
  late final OwnedCatalogBridge _bridge;
  bool _loading = true;
  String? _error;
  List<CatalogItem> _results = const [];
  CatalogScope _scope = CatalogScope.all;
  final _queryController = TextEditingController();
  CatalogItem? _selected;
  List<CatalogInstanceProjection> _instances = const [];

  @override
  void initState() {
    super.initState();
    _bridge = widget.bridge ??
        OwnedCatalogBridge(
          db: widget.services.db,
          offlineCatalog: widget.services.offlineCatalog,
          session: widget.services.oauthSession,
          inventorySync: widget.services.inventorySync,
        );
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.services.oauthSession.isSignedIn) {
        await widget.services.inventorySync.refreshStatus();
      }
      await _bridge.refresh(reloadEntities: true);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
      });
    }
  }

  List<CatalogItem> _applyFilters() {
    final filtered = _bridge.browse(
      CatalogClientFilters(
        query: _queryController.text,
        scope: _scope,
      ),
    );
    return filtered
        .where((i) => catalogItemMatchesSetSlot(i.slot, widget.targetSlot))
        .toList();
  }

  void _refilter() {
    setState(() {
      _results = _applyFilters();
      if (_selected != null &&
          !_results.any((i) => i.hash == _selected!.hash)) {
        _selected = null;
        _instances = const [];
      }
    });
  }

  void _setScope(CatalogScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _results = _applyFilters();
      if (_selected != null &&
          !_results.any((i) => i.hash == _selected!.hash)) {
        _selected = null;
        _instances = const [];
      }
    });
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selected = item;
      _instances = _bridge.instancesFor(item.hash);
    });
  }

  void _confirm({String? instanceId}) {
    final item = _selected;
    if (item == null) return;
    List<int> perks = const [];
    if (instanceId != null) {
      CatalogInstanceProjection? match;
      for (final inst in _instances) {
        if (inst.instanceId == instanceId) {
          match = inst;
          break;
        }
      }
      perks = selectedPerksFromInstance(match);
    }
    Navigator.of(context).pop(
      SetSlotPickResult(
        itemHash: item.hash,
        itemName: item.name,
        instanceId: instanceId,
        selectedPerks: perks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        'Pick for ${setSlotDisplayLabel(widget.targetSlot)}';

    return Dialog(
      key: const Key('set_catalog_picker'),
      child: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('set_catalog_picker_close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('set_catalog_picker_query'),
                controller: _queryController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (_) => _refilter(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  FilterChip(
                    key: const Key('set_picker_scope_all'),
                    label: const Text('All'),
                    selected: _scope == CatalogScope.all,
                    onSelected: (_) => _setScope(CatalogScope.all),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('set_picker_scope_owned'),
                    label: const Text('Owned'),
                    selected: _scope == CatalogScope.owned,
                    onSelected: (_) => _setScope(CatalogScope.owned),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
            if (_selected != null) _buildConfirmBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('set_picker_loading')),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load catalog:\n$_error',
          key: const Key('set_picker_error'),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_results.isEmpty) {
      final ownedHint = _scope == CatalogScope.owned
          ? 'No owned items match this slot. Sign in and sync inventory, or switch to All.'
          : 'No catalog items match this slot. Refresh entity stores in Settings.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            ownedHint,
            key: const Key('set_picker_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ListView.builder(
            key: const Key('set_picker_list'),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              final selected = _selected?.hash == item.hash;
              final chips = buildCatalogDenseMetaChips(
                isExotic: item.isExotic,
                slot: item.slot,
                element: item.element,
                ammo: item.ammo,
                itemTypeName: item.itemTypeName,
                frame: item.frame,
              );
              final meta = [
                ...chips,
                if (item.owned) 'owned×${item.ownedCount}',
              ].join(' · ');
              return ListTile(
                key: Key('set_picker_item_${item.hash}'),
                selected: selected,
                leading: EntityIcon(
                  key: Key('set_picker_item_icon_${item.hash}'),
                  icon: item.icon,
                  size: 32,
                  fallback: item.isExotic
                      ? Icons.star
                      : Icons.inventory_2_outlined,
                ),
                title: Text(item.name),
                subtitle: Text(
                  meta.isEmpty ? '#${item.hash}' : meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectItem(item),
              );
            },
          ),
        ),
        if (_selected != null)
          Expanded(
            flex: 2,
            child: _buildInstanceSide(),
          ),
      ],
    );
  }

  Widget _buildInstanceSide() {
    final item = _selected!;
    if (_instances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'No owned instances — will pin as wishlist (definition only).',
              key: Key('set_picker_wishlist_hint'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Instances (${_instances.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('set_picker_instances'),
            itemCount: _instances.length,
            itemBuilder: (context, index) {
              final inst = _instances[index];
              final traits = inst.plugCards
                  .where((c) => c.isTrait)
                  .map((c) => c.displayName)
                  .take(3)
                  .join(', ');
              return ListTile(
                key: Key('set_picker_instance_${inst.instanceId}'),
                title: Text('Power ${inst.power}'),
                subtitle: Text(
                  [
                    inst.location,
                    if (traits.isNotEmpty) traits,
                    inst.instanceId,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _confirm(instanceId: inst.instanceId),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmBar() {
    final item = _selected!;
    String? autoInstance;
    if (_instances.length == 1) {
      autoInstance = _instances.single.instanceId;
    }
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Use ${item.name}'
                '${autoInstance != null ? ' (auto instance)' : ' (wishlist / pick instance)'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const Key('set_picker_confirm_wishlist'),
              onPressed: () => _confirm(),
              child: const Text('Definition only'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('set_picker_confirm'),
              onPressed: () => _confirm(instanceId: autoInstance),
              child: Text(autoInstance != null ? 'Pin instance' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the set catalog picker dialog; returns pick or null if cancelled.
Future<SetSlotPickResult?> showSetCatalogPicker({
  required BuildContext context,
  required AppServices services,
  required String targetSlot,
  OwnedCatalogBridge? bridge,
}) {
  return showDialog<SetSlotPickResult>(
    context: context,
    builder: (ctx) => SetCatalogPicker(
      services: services,
      targetSlot: targetSlot,
      bridge: bridge,
    ),
  );
}
