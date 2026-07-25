import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dim_export/dim_export_controller.dart';
import '../dim_export/dim_export_panel.dart';
import '../equip/equip_controller.dart';
import '../equip/equip_panel.dart';
import '../host_bootstrap.dart';
import 'builds_library_controller.dart';
import 'soft_guidance_format.dart';

/// Builds library dual-pane (list + identity + variant compose + soft guidance
/// + equip + DIM export — DART-032/033/034/038/039).
class BuildsLibraryPage extends StatefulWidget {
  const BuildsLibraryPage({
    super.key,
    required this.services,
    this.controller,
    this.equipController,
    this.dimExportController,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final BuildsLibraryController? controller;

  /// Optional injectable equip controller (tests).
  final EquipController? equipController;

  /// Optional injectable DIM export controller (tests).
  final DimExportController? dimExportController;

  @override
  State<BuildsLibraryPage> createState() => _BuildsLibraryPageState();
}

class _BuildsLibraryPageState extends State<BuildsLibraryPage> {
  late final BuildsLibraryController _controller;
  late final EquipController _equipController;
  late final DimExportController _dimExportController;
  bool _ownEquipController = false;
  bool _ownDimExportController = false;
  String? _boundEquipKey;
  String? _boundDimExportKey;
  final _createNameController = TextEditingController();
  final _createSubTypeController = TextEditingController();
  final _createArmorHashController = TextEditingController();
  final _createArmorNameController = TextEditingController();
  final _createWeaponHashController = TextEditingController();
  final _createWeaponNameController = TextEditingController();
  final _createPinnedSuperController = TextEditingController();

  final _editNameController = TextEditingController();
  final _editSubTypeController = TextEditingController();
  final _editArmorHashController = TextEditingController();
  final _editArmorNameController = TextEditingController();
  final _editWeaponHashController = TextEditingController();
  final _editWeaponNameController = TextEditingController();
  final _editPinnedSuperController = TextEditingController();
  final _createVariantNameController = TextEditingController();
  final _pinInstanceController = TextEditingController();
  final Map<ArmorStatName, TextEditingController> _softStatControllers = {
    for (final s in ArmorStatName.all) s: TextEditingController(),
  };

  GuardianClass _createClass = GuardianClass.hunter;
  String _createTypeWire = creatableSynergyTypeWires.first;
  String _editTypeWire = creatableSynergyTypeWires.first;
  String? _statusMessage;
  bool _ownController = false;
  String? _boundSelectionId;
  String? _attachSetId;
  String? _pinTargetKey;
  String? _boundSoftTargetsKey;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownController = true;
      _controller = BuildsLibraryController(
        db: widget.services.db,
        session: widget.services.oauthSession,
        inventorySync: widget.services.inventorySync,
      );
    }
    if (widget.equipController != null) {
      _equipController = widget.equipController!;
    } else {
      _ownEquipController = true;
      _equipController = EquipController(
        db: widget.services.db,
        session: widget.services.oauthSession,
        profileClient: widget.services.profileClient,
        writeClient: widget.services.writeClient,
        inventorySync: widget.services.inventorySync,
      );
    }
    if (widget.dimExportController != null) {
      _dimExportController = widget.dimExportController!;
    } else {
      _ownDimExportController = true;
      _dimExportController = DimExportController(
        db: widget.services.db,
      );
    }
    _controller.addListener(_onController);
    _equipController.addListener(_onEquipController);
    _dimExportController.addListener(_onDimExportController);
    _controller.refresh();
  }

  void _onEquipController() {
    if (mounted) setState(() {});
  }

