import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

// ---------------------------------------------------------------------------
// Fixed product states (dual-truth / residual)
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Instance strip multi-PL',
  type: WeaponInstanceStrip,
  path: '[Catalog]/Detail',
)
Widget instanceStrip(BuildContext context) {
  final instances = multiPowerInstances();
  return _InstanceStripHost(
    instances: instances,
    initialSelectedId: defaultHighestPowerInstanceId(instances),
  );
}

@widgetbook.UseCase(
  name: 'Owned · Possible rolls OFF (①+②)',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailOwnedCanRollOff(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kMidnightCoupBase,
      instances: multiPowerInstances(),
      showCanRoll: false,
      showCraft: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      plugEnhancedByHash: kPlugEnhancedByHash,
      familyMembers: midnightCoupFamily().members,
      onSelectFamilyMember: (_) {},
      showOwnedMetaMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Owned · Possible rolls ON (③ expand)',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailOwnedCanRollOn(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kMidnightCoupBase,
      instances: multiPowerInstances(),
      showCanRoll: true,
      showCraft: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      familyMembers: midnightCoupFamily().members,
      onSelectFamilyMember: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Unowned · POSSIBLE ROLLS only',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailUnowned(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kCerberusUnowned,
      instances: const [],
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      intrinsicName: kCerberusUnowned.intrinsicName,
      showOwnedMetaMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Perk grid ①②③ + enhanced note path',
  type: CatalogPerkGrid,
  path: '[Catalog]/Detail',
)
Widget perkGridMixed(BuildContext context) {
  final columns = buildCatalogPerkColumns(
    socketPlugs: kOwnedSocketPlugs,
    definitionSocketPlugs: kDefinitionSocketPlugs,
    plugNameByHash: {
      ...kPlugNameByHash,
      30: 'Enhanced Kill Clip',
    },
    plugIconByHash: kPlugIconByHash,
    plugEnhancedByHash: const {30: true},
    showCanRoll: true,
  );
  return Padding(
    padding: const EdgeInsets.all(12),
    child: SingleChildScrollView(
      child: CatalogPerkGrid(columns: columns),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Detail toggles craft hidden',
  type: CatalogDetailToggles,
  path: '[Catalog]/Detail',
)
Widget detailToggles(BuildContext context) {
  return const _TogglesDemo();
}

// ---------------------------------------------------------------------------
// Knobs — full interactive matrices (P0 Detail pack)
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'All knobs · instance strip',
  type: WeaponInstanceStrip,
  path: '[Catalog]/Detail/Knobs',
)
Widget knobsInstanceStrip(BuildContext context) {
  final empty = context.knobs.boolean(
    label: 'Empty (no copies)',
    initialValue: false,
  );
  final count = context.knobs.int.slider(
    label: 'Copy count',
    initialValue: 3,
    min: 1,
    max: 8,
  );
  final basePower = context.knobs.int.slider(
    label: 'Highest power',
    initialValue: 450,
    min: 200,
    max: 600,
  );
  final powerStep = context.knobs.int.slider(
    label: 'Power step between copies',
    initialValue: 10,
    min: 0,
    max: 50,
  );
  final baseTier = context.knobs.int.slider(
    label: 'Highest tier (T1–5)',
    initialValue: 5,
    min: 1,
    max: 5,
  );
  final special = context.knobs.object.dropdown<String>(
    label: 'Highest specialness',
    options: const ['(none)', 'Adept', 'Holofoil'],
    initialOption: 'Adept',
  );

  if (empty) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: WeaponInstanceStrip(
        instances: [],
        selectedInstanceId: null,
        onSelect: _noopSelect,
      ),
    );
  }

  final instances = _buildInstanceList(
    count: count,
    highestPower: basePower,
    powerStep: powerStep,
    baseTier: baseTier,
    highestSpecial: special == '(none)' ? null : special,
  );

  return _InstanceStripHost(
    instances: instances,
    initialSelectedId: defaultHighestPowerInstanceId(instances),
  );
}

