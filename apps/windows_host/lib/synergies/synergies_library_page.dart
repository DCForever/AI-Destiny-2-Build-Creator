import 'package:destiny2_app/destiny2_app.dart' show SynergyLinkWrite;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../host_bootstrap.dart';
import 'synergies_library_controller.dart';
import 'synergy_designation.dart';

/// Synergy library dual-pane (list + detail/links) — DART-031.
class SynergiesLibraryPage extends StatefulWidget {
  const SynergiesLibraryPage({
    super.key,
    required this.services,
    this.controller,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final SynergiesLibraryController? controller;

  @override
  State<SynergiesLibraryPage> createState() => _SynergiesLibraryPageState();
}

class _SynergiesLibraryPageState extends State<SynergiesLibraryPage> {
  late final SynergiesLibraryController _controller;
  final _nameController = TextEditingController();
  final _subTypeController = TextEditingController();
  final _createDescController = TextEditingController();
  final _editNameController = TextEditingController();
  final _editDescController = TextEditingController();
  final _linkNameController = TextEditingController();
  final _linkHashController = TextEditingController();
  String _createType = creatableSynergyTypeWires.first;
  String _linkKind = SynergyLinkKind.weapon.wireName;
  String? _statusMessage;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownController = true;
      _controller = SynergiesLibraryController(
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
    _subTypeController.dispose();
    _createDescController.dispose();
    _editNameController.dispose();
    _editDescController.dispose();
    _linkNameController.dispose();
    _linkHashController.dispose();
    super.dispose();
  }

  void _onController() {
    final sel = _controller.selected;
    if (sel != null) {
      if (_editNameController.text != sel.name) {
        _editNameController.text = sel.name;
      }
      if (_editDescController.text != sel.description) {
        _editDescController.text = sel.description;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final err = await _controller.createSynergy(
      name: _nameController.text,
      type: _createType,
      subType: _subTypeController.text.trim().isEmpty
          ? null
          : _subTypeController.text,
      description: _createDescController.text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Created ${_nameController.text.trim()}';
      if (err == null) {
        _nameController.clear();
        _subTypeController.clear();
        _createDescController.clear();
      }
    });
  }

  Future<void> _saveIdentity() async {
    final err = await _controller.updateSelectedIdentity(
      name: _editNameController.text,
      description: _editDescController.text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved';
    });
  }

  Future<void> _saveLinks() async {
    final err = await _controller.saveDraftLinks();
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Links saved';
    });
  }

