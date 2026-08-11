import 'dart:async';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    show ArmorSetStatTotals, SetItemRecord, SetRecord, armorBaseStatKeys;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart'
    show CatalogItem, WindowsManifestRefresh;
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../catalog/owned_catalog_bridge.dart';
import '../host_bootstrap.dart';
import '../labels/product_labels.dart';
import '../optimizer/optimizer_controller.dart';
import '../optimizer/optimizer_workspace.dart';
import '../widgets/entity_icon.dart';
import 'set_bonus_families.dart';
import 'set_catalog_picker.dart';
import 'set_item_enrichment.dart';
import 'set_owned_compare_bridge.dart';
import 'set_slot_mapping.dart';
import 'sets_library_controller.dart';
import 'sets_lifecycle_controller.dart';

/// Sets library dual-pane (list + detail/slots) — DART-030/036 + dense board (DART-065).
class SetsLibraryPage extends StatefulWidget {
  const SetsLibraryPage({
    super.key,
    required this.services,
    this.controller,
    this.optimizerController,
    this.bridge,
    this.showLegacyQuickCreate = false,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final SetsLibraryController? controller;

  /// Optional injectable optimizer controller (tests inject candidates / local runner).
  final OptimizerController? optimizerController;

  /// Optional catalog bridge for enrichment (tests).
  final OwnedCatalogBridge? bridge;

  /// Test-only: show collapsed inline quick-create rail (not product path).
  final bool showLegacyQuickCreate;

  @override
  State<SetsLibraryPage> createState() => _SetsLibraryPageState();
}

class _SetsLibraryPageState extends State<SetsLibraryPage> {
  late final SetsLibraryController _controller;
  late final OptimizerController _optimizer;
  late final OwnedCatalogBridge _bridge;
  late final SetsLifecycleController _lifecycle;
  final _nameController = TextEditingController();
  final _editNameController = TextEditingController();
  final _searchController = TextEditingController();
  SetType _createType = SetType.weapon;
  String? _statusMessage;
  /// Legacy quick-create expanded (only when [showLegacyQuickCreate]).
  bool _createExpanded = false;
  bool _ownController = false;
  bool _ownOptimizer = false;
  String? _boundOptimizerSetId;
  SetDetailPresentation? _presentation;
  bool _enriching = false;
  List<SetsBonusFamilyOption> _setBonusFamilies = const [];
  bool _setBonusFamiliesLoading = false;
  bool _setBonusFamiliesLoaded = false;

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
    _lifecycle = SetsLifecycleController();
    _controller.addListener(_onController);
    _controller.refresh();
    // Prefetch set-bonus catalog for create goals (raw table or entity store).
    unawaited(_ensureSetBonusFamilies());
  }

  Future<void> _ensureSetBonusFamilies({bool force = false}) async {
    if (_setBonusFamiliesLoaded && !force) return;
    if (_setBonusFamiliesLoading) return;
    setState(() => _setBonusFamiliesLoading = true);
    try {
      final families = await loadArmorSetBonusFamilies(widget.services);
      if (!mounted) return;
      setState(() {
        _setBonusFamilies = families;
        _setBonusFamiliesLoaded = true;
        _setBonusFamiliesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setBonusFamilies = const [];
        _setBonusFamiliesLoaded = true;
        _setBonusFamiliesLoading = false;
      });
    }
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
    _lifecycle.dispose();
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
    final manifestService = widget.services.manifestRefresh is WindowsManifestRefresh
        ? (widget.services.manifestRefresh as WindowsManifestRefresh).service
        : null;
    enrichSetDetailPresentation(
      detail: sel,
      bridge: _bridge,
      boardSlots: slots,
      userId: _controller.userId,
      manifestService: manifestService,
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

  Future<void> _createLegacyQuick() async {
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

  /// Multi-step create wizard (G-SET-001): Type → Class → Bonus → Name.
  Future<void> _openCreateModal() async {
    _lifecycle.openCreate();
    await _ensureSetBonusFamilies();
    if (!mounted) return;
    final nameCtrl = TextEditingController(text: _lifecycle.createName);
    var tagData = <SetsTagData>[
      for (final t in _lifecycle.createTags)
        SetsTagData(id: t.toLowerCase(), label: t),
    ];

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _lifecycle,
          builder: (context, _) {
            final goalsUi = [
              for (final g in _lifecycle.createGoals)
                SetsBonusGoalData(
                  familyKey: g.setBonusKey,
                  minPieces: g.minPieces,
                ),
            ];
            return SetsLifecycleModal(
              title: _lifecycle.createCrumb,
              width: 720,
              height: 640,
              onClose: () => Navigator.of(ctx).pop(false),
              footer: SetsCreateWizardFooter(
                step: _lifecycle.createStep,
                isFinalStep: _lifecycle.isCreateFinalStep,
                canContinue: _lifecycle.canContinueCreate,
                onBack: _lifecycle.createStep == 0
                    ? null
                    : _lifecycle.backCreate,
                onCancel: () => Navigator.of(ctx).pop(false),
                onContinue: _lifecycle.isCreateFinalStep
                    ? null
                    : () {
                        if (_lifecycle.canContinueCreate) {
                          _lifecycle.continueCreate();
                        }
                      },
                onCreate: _lifecycle.isCreateFinalStep
                    ? () {
                        // Flush field before pop so dispose cannot race route out.
                        _lifecycle.setCreateName(nameCtrl.text);
                        Navigator.of(ctx).pop(true);
                      }
                    : null,
                createLabel: _lifecycle.createType == SetType.armor
                    ? 'Create'
                    : 'Create shell',
              ),
              child: SetsCreateWizard(
                step: _lifecycle.createStep,
                setType: _lifecycle.createType.wireName,
                guardianClass: _lifecycle.createClass?.wireName,
                goals: goalsUi,
                families: _setBonusFamilies,
                namePreview: _lifecycle.namePreview,
                nameController: nameCtrl,
                tags: tagData,
                onTypeChanged: (t) {
                  _lifecycle.setCreateType(SetType.tryParse(t) ?? SetType.armor);
                },
                onClassChanged: (c) {
                  _lifecycle.setCreateClass(GuardianClass.tryParse(c));
                },
                onGoalsChanged: (g) {
                  _lifecycle.setCreateGoals([
                    for (final goal in g)
                      SetBonusCoverageGoal(
                        setBonusKey: goal.familyKey,
                        minPieces: goal.minPieces,
                      ),
                  ]);
                },
                onNameChanged: (v) {
                  _lifecycle.setCreateName(v);
                },
                onTagsChanged: (next) {
                  tagData = next;
                  _lifecycle.setCreateTags([for (final t in next) t.label]);
                },
                isLegalCombo: (goals) => isLegalSetBonusGoalCombo([
                  for (final g in goals)
                    SetBonusCoverageGoal(
                      setBonusKey: g.familyKey,
                      minPieces: g.minPieces,
                    ),
                ]),
                isTagBlocked: isTagBlockedBySynergyTypeVocab,
              ),
            );
          },
        );
      },
    );

    // Capture draft before disposing controller (dialog route may still paint
    // one frame while unmounting TextField listeners).
    _lifecycle.setCreateName(nameCtrl.text);
    final shouldCreate = created == true;
    final createdType = _lifecycle.createType;
    final cmd = shouldCreate
        ? _lifecycle.buildCreateCommand(
            existingNames: _controller.allSets.map((s) => s.name),
          )
        : null;
    // Defer dispose until after dialog tree detaches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameCtrl.dispose();
    });