@widgetbook.UseCase(
  name: 'All knobs · detail toggles',
  type: CatalogDetailToggles,
  path: '[Catalog]/Detail/Knobs',
)
Widget knobsDetailToggles(BuildContext context) {
  final craftAvailable = context.knobs.boolean(
    label: 'Craft available (show craft toggle)',
    initialValue: true,
  );
  final initialCanRoll = context.knobs.boolean(
    label: 'Initial Possible rolls ON',
    initialValue: false,
  );
  final initialCraft = context.knobs.boolean(
    label: 'Initial Possible crafted ON',
    initialValue: false,
  );

  return _TogglesKnobDemo(
    craftAvailable: craftAvailable,
    initialCanRoll: initialCanRoll,
    initialCraft: initialCraft,
  );
}

@widgetbook.UseCase(
  name: 'All knobs · perk grid',
  type: CatalogPerkGrid,
  path: '[Catalog]/Detail/Knobs',
)
Widget knobsPerkGrid(BuildContext context) {
  final empty = context.knobs.boolean(
    label: 'Empty plug data',
    initialValue: false,
  );
  final owned = context.knobs.boolean(
    label: 'Owned instance (①+②)',
    initialValue: true,
  );
  final showCanRoll = context.knobs.boolean(
    label: 'Possible rolls ON (③)',
    initialValue: true,
  );
  final showCraft = context.knobs.boolean(
    label: 'Craft pool ON',
    initialValue: false,
  );
  final enhancedSelected = context.knobs.boolean(
    label: 'Selected trait enhanced (gold)',
    initialValue: true,
  );
  final labelMode = context.knobs.object.dropdown<String>(
    label: 'Perk labels',
    options: const ['auto (B)', 'always', 'never'],
    initialOption: 'auto (B)',
  );
  final bool? showLabels = switch (labelMode) {
    'always' => true,
    'never' => false,
    _ => null,
  };

  if (empty) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: CatalogPerkGrid(columns: []),
    );
  }

  final craftColumns = showCraft
      ? [
          const CatalogPerkColumn(
            label: 'Trait',
            kind: 'trait',
            cells: [
              CatalogPerkCell(hash: 99, displayName: 'Enhanced Harmony'),
            ],
            canBeEnhanced: true,
          ),
        ]
      : const <CatalogPerkColumn>[];

  final columns = buildCatalogPerkColumns(
    socketPlugs: owned ? kOwnedSocketPlugs : null,
    definitionSocketPlugs: kDefinitionSocketPlugs,
    plugNameByHash: {
      ...kPlugNameByHash,
      if (enhancedSelected) 30: 'Enhanced Kill Clip',
    },
    plugIconByHash: kPlugIconByHash,
    plugEnhancedByHash: enhancedSelected ? const {30: true} : const {},
    showCanRoll: owned && showCanRoll,
    showCraft: showCraft,
    craftColumns: craftColumns,
  );

  return Padding(
    padding: const EdgeInsets.all(12),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (catalogColumnsCanBeEnhanced(columns))
            CatalogEnhanceNote(
              contextLabel: !owned
                  ? 'Definition pool'
                  : showCraft
                      ? 'Possible crafted'
                      : 'Possible rolls',
            ),
          CatalogPerkGrid(
            columns: columns,
            showLabels: showLabels,
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 003 CatalogRollTargets — desktop 400 + mobile 390
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Roll targets · desktop 400',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail/RollTargets',
)
Widget rollTargetsDesktop400(BuildContext context) {
  return _rollTargetsDetailFrame(
    context,
    width: kCatalogWeaponsDetailWidth,
    height: 720,
  );
}

@widgetbook.UseCase(
  name: 'Roll targets · mobile 390',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail/RollTargets',
)
Widget rollTargetsMobile390(BuildContext context) {
  return _rollTargetsDetailFrame(
    context,
    width: 390,
    height: 780,
  );
}

Widget _rollTargetsDetailFrame(
  BuildContext context, {
  required double width,
  required double height,
}) {
  final activeKnob = context.knobs.object.dropdown<String>(
    label: 'activeTarget',
    options: const ['none', 'pve', 'pvp'],
    initialOption: 'pve',
  );
  final showEditor = context.knobs.boolean(
    label: 'showEditor',
    initialValue: false,
  );
  final scorePreset = context.knobs.object.dropdown<String>(
    label: 'score',
    options: const ['partial', 'perfect', 'dirty'],
    initialOption: 'partial',
  );
  final instanceCount = context.knobs.int.slider(
    label: 'instanceCount',
    initialValue: 3,
    min: 0,
    max: 3,
  );
  final forceOverlap = context.knobs.boolean(
    label: 'editor overlap (soft)',
    initialValue: false,
  );

  final activeId = switch (activeKnob) {
    'pve' => 'rt-pve',
    'pvp' => 'rt-pvp',
    _ => null,
  };
  final activeName = switch (activeKnob) {
    'pve' => 'PvE',
    'pvp' => 'PvP',
    _ => null,
  };

  final rawInstances = rollTargetDemoInstances(count: instanceCount);
  final scores = activeId == null
      ? const <String, CatalogInstanceRollScore>{}
      : rollTargetScoresForPreset(scorePreset);
  final instances = activeId == null
      ? rawInstances
      : rankRollTargetDemoInstances(rawInstances, scores);

  Map<String, Set<int>> preferred = Map.from(kRollTargetPreferredByColumn);
  Map<String, Set<int>> avoid = Map.from(kRollTargetAvoidByColumn);
  if (forceOverlap && showEditor) {
    preferred = {
      'Trait': {30, 32},
    };
    avoid = {
      'Trait': {32},
    };
  }

  return SizedBox(
    width: width,
    height: height,
    child: _RollTargetsDetailHost(
      activeId: activeId,
      activeName: activeName,
      showEditor: showEditor,
      instances: instances,
      scores: scores,
      preferred: preferred,
      avoid: avoid,
      hasOverlap: forceOverlap && showEditor,
    ),
  );
}

@widgetbook.UseCase(
  name: 'All knobs · weapon detail',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail/Knobs',
)
Widget knobsWeaponDetail(BuildContext context) {
  final fixture = context.knobs.object.dropdown<String>(
    label: 'Item fixture',
    options: const [
      'Midnight Coup (owned)',
      'Ace of Spades (exotic)',
      'Cerberus+1 (unowned)',
      'Unsworn (trace)',
    ],
    initialOption: 'Midnight Coup (owned)',
  );
  final forceUnowned = context.knobs.boolean(
    label: 'Force unowned (no instances)',
    initialValue: false,
  );
  final instanceCount = context.knobs.int.slider(
    label: 'Instance count',
    initialValue: 3,
    min: 0,
    max: 6,
  );
  final showCanRoll = context.knobs.boolean(
    label: 'Possible rolls ON',
    initialValue: false,
  );
  final craftAvailable = context.knobs.boolean(
    label: 'Craft available',
    initialValue: false,
  );
  final showCraft = context.knobs.boolean(
    label: 'Possible crafted ON',
    initialValue: false,
  );
  final showOwnedMeta = context.knobs.boolean(
    label: 'Show owned meta ×N',
    initialValue: true,
  );
  final showFamily = context.knobs.boolean(
    label: 'Family version switcher',
    initialValue: true,
  );
  final enhancedTrait = context.knobs.boolean(
    label: 'Enhanced selected trait',
    initialValue: false,
  );

  final item = switch (fixture) {
    'Ace of Spades (exotic)' => kAceOfSpades,
    'Cerberus+1 (unowned)' => kCerberusUnowned,
    'Unsworn (trace)' => kUnsworn,
    _ => kMidnightCoupBase,
  };
  final unowned = forceUnowned || !item.owned || fixture.contains('unowned');
  final instances = unowned || instanceCount == 0
      ? const <CatalogInstanceProjection>[]
      : _buildInstanceList(
          count: instanceCount,
          highestPower: 450,
          powerStep: 10,
          baseTier: 5,
          highestSpecial: 'Adept',
          itemHash: item.hash,
        );

  final family = switch (fixture) {
    'Ace of Spades (exotic)' => groupWeaponFamilies([kAceOfSpades]).single,
    'Cerberus+1 (unowned)' => groupWeaponFamilies([kCerberusUnowned]).single,
    'Unsworn (trace)' => groupWeaponFamilies([kUnsworn]).single,
    _ => midnightCoupFamily(),
  };

  return _DetailKnobHost(
    item: item,
    instances: instances,
    showCanRoll: showCanRoll,
    showCraft: showCraft && craftAvailable,
    craftAvailable: craftAvailable,
    showOwnedMetaMark: showOwnedMeta,
    familyMembers: showFamily && family.members.length > 1
        ? family.members
        : const [],
    plugEnhancedByHash: enhancedTrait
        ? <int, bool>{30: true, ...kPlugEnhancedByHash}
        : kPlugEnhancedByHash,
    intrinsicName: item.intrinsicName,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _noopSelect(CatalogInstanceProjection _) {}

List<CatalogInstanceProjection> _buildInstanceList({
  required int count,
  required int highestPower,
  required int powerStep,
  int baseTier = 5,
  String? highestSpecial,
  int itemHash = 101,
}) {
  return [
    for (var i = 0; i < count; i++)
      catalogInstance(
        id: 'i-$i',
        power: highestPower - (i * powerStep),
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        gearTier: (baseTier - i).clamp(1, 5),
        specialLabel: i == 0 ? highestSpecial : null,
      ),
  ];
}

Widget _detailFrame(Widget child) {
  return SizedBox(
    width: kCatalogWeaponsDetailWidth,
    height: 720,
    child: child,
  );
}

class _InstanceStripHost extends StatefulWidget {
  const _InstanceStripHost({
    required this.instances,
    required this.initialSelectedId,
  });

  final List<CatalogInstanceProjection> instances;
  final String? initialSelectedId;

  @override
  State<_InstanceStripHost> createState() => _InstanceStripHostState();
}

class _InstanceStripHostState extends State<_InstanceStripHost> {
  late String? _selected = widget.initialSelectedId;

  @override
  void didUpdateWidget(covariant _InstanceStripHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instances != widget.instances ||
        oldWidget.initialSelectedId != widget.initialSelectedId) {
      final ids = widget.instances.map((e) => e.instanceId).toSet();
      if (_selected == null || !ids.contains(_selected)) {
        _selected = widget.initialSelectedId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WeaponInstanceStrip(
            instances: widget.instances,
            selectedInstanceId: _selected,
            onSelect: (i) => setState(() => _selected = i.instanceId),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Text(
              'Selected: $_selected',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _TogglesDemo extends StatefulWidget {
  const _TogglesDemo();

  @override
  State<_TogglesDemo> createState() => _TogglesDemoState();
}

class _TogglesDemoState extends State<_TogglesDemo> {
  var _canRoll = false;
  var _craft = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogDetailToggles(
            showCanRoll: _canRoll,
            showCraft: _craft,
            craftAvailable: false,
            onCanRollChanged: (v) => setState(() => _canRoll = v),
            onCraftChanged: (v) => setState(() => _craft = v),
          ),
          const SizedBox(height: 16),
          CatalogDetailToggles(
            showCanRoll: _canRoll,
            showCraft: _craft,
            craftAvailable: true,
            onCanRollChanged: (v) => setState(() => _canRoll = v),
            onCraftChanged: (v) => setState(() => _craft = v),
          ),
        ],
      ),
    );
  }
}

class _TogglesKnobDemo extends StatefulWidget {
  const _TogglesKnobDemo({
    required this.craftAvailable,
    required this.initialCanRoll,
    required this.initialCraft,
  });

  final bool craftAvailable;
  final bool initialCanRoll;
  final bool initialCraft;

  @override
  State<_TogglesKnobDemo> createState() => _TogglesKnobDemoState();
}

class _TogglesKnobDemoState extends State<_TogglesKnobDemo> {
  late var _canRoll = widget.initialCanRoll;
  late var _craft = widget.initialCraft;

  @override
  void didUpdateWidget(covariant _TogglesKnobDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCanRoll != widget.initialCanRoll) {
      _canRoll = widget.initialCanRoll;
    }
    if (oldWidget.initialCraft != widget.initialCraft) {
      _craft = widget.initialCraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CatalogDetailToggles(
        showCanRoll: _canRoll,
        showCraft: _craft,
        craftAvailable: widget.craftAvailable,
        onCanRollChanged: (v) => setState(() => _canRoll = v),
        onCraftChanged: (v) => setState(() => _craft = v),
      ),
    );
  }
}

class _DetailKnobHost extends StatefulWidget {
  const _DetailKnobHost({
    required this.item,
    required this.instances,
    required this.showCanRoll,
    required this.showCraft,
    required this.craftAvailable,
    required this.showOwnedMetaMark,
    required this.familyMembers,
    required this.plugEnhancedByHash,
    this.intrinsicName,
  });

  final CatalogItem item;
  final List<CatalogInstanceProjection> instances;
  final bool showCanRoll;
  final bool showCraft;
  final bool craftAvailable;
  final bool showOwnedMetaMark;
  final List<WeaponFamilyMember> familyMembers;
  final Map<int, bool> plugEnhancedByHash;
  final String? intrinsicName;

  @override
  State<_DetailKnobHost> createState() => _DetailKnobHostState();
}

class _DetailKnobHostState extends State<_DetailKnobHost> {
  late var _canRoll = widget.showCanRoll;
  late var _craft = widget.showCraft;
  late String? _selectedId =
      defaultHighestPowerInstanceId(widget.instances);
  late CatalogItem _item = widget.item;

  @override
  void didUpdateWidget(covariant _DetailKnobHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCanRoll != widget.showCanRoll) {
      _canRoll = widget.showCanRoll;
    }
    if (oldWidget.showCraft != widget.showCraft) {
      _craft = widget.showCraft;
    }
    if (oldWidget.item.hash != widget.item.hash ||
        oldWidget.instances != widget.instances) {
      _item = widget.item;
      _selectedId = defaultHighestPowerInstanceId(widget.instances);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _detailFrame(
      CatalogWeaponDetail(
        item: _item,
        instances: widget.instances,
        selectedInstanceId: _selectedId,
        onSelectInstance: (i) => setState(() => _selectedId = i.instanceId),
        showCanRoll: _canRoll,
        showCraft: _craft,
        craftAvailable: widget.craftAvailable,
        onCanRollChanged: (v) => setState(() => _canRoll = v),
        onCraftChanged: (v) => setState(() => _craft = v),
        definitionSocketPlugs: kDefinitionSocketPlugs,
        plugNameByHash: kPlugNameByHash,
        plugIconByHash: kPlugIconByHash,
        plugEnhancedByHash: widget.plugEnhancedByHash,
        familyMembers: widget.familyMembers,
        onSelectFamilyMember: widget.familyMembers.isEmpty
            ? null
            : (m) => setState(() => _item = m.item),
        showOwnedMetaMark: widget.showOwnedMetaMark,
        intrinsicName: widget.intrinsicName,
      ),
    );
  }
}

/// Interactive roll-target detail host for Widgetbook knobs (003).
class _RollTargetsDetailHost extends StatefulWidget {
  const _RollTargetsDetailHost({
    required this.activeId,
    required this.activeName,
    required this.showEditor,
    required this.instances,
    required this.scores,
    required this.preferred,
    required this.avoid,
    required this.hasOverlap,
  });

  final String? activeId;
  final String? activeName;
  final bool showEditor;
  final List<CatalogInstanceProjection> instances;
  final Map<String, CatalogInstanceRollScore> scores;
  final Map<String, Set<int>> preferred;
  final Map<String, Set<int>> avoid;
  final bool hasOverlap;

  @override
  State<_RollTargetsDetailHost> createState() => _RollTargetsDetailHostState();
}

class _RollTargetsDetailHostState extends State<_RollTargetsDetailHost> {
  late String? _activeId = widget.activeId;
  late String? _activeName = widget.activeName;
  late bool _editing = widget.showEditor;
  late Map<String, Set<int>> _preferred = Map.from(widget.preferred);
  late Map<String, Set<int>> _avoid = Map.from(widget.avoid);
  late String? _selected =
      defaultHighestPowerInstanceId(widget.instances);
  var _draftName = 'PvE';

  @override
  void didUpdateWidget(covariant _RollTargetsDetailHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) {
      _activeId = widget.activeId;
      _activeName = widget.activeName;
    }
    if (oldWidget.showEditor != widget.showEditor) {
      _editing = widget.showEditor;
    }
    if (oldWidget.preferred != widget.preferred ||
        oldWidget.avoid != widget.avoid) {
      _preferred = Map.from(widget.preferred);
      _avoid = Map.from(widget.avoid);
    }
    final ids = widget.instances.map((e) => e.instanceId).toSet();
    if (_selected == null || !ids.contains(_selected)) {
      _selected = defaultHighestPowerInstanceId(widget.instances);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _activeId != null;
    final scores = hasActive ? widget.scores : const <String, CatalogInstanceRollScore>{};
    final ranked = hasActive;
    final hasOverlap = catalogRollTargetHasOverlap(
      preferredByColumn: _preferred,
      avoidByColumn: _avoid,
    ) ||
        widget.hasOverlap;
    final canSave = _editing && _draftName.trim().isNotEmpty && !hasOverlap;

    return CatalogWeaponDetail(
      item: kMidnightCoupBase,
      instances: widget.instances,
      selectedInstanceId: _selected,
      onSelectInstance: (i) => setState(() => _selected = i.instanceId),
      showCanRoll: true,
      showCraft: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      rollTargets: kRollTargetOptions,
      activeRollTargetId: _activeId,
      activeRollTargetName: _activeName,
      onActiveRollTargetChanged: (id) {
        setState(() {
          _activeId = id;
          _activeName = id == null
              ? null
              : kRollTargetOptions
                  .firstWhere(
                    (t) => t.id == id,
                    orElse: () => const CatalogRollTargetOption(
                      id: '',
                      name: '',
                    ),
                  )
                  .name;
          if (_activeName != null && _activeName!.isEmpty) {
            _activeName = null;
          }
        });
      },
      instanceRollScores: scores,
      preserveInstanceOrder: ranked,
      rankedByRollTarget: ranked,
      editingRollTarget: _editing,
      onEditRollTarget: () => setState(() => _editing = true),
      onNewRollTarget: () => setState(() {
        _editing = true;
        _draftName = '';
        _preferred = {};
        _avoid = {};
      }),
      onDeleteRollTarget: _activeId != null ? () {} : null,
      canDeleteRollTarget: _activeId != null,
      rollTargetDraftName: _draftName,
      onRollTargetDraftNameChanged: (v) => setState(() => _draftName = v),
      rollTargetHasOverlap: hasOverlap,
      onSaveRollTarget: canSave ? () => setState(() => _editing = false) : null,
      onCancelRollTarget: () => setState(() => _editing = false),
      canSaveRollTarget: canSave,
      preferredByColumn: _preferred,
      avoidByColumn: _avoid,
      onCycleRollPlug: _editing
          ? (col, hash) {
              final mode = catalogRollPlugModeFor(
                columnKey: col,
                plugHash: hash,
                preferredByColumn: _preferred,
                avoidByColumn: _avoid,
              );
              final next = nextCatalogRollPlugMode(mode);
              final r = applyCatalogRollPlugMode(
                columnKey: col,
                plugHash: hash,
                mode: next,
                preferredByColumn: _preferred,
                avoidByColumn: _avoid,
              );
              setState(() {
                _preferred = r.preferredByColumn;
                _avoid = r.avoidByColumn;
              });
            }
          : null,
    );
  }
}
