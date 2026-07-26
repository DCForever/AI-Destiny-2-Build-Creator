import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dim_export/dim_export_controller.dart';
import '../dim_export/dim_export_panel.dart';
import '../equip/equip_controller.dart';
import '../equip/equip_panel.dart';
import '../host_bootstrap.dart';
import 'builds_library_controller.dart';
import 'finish_gaps_format.dart';
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

  Future<void> _saveIdentity({IdentityAction? identityAction}) async {
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

    final nextArmorSlot = _lookupExoticArmorSlot(armorHash);
    final existingArmorSlot =
        _lookupExoticArmorSlot(_controller.selected?.build.exoticArmorHash);

    final err = await _controller.updateSelectedIdentity(
      name: _editNameController.text,
      setExoticArmor: true,
      exoticArmorHash: armorHash,
      exoticArmorName: _editArmorNameController.text.trim().isEmpty
          ? null
          : _editArmorNameController.text.trim(),
      existingExoticArmorSlot: existingArmorSlot,
      nextExoticArmorSlot: nextArmorSlot,
      setExoticWeapon: true,
      exoticWeaponHash: weaponHash,
      exoticWeaponName: _editWeaponNameController.text.trim().isEmpty
          ? null
          : _editWeaponNameController.text.trim(),
      setPinnedSuper: true,
      pinnedSuper: _editPinnedSuperController.text.trim().isEmpty
          ? null
          : _editPinnedSuperController.text.trim(),
      identityAction: identityAction,
    );
    if (!mounted) return;
    setState(() {
      if (err != null && _controller.identityConfirmRequired) {
        _statusMessage =
            'Identity change requires Confirm or Fork (${_controller.pendingIdentityFields?.join(', ')})';
      } else {
        _statusMessage = err ??
            (_controller.lastForkedFromId != null
                ? 'Forked from ${_controller.lastForkedFromId}'
                : 'Saved');
      }
      if (err == null) {
        _boundSelectionId = null; // re-bind fields from controller
        _onController();
      }
    });
  }

  String? _lookupExoticArmorSlot(int? hash) {
    if (hash == null) return null;
    final items = _controller.catalogItems ??
        widget.services.offlineCatalog.baseItems;
    for (final i in items) {
      if (i.hash == hash &&
          ((i.sourceStore ?? '') == 'exotic-armor' || i.isExotic)) {
        return i.slot;
      }
    }
    return null;
  }

  Future<void> _openManifestPick({
    required ManifestPickKind kind,
    required void Function(ManifestPick pick) onPick,
  }) async {
    final items = _controller.catalogItems ??
        widget.services.offlineCatalog.baseItems;
    final className = _controller.selected?.build.className;
    final queryController = TextEditingController();
    List<ManifestPick> results = searchManifestPicks(
      items: items,
      kind: kind,
      classType: className,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              key: Key('manifest_pick_dialog_${kind.name}'),
              title: Text('Search ${kind.name}'),
              content: SizedBox(
                width: 420,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      key: Key('manifest_pick_query_${kind.name}'),
                      controller: queryController,
                      decoration: const InputDecoration(
                        labelText: 'Search by name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (q) {
                        setLocal(() {
                          results = searchManifestPicks(
                            items: items,
                            kind: kind,
                            query: q,
                            classType: className,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: results.isEmpty
                          ? const Text(
                              'No Manifest hits (refresh entity catalog).',
                              key: Key('manifest_pick_empty'),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final p = results[i];
                                return ListTile(
                                  key: Key('manifest_pick_${p.hash}'),
                                  title: Text(p.name),
                                  subtitle: Text(
                                    p.subtitle?.isNotEmpty == true
                                        ? p.subtitle!
                                        : 'hash ${p.hash}',
                                  ),
                                  onTap: () {
                                    onPick(p);
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('manifest_pick_cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    queryController.dispose();
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
            const FlapBoardHeader(template: kFlapColumnsBuilds),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('builds_edit_armor_name'),
                  controller: _editArmorNameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Exotic armor (Manifest pick)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('builds_pick_exotic_armor'),
                onPressed: () => _openManifestPick(
                  kind: ManifestPickKind.exoticArmor,
                  onPick: (p) {
                    setState(() {
                      _editArmorHashController.text = '${p.hash}';
                      _editArmorNameController.text = p.name;
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('builds_edit_weapon_name'),
                  controller: _editWeaponNameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Exotic weapon (optional pick)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('builds_pick_exotic_weapon'),
                onPressed: () => _openManifestPick(
                  kind: ManifestPickKind.exoticWeapon,
                  onPick: (p) {
                    setState(() {
                      _editWeaponHashController.text = '${p.hash}';
                      _editWeaponNameController.text = p.name;
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('builds_edit_pinned_super'),
                  controller: _editPinnedSuperController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Pinned Super (Manifest pick)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('builds_pick_super'),
                onPressed: () => _openManifestPick(
                  kind: ManifestPickKind.superAbility,
                  onPick: (p) {
                    setState(() {
                      _editPinnedSuperController.text = p.name;
                    });
                  },
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Subclass kit',
            key: const Key('builds_subclass_kit_title'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _controller.subclassCapacityCaption,
            key: const Key('builds_subclass_capacity'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aspects: ${_controller.editSubclass.aspects.isEmpty ? '(none)' : _controller.editSubclass.aspects.join(', ')}',
            key: const Key('builds_subclass_aspects'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          Text(
            'Fragments: ${_controller.editSubclass.fragments.isEmpty ? '(none)' : _controller.editSubclass.fragments.join(', ')}',
            key: const Key('builds_subclass_fragments'),
          ),
          if (_controller.composeHardBlocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('builds_hard_blocks'),
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in _controller.composeHardBlocks)
                    Text(
                      '${b.code}: ${b.message}',
                      key: Key('builds_hard_block_${b.code}'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_controller.identityConfirmRequired) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('builds_identity_confirm_panel'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Identity change requires Confirm (in-place) or Fork (new build). '
                    'Fields: ${_controller.pendingIdentityFields?.join(', ')}',
                    key: const Key('builds_identity_confirm_message'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('builds_save_identity'),
            // Soft misses never disable Save; hard blocks do.
            onPressed: _controller.loading ||
                    _controller.identitySaveHardBlocked ||
                    _controller.identityConfirmRequired
                ? null
                : () => _saveIdentity(),
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
    return Column(
      key: const Key('builds_finish_gaps_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Finish readiness',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          kFinishGapsPolicyCaption,
          key: const Key('finish_gaps_policy'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (gaps == null)
          const Text(
            'Select a variant to evaluate finish gaps.',
            key: Key('finish_gaps_empty'),
          )
        else ...[
          Text(
            formatFinishGapsCompleteSummary(gaps),
            key: const Key('finish_gaps_complete_summary'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: gaps.complete
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
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
        ],
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

