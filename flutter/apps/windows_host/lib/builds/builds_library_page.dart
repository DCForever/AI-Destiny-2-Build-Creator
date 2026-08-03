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
import '../labels/product_labels.dart';
import '../optimizer/optimizer_controller.dart';
import '../optimizer/optimizer_workspace.dart';
import '../sets/set_catalog_picker.dart';
import 'builds_library_controller.dart';

part 'builds_library_page_rail.dart';
part 'builds_library_page_detail.dart';
part 'builds_library_page_compose.dart';
part 'builds_library_page_finish_embed.dart';

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
  /// Create intent plate: null = auto (open when library empty).
  bool? _createExpandedOverride;
  /// Finish policy copy behind progressive disclosure (shape P1).
  bool _finishPolicyExpanded = false;
  /// Optional identity pins (exotics/super): collapsed when empty by default.
  bool _optionalPinsExpanded = false;
  /// Subclass kit: collapsed when empty by default.
  bool _subclassKitExpanded = false;
  /// Synergy add row: hidden until user asks to add another type.
  bool _synergyAddExpanded = false;
  /// Loadout console step rail (build-basics mock): 1 identity · 2 loadout · 3 finish · 4 variants.
  int _buildDetailStep = 1;

  bool get _createExpanded =>
      _createExpandedOverride ??
      (_controller.builds.isEmpty && !_controller.loading);
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
      // Progressive disclosure: only open optional sections when they have data.
      final b = sel.build;
      final hasPin = (b.exoticArmorName != null && b.exoticArmorName!.isNotEmpty) ||
          b.exoticArmorHash != null ||
          (b.exoticWeaponName != null && b.exoticWeaponName!.isNotEmpty) ||
          b.exoticWeaponHash != null ||
          (b.pinnedSuper != null && b.pinnedSuper!.trim().isNotEmpty);
      final kit = _controller.editSubclass;
      final hasKit = kit.aspects.isNotEmpty || kit.fragments.isNotEmpty;
      _optionalPinsExpanded = hasPin;
      _subclassKitExpanded = hasKit;
      _synergyAddExpanded = false;
    } else if (sel == null) {
      _boundSelectionId = null;
      _boundSoftTargetsKey = null;
      _optionalPinsExpanded = false;
      _subclassKitExpanded = false;
      _synergyAddExpanded = false;
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

    // Intent brief: if chips empty, commit the current type dropdown (auto-Add).
    if (_controller.createDraftTypes.isEmpty) {
      _controller.addCreateDraftType(
        _createTypeWire,
        _createSubTypeController.text,
      );
      _createSubTypeController.clear();
    }
    if (_controller.createDraftTypes.isEmpty) {
      setState(
        () => _statusMessage = 'Add a synergy type (or pick one and Create)',
      );
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
          'Created ${nameText.isEmpty ? displayGuardianClass(_createClass) : nameText}';
      if (err == null) {
        _createExpandedOverride = false; // Board-first after success (shape brief).
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

  /// Section chrome: condensed title role from Flap tokens via theme.
  TextStyle? _sectionTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  TextStyle? _sectionLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 0.6,
          );

  TextStyle? _bodyMutedStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              padding: const EdgeInsets.fromLTRB(
                kPanelPadLg,
                kSpace8,
                kPanelPadLg,
                0,
              ),
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

}