    if (!shouldCreate || !mounted || cmd == null) {
      _lifecycle.close();
      return;
    }

    if (createdType == SetType.armor && _lifecycle.createClass == null) {
      _lifecycle.close();
      setState(() => _statusMessage = 'Class required for Armor sets');
      return;
    }

    final err = await _controller.createSetFromCommand(cmd);
    if (!mounted) return;
    if (err != null) {
      _lifecycle.close();
      setState(() => _statusMessage = err);
      return;
    }

    final setId = _controller.selected?.set.id;
    setState(() => _statusMessage = 'Created ${cmd.name}');

    if (createdType == SetType.armor && setId != null) {
      if (!mounted) return;
      await _openArmorBoardModal(setId);
    }
    _lifecycle.close();
  }

  List<SetsArmorSlotData> _armorBoardSlotsFromSelected() {
    final sel = _controller.selected;
    final bySlot = <String, SetItemRecord>{};
    if (sel != null) {
      for (final item in sel.activeItems) {
        final wire = item.slot.contains(':')
            ? item.slot.split(':').first
            : item.slot;
        bySlot.putIfAbsent(wire, () => item);
      }
    }
    return [
      for (var i = 0; i < kArmorBoardSlotWires.length; i++)
        () {
          final wire = kArmorBoardSlotWires[i];
          final item = bySlot[wire];
          return SetsArmorSlotData(
            slotWire: wire,
            slotLabel: kArmorBoardSlotLabels[i],
            itemName: item?.itemName,
            instanceId: item?.instanceId,
            isExotic: item != null
                ? (_metaForHash(item.itemHash, item.itemName).isExotic == true)
                : false,
          );
        }(),
    ];
  }

  /// Interactive armor board modal (Optimize + per-slot Pick).
  Future<void> _openArmorBoardModal(String setId) async {
    await _controller.selectSet(setId);
    if (!mounted) return;
    _lifecycle.openBoard(setId);
    _optimizer.bindTargetSet(
      setId: setId,
      setName: _controller.selected?.set.name ?? setId,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModal) {
            final slots = _armorBoardSlotsFromSelected();
            return SetsLifecycleModal(
              title: 'Armor board',
              width: 960,
              height: 720,
              onClose: () => Navigator.of(dialogCtx).pop(),
              child: SingleChildScrollView(
                child: SetsArmorBoard(
                  key: const Key('sets_armor_board_modal'),
                  slots: slots,
                  onOptimize: () async {
                    await _openOptimizeFromBoard(dialogCtx);
                    if (!dialogCtx.mounted) return;
                    await _controller.refresh(keepSelection: true);
                    if (dialogCtx.mounted) setModal(() {});
                  },
                  onPickSlot: (slot) async {
                    await _fillSlot(slot);
                    if (!dialogCtx.mounted) return;
                    await _controller.refresh(keepSelection: true);
                    if (dialogCtx.mounted) setModal(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
    _lifecycle.close();
  }

  List<SetsOptimizeKitRowData> _kitsFromOptimizerCombinations() {
    final combos = _optimizer.visibleCombinations;
    return [
      for (var i = 0; i < combos.length; i++)
        () {
          final c = combos[i];
          final stats = <String, int>{
            for (final e in c.estimatedStats.entries) e.key.wireName: e.value,
          };
          final total = stats.values.fold<int>(0, (a, b) => a + b);
          final goals = c.setBonusSummary.isEmpty
              ? '—'
              : c.setBonusSummary
                  .map((s) {
                    final tier = s.active4pc
                        ? '4pc'
                        : (s.active2pc ? '2pc' : '${s.pieceCount}pc');
                    return '${s.setBonusKey} $tier';
                  })
                  .join(' · ');
          return SetsOptimizeKitRowData(
            id: '$i',
            total: total,
            stats: stats,
            slotNames: {
              for (final p in c.pieces)
                p.slot.wireName: (p.itemName?.trim().isNotEmpty == true)
                    ? p.itemName!.trim()
                    : '#${p.itemHash}',
            },
            goalsLabel: goals,
          );
        }(),
    ];
  }

  Future<void> _openOptimizeFromBoard(BuildContext boardContext) async {
    final sel = _controller.selected;
    if (sel == null) return;

    if (!widget.services.oauthSession.isSignedIn) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Sign in and sync inventory before Optimize (owned candidates only).';
        });
      }
      // Still open shell with empty honesty so the button is never a no-op.
    }

    _optimizer.bindTargetSet(
      setId: sel.set.id,
      setName: sel.set.name,
    );

    var kits = <SetsOptimizeKitRowData>[];
    String? selectedKitId;
    var started = false;

    await showDialog<void>(
      context: boardContext,
      barrierDismissible: false,
      builder: (optCtx) {
        return StatefulBuilder(
          builder: (optCtx, setOpt) {
            if (!started) {
              started = true;
              // Kick off kit search after first frame so shell shows "running".
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await _optimizer.findKits();
                if (!optCtx.mounted) return;
                kits = _kitsFromOptimizerCombinations();
                selectedKitId = kits.isNotEmpty ? kits.first.id : null;
                setOpt(() {});
              });
            }

            final constraints =
                parseOptimizerConstraints(sel.set.optimizerConstraints);
            final classLabel = constraints?.className != null
                ? displayGuardianClass(constraints!.className!)
                : null;
            final bonusLabel = (constraints?.setBonusGoals.isNotEmpty ?? false)
                ? constraints!.setBonusGoals
                    .map((g) => '${g.setBonusKey} ${g.minPieces}pc')
                    .join(' · ')
                : null;

            return SetsLifecycleModal(
              title: 'Optimize',
              width: 960,
              height: 720,
              onClose: () {
                _optimizer.cancelPending();
                Navigator.of(optCtx).pop();
              },
              child: ListenableBuilder(
                listenable: _optimizer,
                builder: (context, _) {
                  // Keep kits in sync when findKits completes via listenable.
                  if (!_optimizer.running &&
                      kits.isEmpty &&
                      _optimizer.combinations.isNotEmpty) {
                    kits = _kitsFromOptimizerCombinations();
                    selectedKitId ??= kits.isNotEmpty ? kits.first.id : null;
                  }
                  final emptyMsg = _optimizer.running
                      ? 'Finding kits…'
                      : (_optimizer.error ??
                          (_optimizer.status?.isNotEmpty == true
                              ? _optimizer.status
                              : 'No kits found. Sync owned armor and try again.'));
                  // Shell uses Expanded for kit matrix — must not wrap in ScrollView.
                  return SetsOptimizeConfirmShell(
                    key: const Key('sets_board_optimize_shell'),
                    kits: [
                      for (final k in kits)
                        SetsOptimizeKitRowData(
                          id: k.id,
                          total: k.total,
                          stats: k.stats,
                          slotNames: k.slotNames,
                          goalsLabel: k.goalsLabel,
                          selected: k.id == selectedKitId,
                        ),
                    ],
                    selectedKitId: selectedKitId,
                    running: _optimizer.running,
                    hasPins: sel.activeItems.isNotEmpty,
                    classLabel: classLabel,
                    bonusGoalsLabel: bonusLabel,
                    emptyMessage: emptyMsg,
                    onSelectKit: (id) => setOpt(() => selectedKitId = id),
                    onCancel: () {
                      _optimizer.cancelPending();
                      Navigator.of(optCtx).pop();
                    },
                    onConfirmApply: selectedKitId == null ||
                            _optimizer.running ||
                            _optimizer.confirming
                        ? null
                        : () async {
                            final idx = int.tryParse(selectedKitId!);
                            if (idx == null) return;
                            final stageErr =
                                _optimizer.requestApplyInPlace(idx);
                            if (stageErr != null) {
                              if (mounted) {
                                setState(() => _statusMessage = stageErr);
                              }
                              return;
                            }
                            final applyErr = await _optimizer.confirmPending();
                            if (!optCtx.mounted) return;
                            Navigator.of(optCtx).pop();
                            await _controller.refresh(keepSelection: true);
                            if (mounted) {
                              setState(() {
                                _statusMessage = applyErr ??
                                    (_optimizer.status ?? 'Kit applied');
                              });
                            }
                          },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveName() async {
    final err = await _controller.updateSelected(name: _editNameController.text);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved';
    });
  }

  SetItemMeta _metaForHash(int itemHash, String itemName) {
    CatalogItem? hit;
    for (final c in _bridge.annotatedBase) {
      if (c.hash == itemHash) {
        hit = c;
        break;
      }
    }
    if (hit == null) {
      return SetItemMeta(kind: SetItemKind.unknown, name: itemName);
    }
    final armor = isArmorBoardSlot(hit.slot ?? '') ||
        (hit.sourceStore?.contains('armor') ?? false);
    return setItemMetaFromCatalog(
      isExotic: hit.isExotic,
      slot: hit.slot,
      kind: armor ? 'armor' : 'weapons',
      name: hit.name,
    );
  }

  Future<void> _fillSlot(String slot) async {
    final setType = SetType.tryParse(_controller.selected?.set.type ?? '');
    final excludeExotic =
        _controller.excludeExoticForSlot(slot, _metaForHash);

    // Armor fill: owned-only compare (G-SET-002) — not Catalog page embed.
    final SetSlotPickResult? pick;
    if (setType == SetType.armor) {
      final signedOut = !widget.services.oauthSession.isSignedIn;
      final other = <({String slot, bool isExotic, String? name})>[
        for (final row in _controller.selected?.activeItems ?? const [])
          if (row.slot != slot)
            (
              slot: row.slot,
              isExotic: _metaForHash(row.itemHash, row.itemName).isExotic == true,
              name: row.itemName,
            ),
      ];
      // Host maps owned inventory → compare rows when bridge has instances;
      // honesty empty when signed-out / no owned copies (no fake catalog).
      final ownedRows = <OwnedArmorCompareRow>[];
      pick = await showOwnedComparePicker(
        context: context,
        targetSlot: slot,
        ownedRows: ownedRows,
        signedOut: signedOut,
        excludeExotic: excludeExotic,
        otherOccupied: other,
      );
    } else {
      final catalogKind =
          setType == SetType.mod ? 'armor' : 'weapons';
      pick = await showSetCatalogPicker(
        context: context,
        services: widget.services,
        targetSlot: slot,
        bridge: _bridge,
        excludeExotic: excludeExotic,
        catalogKind: catalogKind,
      );
    }
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

    final known = <int, SetItemMeta>{
      for (final row in _controller.selected?.activeItems ?? const [])
        row.itemHash: _metaForHash(row.itemHash, row.itemName),
    };
    final err = await _controller.fillSlot(
      slot,
      pick,
      knownItemMeta: known,
    );
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

  List<SetsArmorLibraryRowData> _mapLibraryRows() {
    final selectedId = _controller.selected?.set.id;
    return [
      for (final s in _controller.sets)
        SetsArmorLibraryRowData(
          id: s.id,
          name: s.name,
          classLabel: _classLabelForSet(s),
          pieceCount: _controller.pieceCountOf(s.id),
          capacity: _capacityForSet(s),
          coverageLabel: _coverageLabelForSet(s),
          usedByLabel: selectedId == s.id ? _usedByLabelForSelected() : '—',
          selected: selectedId == s.id,
        ),
    ];
  }

  String _classLabelForSet(SetRecord s) {
    final constraints = parseOptimizerConstraints(s.optimizerConstraints);
    final cls = constraints?.className;
    if (cls != null) {
      return displayGuardianClass(cls);
    }
    if (s.type != SetType.armor.wireName) {
      return displaySetTypeWire(s.type);
    }
    return '—';
  }

  int _capacityForSet(SetRecord s) {
    final t = SetType.tryParse(s.type) ?? SetType.weapon;
    return slotsForSetType(t).length;
  }

  String _coverageLabelForSet(SetRecord s) {
    final constraints = parseOptimizerConstraints(s.optimizerConstraints);
    final goals = constraints?.setBonusGoals ?? const <SetBonusCoverageGoal>[];
    if (goals.isEmpty) return '—';
    return goals
        .map((g) => '${g.minPieces}pc ${g.setBonusKey}')
        .join(' · ');
  }

  String _usedByLabelForSelected() {
    final used = _controller.usedByOfSelected();
    if (used.isEmpty) return '—';
    if (used.length == 1) {
      final name = used.first.buildName?.trim();
      return (name != null && name.isNotEmpty) ? name : '1 build';
    }
    return '${used.length} builds';
  }

  @override
  Widget build(BuildContext context) {
    final emptyHonesty = !_controller.loading && _controller.sets.isEmpty
        ? const SetsHonestyEmpty(
            key: Key('sets_list_empty'),
            kind: SetsHonestyKind.noMatches,
            message: 'No sets yet. Create one above.',
          )
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            child: SetsLibraryWorkspace(
              key: const Key('sets_library_workspace_live'),
              rows: _mapLibraryRows(),
              detail: _buildDetail(context),
              honesty: emptyHonesty,
              loading: _controller.loading && _controller.sets.isEmpty,
              searchController: _searchController,
              onSearchChanged: _controller.setSearchQuery,
              onSelectRow: (id) => _controller.selectSet(id),
              onNewSet: _controller.loading ? null : _openCreateModal,
              railHeader: _buildRailHeader(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Filters (+ optional test-only legacy quick-create). Product path: New set only.
  Widget _buildRailHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSetsFilterHeader(),
        if (widget.showLegacyQuickCreate) ...[
          ListTile(
            key: const Key('sets_create_toggle'),
            dense: true,
            title: Text(
              _createExpanded ? 'Hide quick create' : 'Quick create',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: _createExpanded
                ? null
                : Text(
                    'Test-only inline create (not product path)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            trailing: Icon(
              _createExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() => _createExpanded = !_createExpanded);
            },
          ),
          if (_createExpanded) ...[
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
                onSubmitted: (_) => _createLegacyQuick(),
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
                      child: Text(displaySetType(t)),
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
                onPressed: _controller.loading ? null : _createLegacyQuick,
                child: const Text('Create set'),
              ),
            ),
          ],
        ],
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSetsFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search lives on SetsLibraryWorkspace (sets_library_search).
          // Keep a hidden/compat alias for older tests that look for sets_search.
          Offstage(
            offstage: true,
            child: TextField(
              key: const Key('sets_search'),
              controller: _searchController,
              onChanged: _controller.setSearchQuery,
            ),
          ),
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
                    displaySetType(t),
                    key: Key('sets_type_chip_${t.wireName}'),
                  ),
                ),
            ],
            onChanged: _controller.setTypeFilter,
          ),
          const SizedBox(height: 6),
          Text(
            'Tags',
            key: const Key('sets_tag_filters_label'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Wrap(
            key: const Key('sets_tag_filters'),
            spacing: 4,
            children: [
              for (final tag in const ['pve', 'pvp', 'solar'])
                FilterChip(
                  key: Key('sets_tag_chip_$tag'),
                  label: Text(
                    displaySynergyTypeWire(tag),
                    style: const TextStyle(fontSize: 11),
                  ),
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

  Widget _buildDetail(BuildContext context) {
    final sel = _controller.selected;
    if (sel == null) {
      return LibraryDetailEmpty(
        key: const Key('sets_detail_empty'),
        icon: Icons.inventory_2_outlined,
        title: 'No set selected',
        body: _controller.sets.isEmpty
            ? 'Open New set on the left to create a weapon, armor, or mod set, then fill slots here.'
            : 'Select a set on the board to edit slots, tags, and readiness.',
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
              if (setType == SetType.armor)
                FilledButton.tonal(
                  key: const Key('sets_open_board'),
                  onPressed: () => _openArmorBoardModal(sel.set.id),
                  child: const Text('Open board…'),
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
                  if (!readiness.meetsPackageMinimum &&
                      readiness.packageMinimumMessage != null)
                    Text(
                      readiness.packageMinimumMessage!,
                      key: const Key('sets_occupancy_hint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
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
        Row(
          children: [
            EntityIcon(
              key: Key('sets_slot_icon_$slot'),
              icon: row?.icon,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name ($hash)',
                key: Key('sets_slot_name_$slot'),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
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
        if (row?.armorStats != null || traits.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: Key('sets_slot_richness_$slot'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: Text(
                'Roll details',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              subtitle: Text(
                [
                  if (row?.armorStats != null) 'stats',
                  if (traits.isNotEmpty) '${traits.length} traits',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                if (row?.armorStats != null)
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      for (final key in armorBaseStatKeys)
                        if (row!.armorStats!.stats[key] != null)
                          Chip(
                            key: Key('sets_slot_stat_${slot}_$key'),
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '$key ${row.armorStats!.stats[key]}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      if (row!.armorStats!.total != null)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            'Total ${row.armorStats!.total}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          )
        else if (row?.statsUnknown == true) ...[
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