  void _addLink() {
    final display = _linkNameController.text.trim();
    if (display.isEmpty) {
      setState(() => _statusMessage = 'Link display name must not be empty');
      return;
    }
    int? itemHash;
    final hashText = _linkHashController.text.trim();
    if (hashText.isNotEmpty) {
      itemHash = int.tryParse(hashText);
      if (itemHash == null) {
        setState(() => _statusMessage = 'Item hash must be an integer');
        return;
      }
    }
    _controller.addDraftLink(
      SynergyLinkWrite(
        kind: _linkKind,
        displayName: display,
        itemHash: itemHash,
      ),
    );
    _linkNameController.clear();
    _linkHashController.clear();
    setState(() => _statusMessage = 'Link added (save to persist)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synergies'),
        actions: [
          IconButton(
            key: const Key('synergies_reload'),
            tooltip: 'Reload library',
            onPressed:
                _controller.loading ? null : () => _controller.refresh(),
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
                key: const Key('synergies_status'),
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
    // Compact create strip (name/type/subtype only) so list remains Expanded
    // without nested scroll clipping in short test viewports.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            'Library',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            key: const Key('synergies_create_name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'New synergy name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _create(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: DropdownButtonFormField<String>(
            key: const Key('synergies_create_type'),
            // ignore: deprecated_member_use
            value: _createType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in creatableSynergyTypeWires)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _createType = v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: TextField(
            key: const Key('synergies_create_subtype'),
            controller: _subTypeController,
            decoration: const InputDecoration(
              labelText: 'Subtype (optional)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Hidden optional description field for tests / accessibility (dense).
        Offstage(
          offstage: true,
          child: TextField(
            key: const Key('synergies_create_description'),
            controller: _createDescController,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: FilledButton(
            key: const Key('synergies_create_button'),
            onPressed: _controller.loading ? null : _create,
            child: const Text('Create synergy'),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < kFlapColumnsSynergy.headerLabels.length; i++)
                Expanded(
                  flex: i == 0 || i == 2 ? 2 : 1,
                  child: Text(
                    kFlapColumnsSynergy.headerLabels[i].toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildSynergyList()),
      ],
    );
  }

  Widget _buildSynergyList() {
    if (_controller.loading && _controller.synergies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('synergies_loading')),
      );
    }
    if (_controller.synergies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No synergies yet. Create one above.',
            key: Key('synergies_list_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('synergies_list'),
      itemCount: _controller.synergies.length,
      itemBuilder: (context, index) {
        final s = _controller.synergies[index];
        final selected = _controller.selected?.id == s.id;
        final designation = _controller.designationOf(s);
        final evidenceCount =
            selected ? _controller.draftLinks.length : s.links.length;
        return InkWell(
          key: Key('synergies_list_row_${s.id}'),
          onTap: () => _controller.selectSynergy(s.id),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12)
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
                    s.name,
                    key: Key('synergies_list_name_${s.id}'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    designation,
                    key: Key('synergies_list_designation_${s.id}'),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$evidenceCount link${evidenceCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    'ok',
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
          'Select a synergy or create one to edit evidence links.',
          key: Key('synergies_detail_empty'),
        ),
      );
    }

    final designation = formatSynergyDesignation(sel.type, sel.subType);

    return SingleChildScrollView(
      key: const Key('synergies_detail'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit synergy',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('synergies_edit_name'),
            controller: _editNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('synergies_edit_description'),
            controller: _editDescController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                key: const Key('synergies_detail_designation'),
                label: Text(designation),
                avatar: const Icon(Icons.lock_outline, size: 16),
              ),
              Text(
                'Designation locked',
                key: const Key('synergies_designation_locked'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              FilledButton(
                key: const Key('synergies_save_identity'),
                onPressed: _saveIdentity,
                child: const Text('Save'),
              ),
            ],
          ),
          // Explicitly no type/subtype editors after create (exit: immutable).
          const SizedBox(height: 20),
          Text(
            'Evidence links',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_controller.draftLinks.isEmpty)
            Text(
              'No evidence links yet.',
              key: const Key('synergies_links_empty'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            )
          else
            Column(
              key: const Key('synergies_links_list'),
              children: [
                for (var i = 0; i < _controller.draftLinks.length; i++)
                  _buildLinkRow(i, _controller.draftLinks[i]),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            'Add link',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const Key('synergies_link_kind'),
            // ignore: deprecated_member_use
            value: _linkKind,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kind',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final k in SynergyLinkKind.values)
                DropdownMenuItem(
                  value: k.wireName,
                  child: Text(synergyLinkKindLabel(k.wireName)),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _linkKind = v);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('synergies_link_display_name'),
            controller: _linkNameController,
            decoration: const InputDecoration(
              labelText: 'Display name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('synergies_link_item_hash'),
            controller: _linkHashController,
            decoration: const InputDecoration(
              labelText: 'Item hash (optional)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('synergies_link_add'),
                onPressed: _addLink,
                child: const Text('Add to draft'),
              ),
              FilledButton(
                key: const Key('synergies_links_save'),
                onPressed: _saveLinks,
                child: const Text('Save links'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(int index, SynergyLinkWrite link) {
    return Container(
      key: Key('synergies_link_row_$index'),
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
          Expanded(
            child: Text(
              '${synergyLinkKindLabel(link.kind)}: ${link.displayName}'
              '${link.itemHash != null ? ' (${link.itemHash})' : ''}',
              key: Key('synergies_link_label_$index'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            key: Key('synergies_link_remove_$index'),
            onPressed: () {
              _controller.removeDraftLinkAt(index);
              setState(() => _statusMessage = 'Link removed (save to persist)');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