  void _onDimExportController() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _equipController.removeListener(_onEquipController);
    _dimExportController.removeListener(_onDimExportController);
    if (_ownController) {
      _controller.dispose();
    }
    if (_ownEquipController) {
      _equipController.dispose();
    }
    if (_ownDimExportController) {
      _dimExportController.dispose();
    }
    _createNameController.dispose();
    _createSubTypeController.dispose();
    _createArmorHashController.dispose();
    _createArmorNameController.dispose();
    _createWeaponHashController.dispose();
    _createWeaponNameController.dispose();
    _createPinnedSuperController.dispose();
    _editNameController.dispose();
    _editSubTypeController.dispose();
    _editArmorHashController.dispose();
    _editArmorNameController.dispose();
    _editWeaponHashController.dispose();
    _editWeaponNameController.dispose();
    _editPinnedSuperController.dispose();
    _createVariantNameController.dispose();
    _pinInstanceController.dispose();
    for (final c in _softStatControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncSoftStatFieldsFromController() {
    final targets = _controller.softStatTargets;
    final key =
        '${_controller.selected?.build.id}|${formatSoftStatTargetsSummary(targets)}';
    if (key == _boundSoftTargetsKey) return;
    _boundSoftTargetsKey = key;
    for (final stat in ArmorStatName.all) {
      final v = targets[stat];
      _softStatControllers[stat]!.text = v?.toString() ?? '';
    }
  }

  void _onController() {
    final sel = _controller.selected;
    if (sel != null && sel.build.id != _boundSelectionId) {
      _boundSelectionId = sel.build.id;
      _boundSoftTargetsKey = null;
      _editNameController.text = sel.build.name;
      _editArmorHashController.text =
          sel.build.exoticArmorHash?.toString() ?? '';
      _editArmorNameController.text = sel.build.exoticArmorName ?? '';
      _editWeaponHashController.text =
          sel.build.exoticWeaponHash?.toString() ?? '';
      _editWeaponNameController.text = sel.build.exoticWeaponName ?? '';
      _editPinnedSuperController.text = sel.build.pinnedSuper ?? '';
    } else if (sel == null) {
      _boundSelectionId = null;
      _boundSoftTargetsKey = null;
      for (final c in _softStatControllers.values) {
        c.clear();
      }
    }
    _syncSoftStatFieldsFromController();
    _syncEquipBinding();
    _syncDimExportBinding();
    if (mounted) setState(() {});
  }

  void _syncEquipBinding() {
    final sel = _controller.selected;
    final variant = _controller.selectedVariant;
    final uid = _controller.userId;
    if (sel == null || variant == null || uid == null) {
      if (_boundEquipKey != null) {
        _boundEquipKey = null;
        _equipController.clearBinding();
      }
      return;
    }
    // Include pin fingerprint so attach/pin changes re-evaluate equip-ready.
    final pinFp = [
      for (final p in _controller.slotPins)
        '${p.slot}:${p.itemHash}:${p.instanceId ?? ''}',
    ].join(',');
    final key =
        '${sel.build.id}|${variant.id}|${sel.build.className}|$pinFp';
    if (key == _boundEquipKey) return;
    _boundEquipKey = key;
    // Fire-and-forget; controller notifies when ready.
    _equipController.bind(
      userId: uid,
      buildId: sel.build.id,
      variantId: variant.id,
      buildClass: sel.build.className,
    );
  }

  void _syncDimExportBinding() {
    final sel = _controller.selected;
    final variant = _controller.selectedVariant;
    final uid = _controller.userId;
    if (sel == null || variant == null || uid == null) {
      if (_boundDimExportKey != null) {
        _boundDimExportKey = null;
        _dimExportController.clearBinding();
      }
      return;
    }
    final pinFp = [
      for (final p in _controller.slotPins)
        '${p.slot}:${p.itemHash}:${p.instanceId ?? ''}',
    ].join(',');
    final key = '${sel.build.id}|${variant.id}|$pinFp';
    if (key == _boundDimExportKey) return;
    _boundDimExportKey = key;
    _dimExportController.bind(
      userId: uid,
      buildId: sel.build.id,
      variantId: variant.id,
    );
  }

  int? _parseOptionalHash(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _create() async {
    final armorHash = _parseOptionalHash(_createArmorHashController.text);
    if (_createArmorHashController.text.trim().isNotEmpty && armorHash == null) {
      setState(() => _statusMessage = 'Exotic armor hash must be an integer');
      return;
    }
    final weaponHash = _parseOptionalHash(_createWeaponHashController.text);
    if (_createWeaponHashController.text.trim().isNotEmpty &&
        weaponHash == null) {
      setState(() => _statusMessage = 'Exotic weapon hash must be an integer');
      return;
    }

    final nameText = _createNameController.text.trim();
    final err = await _controller.createBuild(
      name: nameText.isEmpty ? null : nameText,
      className: _createClass,
      exoticArmorHash: armorHash,
      exoticArmorName: _createArmorNameController.text.trim().isEmpty
          ? null
          : _createArmorNameController.text.trim(),
      exoticWeaponHash: weaponHash,
      exoticWeaponName: _createWeaponNameController.text.trim().isEmpty
          ? null
          : _createWeaponNameController.text.trim(),
      pinnedSuper: _createPinnedSuperController.text.trim().isEmpty
          ? null
          : _createPinnedSuperController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ??
          'Created ${nameText.isEmpty ? _createClass.wireName : nameText}';
      if (err == null) {
        _createNameController.clear();
        _createSubTypeController.clear();
        _createArmorHashController.clear();
        _createArmorNameController.clear();
        _createWeaponHashController.clear();
        _createWeaponNameController.clear();
        _createPinnedSuperController.clear();
      }
    });
  }

  Future<void> _saveIdentity() async {
    final armorHash = _parseOptionalHash(_editArmorHashController.text);
    if (_editArmorHashController.text.trim().isNotEmpty && armorHash == null) {
      setState(() => _statusMessage = 'Exotic armor hash must be an integer');
      return;
    }
    final weaponHash = _parseOptionalHash(_editWeaponHashController.text);
    if (_editWeaponHashController.text.trim().isNotEmpty &&
        weaponHash == null) {
      setState(() => _statusMessage = 'Exotic weapon hash must be an integer');
      return;
    }

    final err = await _controller.updateSelectedIdentity(
      name: _editNameController.text,
      setExoticArmor: true,
      exoticArmorHash: armorHash,
      exoticArmorName: _editArmorNameController.text.trim().isEmpty
          ? null
          : _editArmorNameController.text.trim(),
      setExoticWeapon: true,
      exoticWeaponHash: weaponHash,
      exoticWeaponName: _editWeaponNameController.text.trim().isEmpty
          ? null
          : _editWeaponNameController.text.trim(),
      setPinnedSuper: true,
      pinnedSuper: _editPinnedSuperController.text.trim().isEmpty
          ? null
          : _editPinnedSuperController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved';
      if (err == null) {
        _boundSelectionId = null; // re-bind fields from controller
        _onController();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Builds'),
        actions: [
          IconButton(
            key: const Key('builds_reload'),
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
                key: const Key('builds_status'),
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
    // Create strip scrolls when height is tight (host nav + short test VMs).
    // Optional exotic/super pins on create are offstage (controller / detail edit).
    return LayoutBuilder(
      builder: (context, constraints) {
        final createMax =
            (constraints.maxHeight * 0.58).clamp(140.0, 360.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: createMax),
              child: SingleChildScrollView(
                child: Column(
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
                        key: const Key('builds_create_name'),
                        controller: _createNameController,
                        decoration: const InputDecoration(
                          labelText: 'New build name (optional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _create(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: DropdownButtonFormField<GuardianClass>(
                        key: const Key('builds_create_class'),
                        // ignore: deprecated_member_use
                        value: _createClass,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in GuardianClass.values)
                            DropdownMenuItem(
                              value: c,
                              child: Text(c.wireName),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _createClass = v);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: DropdownButtonFormField<String>(
                        key: const Key('builds_create_synergy_type'),
                        // ignore: deprecated_member_use
                        value: _createTypeWire,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Synergy type',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final t in creatableSynergyTypeWires)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _createTypeWire = v);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: TextField(
                        key: const Key('builds_create_synergy_subtype'),
                        controller: _createSubTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Subtype (optional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: OutlinedButton(
                        key: const Key('builds_create_add_synergy'),
                        onPressed: () {
                          _controller.addCreateDraftType(
                            _createTypeWire,
                            _createSubTypeController.text,
                          );
                          _createSubTypeController.clear();
                        },
                        child: const Text('Add synergy type'),
                      ),
                    ),
                    if (_controller.createDraftTypes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Wrap(
                          key: const Key('builds_create_synergy_chips'),
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (var i = 0;
                                i < _controller.createDraftTypes.length;
                                i++)
                              InputChip(
                                key: Key('builds_create_synergy_chip_$i'),
                                label: Text(
                                  _controller
                                      .createDraftTypes[i].designationKey,
                                ),
                                onDeleted: () =>
                                    _controller.removeCreateDraftTypeAt(i),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                      child: FilledButton(
                        key: const Key('builds_create_button'),
                        onPressed: _controller.loading ? null : _create,
                        child: const Text('Create build'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (var i = 0;
                      i < kFlapColumnsBuilds.headerLabels.length;
                      i++)
                    Expanded(
                      flex: i == 0 || i == 3 ? 2 : 1,
                      child: Text(
                        kFlapColumnsBuilds.headerLabels[i].toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBuildList()),
          ],
        );
      },
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
        return InkWell(
          key: Key('builds_list_row_${b.id}'),
          onTap: () => _controller.selectBuild(b.id),
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
                    b.name,
                    key: Key('builds_list_name_${b.id}'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    _controller.identitySummaryOf(b),
                    key: Key('builds_list_identity_${b.id}'),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    _controller.exoticsSummaryOf(b),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _controller.synergySummaryOf(b),
                    key: Key('builds_list_synergy_${b.id}'),
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
          'Select a build or create one to edit identity.',
          key: Key('builds_detail_empty'),
        ),
      );
    }
    final b = sel.build;
    final synergyText = _controller.synergySummaryOf(b);

    return SingleChildScrollView(
      key: const Key('builds_detail'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Identity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                key: const Key('builds_detail_class'),
                label: Text(b.className),
              ),
              Chip(
                key: const Key('builds_detail_synergy_types'),
                label: Text(
                  synergyText.isEmpty ? '(none)' : synergyText,
                ),
              ),
              if (b.pinnedSuper != null && b.pinnedSuper!.trim().isNotEmpty)
                Chip(
                  key: const Key('builds_detail_pinned_super'),
                  label: Text('Super: ${b.pinnedSuper}'),
                ),
              if (b.exoticArmorName != null || b.exoticArmorHash != null)
                Chip(
                  key: const Key('builds_detail_exotic_armor'),
                  label: Text(
                    b.exoticArmorName ?? 'Armor ${b.exoticArmorHash}',
                  ),
                ),
              if (b.exoticWeaponName != null || b.exoticWeaponHash != null)
                Chip(
                  key: const Key('builds_detail_exotic_weapon'),
                  label: Text(
                    b.exoticWeaponName ?? 'Weapon ${b.exoticWeaponHash}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('builds_edit_name'),
            controller: _editNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Synergy types',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (_controller.editDraftTypes.isEmpty)
            const Text(
              'No synergy types (required before save).',
              key: Key('builds_edit_synergy_empty'),
            )
          else
            Wrap(
              key: const Key('builds_edit_synergy_chips'),
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _controller.editDraftTypes.length; i++)
                  InputChip(
                    key: Key('builds_edit_synergy_chip_$i'),
                    label: Text(_controller.editDraftTypes[i].designationKey),
                    onDeleted: () => _controller.removeEditDraftTypeAt(i),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('builds_edit_synergy_type'),
                  // ignore: deprecated_member_use
                  value: _editTypeWire,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Add type',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in creatableSynergyTypeWires)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _editTypeWire = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          Text(
            'Exotic / Super pins',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('builds_edit_armor_hash'),
            controller: _editArmorHashController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Exotic armor hash',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('builds_edit_armor_name'),
            controller: _editArmorNameController,
            decoration: const InputDecoration(
              labelText: 'Exotic armor name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('builds_edit_weapon_hash'),
            controller: _editWeaponHashController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Exotic weapon hash',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('builds_edit_weapon_name'),
            controller: _editWeaponNameController,
            decoration: const InputDecoration(
              labelText: 'Exotic weapon name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('builds_edit_pinned_super'),
            controller: _editPinnedSuperController,
            decoration: const InputDecoration(
              labelText: 'Pinned Super',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('builds_save_identity'),
            onPressed: _controller.loading ? null : _saveIdentity,
            child: const Text('Save identity'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          _buildVariantCompose(context),
        ],
      ),
    );
  }

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
          'Variants',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (variants.isEmpty)
          const Text(
            'No variants on this build.',
            key: Key('builds_variants_empty'),
          )
        else
          Wrap(
            key: const Key('builds_variants_list'),
            spacing: 8,
            runSpacing: 8,
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
        const SizedBox(height: 8),
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
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('builds_create_variant_button'),
              onPressed: _controller.loading ? null : _createVariant,
              child: const Text('Create variant'),
            ),
          ],
        ),
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
        const SizedBox(height: 16),
        Text(
          'Slot pins',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Wishlist = definition only; instance = owned copy pin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
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
          EquipPanel(
            key: const Key('builds_equip_panel'),
            controller: _equipController,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          DimExportPanel(
            key: const Key('builds_dim_export_panel'),
            controller: _dimExportController,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
        ],
        _buildSoftGuidance(context),
      ],
    );
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
                    backgroundColor: Color(
                      _toneColor(coverageTierToneKey(row.tier)),
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

  int _toneColor(String toneKey) {
    switch (toneKey) {
      case 'success':
        return kFlapSuccessDark;
      case 'warning':
        return kFlapWarningDark;
      case 'danger':
        return kFlapDangerDark;
      default:
        return kFlapMutedDark;
    }
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

