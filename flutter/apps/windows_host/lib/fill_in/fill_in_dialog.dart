import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../builds_mock/builds_mock_models.dart';
import 'fill_in_build_mapper.dart';
import 'fill_in_cache_loader.dart';
import 'fill_in_labels.dart';

/// Injectable clipboard writer (tests capture text without OS clipboard).
typedef FillInClipboardWriter = Future<void> Function(String text);

/// Injectable missing-list saver (tests avoid real StorageRoot IO).
typedef FillInMissingListSaver = Future<void> Function(FillInSavedBuildPlan plan);

/// Called after Apply to build / Undo updates the app build copy.
typedef FillInBuildMutator = void Function(MockBuild updated);

Future<void> defaultFillInClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Opens the Fill In pop-up for [build].
///
/// Loads DIM armor + weapons caches, runs [matchFillIn], shows held / missing /
/// substitute diffs. **Apply to build** writes all total-fill slots into the
/// app copy; missing list stays saved. Never writes Bungie inventory.
///
/// When [dimLoadout] is set (matched compiled DIM link), exotic armor + items
/// enrich the build the same way the details panel reads EXOTIC.
Future<void> showFillInDialog({
  required BuildContext context,
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInClipboardWriter? clipboardWriter,
  FillInMissingListSaver? saveMissingList,
  VoidCallback? onMissingListSaved,
  FillInBuildMutator? onBuildUpdated,
  FillInSavedBuildPlan? existingPlan,
  GuardianClass guardianClass = GuardianClass.warlock,
  CachedDimLoadout? dimLoadout,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return FillInDialog(
        build: build,
        loadCaches: loadCaches,
        clipboardWriter: clipboardWriter ?? defaultFillInClipboardWriter,
        saveMissingList: saveMissingList,
        onMissingListSaved: onMissingListSaved,
        onBuildUpdated: onBuildUpdated,
        existingPlan: existingPlan,
        guardianClass: guardianClass,
        dimLoadout: dimLoadout,
      );
    },
  );
}

/// Fill In results dialog with Apply to build / Undo fill in.
class FillInDialog extends StatefulWidget {
  const FillInDialog({
    super.key,
    required this.build,
    required this.loadCaches,
    this.clipboardWriter = defaultFillInClipboardWriter,
    this.saveMissingList,
    this.onMissingListSaved,
    this.onBuildUpdated,
    this.existingPlan,
    this.guardianClass = GuardianClass.warlock,
    this.dimLoadout,
  });

  final MockBuild build;
  final FillInCacheLoader loadCaches;
  final FillInClipboardWriter clipboardWriter;
  final FillInMissingListSaver? saveMissingList;
  final VoidCallback? onMissingListSaved;
  final FillInBuildMutator? onBuildUpdated;
  final FillInSavedBuildPlan? existingPlan;
  final GuardianClass guardianClass;
  final CachedDimLoadout? dimLoadout;

  @override
  State<FillInDialog> createState() => _FillInDialogState();
}

class _FillInDialogState extends State<FillInDialog> {
  var _loading = true;
  var _saving = false;
  var _applying = false;
  String? _error;
  String? _saveMessage;
  FillInBuildResult? _result;
  List<FillInSlotMatch> _missing = const [];
  List<FillInSlotDiff> _diffs = const [];
  FillInSimilarWeapon? _similar;
  String? _missingWeaponName;
  late MockBuild _build;
  FillInSavedBuildPlan? _plan;

  /// Exact pre-Apply build snapshot for Undo (exotic weapon + slot + rows).
  /// Never reconstruct Undo from per-slot [FillInAppliedSlot.originalLabel]s.
  MockBuild? _undoBaseline;

  @override
  void initState() {
    super.initState();
    _build = enrichMockBuildFromDimLoadout(
      widget.build,
      loadout: widget.dimLoadout,
    );
    _plan = widget.existingPlan;
    _runMatch();
  }

  Future<void> _runMatch() async {
    final loaded = await widget.loadCaches();
    if (!mounted) return;
    if (!loaded.isOk) {
      setState(() {
        _loading = false;
        _error = loaded.errorMessage;
        _result = null;
        _missing = const [];
        _diffs = const [];
        _similar = null;
        _missingWeaponName = null;
      });
      return;
    }

    final mapped = mapMockBuildForFillIn(
      build: _build,
      inventory: loaded.items,
      guardianClass: widget.guardianClass,
      dimLoadout: widget.dimLoadout,
    );
    // Keep the dialog build in sync with DIM enrichment (exotic armor name).
    _build = enrichMockBuildFromDimLoadout(
      _build,
      loadout: widget.dimLoadout,
    );
    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    final result = report.builds.single;
    final missing = [
      for (final slot in result.slots)
        if (!slot.isHeld) slot,
    ];

    FillInSimilarWeapon? similar;
    String? missingWeaponName;
    FillInWeaponNeed? weaponNeed;
    final weaponMissing = missing.any(_isWeaponMatch);
    if (weaponMissing) {
      weaponNeed = fillInWeaponNeedForBuild(
        build: _build,
        inventory: loaded.items,
      );
      missingWeaponName = weaponNeed?.name ?? _build.exoticWeapon.trim();
      if (weaponNeed != null) {
        similar = suggestSimilarWeapon(
          need: weaponNeed,
          heldWeapons: loaded.items,
        );
      }
    }

    final currentLabels = <EquipmentSlot, String>{};
    for (final assignment in _build.slots) {
      final slot = EquipmentSlot.tryParse(assignment.slot) ??
          _slotFromMockWire(assignment.slot);
      if (slot != null) currentLabels[slot] = assignment.pieceName;
    }
    if (_build.exoticArmor.trim().isNotEmpty) {
      for (final assignment in _build.slots) {
        if (!assignment.isExoticSlot) continue;
        final slot = _slotFromMockWire(assignment.slot);
        if (slot != null && EquipmentSlot.armorSlots.contains(slot)) {
          currentLabels.putIfAbsent(slot, () => _build.exoticArmor.trim());
        }
      }
      currentLabels.putIfAbsent(
        EquipmentSlot.classItem,
        () => _build.exoticArmor.trim(),
      );
    }
    if (_build.exoticWeapon.trim().isNotEmpty) {
      final weaponSlot = _build.exoticWeaponSlot == null
          ? null
          : EquipmentSlot.tryParse(_build.exoticWeaponSlot!);
      currentLabels.putIfAbsent(
        weaponSlot ?? EquipmentSlot.special,
        () => _build.exoticWeapon.trim(),
      );
    }

    final diffs = planFillInSubstitutes(
      match: result,
      requirement: mapped.requirement,
      inventory: mapped.inventory,
      currentLabels: currentLabels,
      weaponNeed: weaponNeed,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _result = result;
      _missing = missing;
      _diffs = diffs;
      _similar = similar;
      _missingWeaponName =
          missingWeaponName?.isEmpty ?? true ? null : missingWeaponName;
    });
  }

  Future<void> _copyMissing() async {
    if (_missing.isEmpty) return;
    final lines = <String>[
      for (final slot in _missing) fillInSlotLabel(slot.slot),
    ];
    await widget.clipboardWriter(lines.join('\n'));
  }

  Future<void> _saveMissing() async {
    final save = widget.saveMissingList;
    if (save == null || _saving) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      final similar = _similar;
      final plan = FillInSavedBuildPlan(
        buildId: _build.id,
        missing: [
          for (final slot in _missing) fillInSlotLabel(slot.slot),
        ],
        similarWeaponName: similar?.item.name,
        similarForName: _missingWeaponName,
        applied: _plan?.applied ?? const [],
      );
      await save(plan);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _plan = plan;
        _saveMessage = 'Missing list saved on this build.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveMessage = 'Could not save missing list: $e';
      });
    }
  }

  Future<void> _applyToBuild() async {
    if (_applying) return;
    if (_diffs.isEmpty) {
      setState(() => _saveMessage = 'Nothing to apply.');
      return;
    }
    setState(() {
      _applying = true;
      _saveMessage = null;
    });

    // Snapshot exact pre-Apply build for Undo (weapon + slot + full row list).
    final baseline = _snapshotBuild(_build);

    var next = _build;
    final applied = <FillInAppliedSlot>[];
    final slotByWire = <String, MockSlotAssignment>{
      for (final s in next.slots) s.slot: s,
    };

    for (final diff in _diffs) {
      final label = diff.applyLabel;
      final original = diff.currentLabel;
      final instanceId = diff.applyInstanceId;
      final itemHash = diff.applyItemHash;
      final filled = diff.isHeld || diff.wouldSubstitute;

      applied.add(
        FillInAppliedSlot(
          slotWire: diff.slot.wireName,
          label: label,
          originalLabel: original,
          instanceId: instanceId,
          itemHash: itemHash,
        ),
      );

      if (_isWeaponSlot(diff.slot)) {
        // Never write wire placeholders (e.g. "heavy") as the exotic name.
        if (_isRealItemLabel(label) &&
            (diff.wouldSubstitute || next.exoticWeapon.trim().isEmpty)) {
          next = next.copyWith(
            exoticWeapon: label,
            exoticWeaponSlot: diff.slot.wireName,
          );
        }
        slotByWire[diff.slot.wireName] = MockSlotAssignment(
          slot: diff.slot.wireName,
          setId: slotByWire[diff.slot.wireName]?.setId ?? 'weapon',
          pieceName: label,
          isExoticSlot: true,
          filledIn: filled,
        );
        continue;
      }

      final existing = slotByWire[diff.slot.wireName];
      final isExotic = existing?.isExoticSlot ??
          (next.exoticArmor.trim().isNotEmpty &&
              _isRealItemLabel(label) &&
              label.trim().toLowerCase() ==
                  next.exoticArmor.trim().toLowerCase());
      slotByWire[diff.slot.wireName] = MockSlotAssignment(
        slot: diff.slot.wireName,
        setId: existing?.setId ?? (isExotic ? 'exotic' : 'fill_in'),
        pieceName: label,
        isExoticSlot: isExotic,
        filledIn: filled,
      );

      if (isExotic && _isRealItemLabel(label)) {
        next = next.copyWith(exoticArmor: label);
      }
    }

    next = next.copyWith(
      slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
    );

    final missingLabels = [
      for (final slot in _missing)
        if (!_diffs.any(
          (d) => d.slot == slot.slot && (d.wouldSubstitute || d.isHeld),
        ))
          fillInSlotLabel(slot.slot),
    ];

    final plan = FillInSavedBuildPlan(
      buildId: next.id,
      missing: missingLabels,
      similarWeaponName: _similar?.item.name,
      similarForName: _missingWeaponName,
      applied: List<FillInAppliedSlot>.unmodifiable(applied),
    );

    final save = widget.saveMissingList;
    try {
      if (save != null) await save(plan);
      widget.onBuildUpdated?.call(next);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _applying = false;
        _build = next;
        _plan = plan;
        _undoBaseline = baseline;
        _saveMessage = 'Applied to build.';
      });
      await _runMatch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _saveMessage = 'Could not apply to build: $e';
      });
    }
  }

  Future<void> _undoFillIn() async {
    final plan = _plan;
    final baseline = _undoBaseline;
    if (plan == null || !plan.hasAppliedSubstitutes || _applying) return;
    if (baseline == null) {
      setState(() => _saveMessage = 'Nothing to undo.');
      return;
    }
    setState(() {
      _applying = true;
      _saveMessage = null;
    });

    // Exact restore — do not reconstruct from per-slot originalLabel entries.
    final next = _snapshotBuild(baseline);

    final restored = plan.copyWith(clearApplied: true);
    final save = widget.saveMissingList;
    try {
      if (save != null) await save(restored);
      widget.onBuildUpdated?.call(next);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _applying = false;
        _build = next;
        _plan = restored;
        _undoBaseline = null;
        _saveMessage = 'Fill in undone.';
      });
      await _runMatch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _saveMessage = 'Could not undo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final build = _build;
    final hasApplied =
        (_plan?.hasAppliedSubstitutes ?? false) && _undoBaseline != null;
    final canApply = _diffs.isNotEmpty;
    return AlertDialog(
      key: Key('fill_in_dialog_${build.id}'),
      title: Text('Fill In — ${build.name}'),
      content: SizedBox(
        width: 440,
        child: _buildBody(context),
      ),
      actions: [
        if (hasApplied)
          TextButton(
            key: const Key('fill_in_undo'),
            onPressed: _applying ? null : _undoFillIn,
            child: const Text('Undo fill in'),
          ),
        if (canApply && widget.onBuildUpdated != null)
          FilledButton(
            key: const Key('fill_in_apply_to_build'),
            onPressed: (_applying || _loading) ? null : _applyToBuild,
            child: Text(_applying ? 'Applying…' : 'Apply to build'),
          ),
        if (_missing.isNotEmpty && widget.saveMissingList != null)
          TextButton(
            key: const Key('fill_in_save_missing'),
            onPressed: _saving ? null : _saveMissing,
            child: Text(_saving ? 'Saving…' : 'Save missing list'),
          ),
        if (_missing.isNotEmpty)
          TextButton(
            key: const Key('fill_in_copy_missing'),
            onPressed: _copyMissing,
            child: const Text('Copy missing list'),
          ),
        TextButton(
          key: const Key('fill_in_close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null) {
      return Text(
        _error!,
        key: const Key('fill_in_cache_error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    final result = _result;
    if (result == null) {
      return const Text('No Fill In result.', key: Key('fill_in_empty'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.hasSolipsismWarning) ...[
            Text(
              result.exoticArmorUnknown
                  ? "Exotic armor unknown: can't confirm Solipsism/Prismatic."
                  : 'Solipsism is flagged: subclass is not Prismatic.',
              key: const Key('fill_in_solipsism_flag'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          for (final diff in _diffs) ...[
            _DiffRow(
              diff: diff,
              match: _matchForSlot(result.slots, diff.slot),
              filledIn: _build.slots.any(
                (s) =>
                    s.filledIn &&
                    (_slotFromMockWire(s.slot) == diff.slot ||
                        s.slot == diff.slot.wireName),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_diffs.isEmpty)
            for (final slot in result.slots) ...[
              _SlotRow(match: slot),
              const SizedBox(height: 8),
            ],
          if (_similar != null) ...[
            const SizedBox(height: 4),
            Text(
              'Similar: ${_similar!.item.name}'
              '${_missingWeaponName == null ? '' : ' (for $_missingWeaponName)'}',
              key: const Key('fill_in_similar_weapon'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_saveMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _saveMessage!,
              key: const Key('fill_in_save_status'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (result.slots.isEmpty)
            const Text(
              'This build has no armor or exotic weapon slots to check.',
              key: Key('fill_in_no_slots'),
            ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.diff,
    required this.filledIn,
    this.match,
  });

  final FillInSlotDiff diff;
  final bool filledIn;
  final FillInSlotMatch? match;

  @override
  Widget build(BuildContext context) {
    final slotLabel = fillInSlotLabel(diff.slot);
    final overCap = match?.exceedsCap ?? false;
    final right = diff.wouldSubstitute
        ? diff.substituteLabel!
        : (diff.isHeld ? 'held' : 'missing');
    final chipState = overCap
        ? 'over cap'
        : (diff.isHeld
            ? 'held'
            : (diff.wouldSubstitute ? 'substitute' : 'missing'));
    return Row(
      key: Key('fill_in_diff_${diff.slot.wireName}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slotLabel, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${diff.currentLabel} → $right',
                key: Key('fill_in_diff_text_${diff.slot.wireName}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (match != null && !_isWeaponSlot(diff.slot) && match!.isHeld)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${match!.poolHeldCount}/${match!.cap}',
              key: Key('fill_in_held_count_${diff.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (match?.overCapLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              match!.overCapLabel!,
              key: Key('fill_in_over_cap_${diff.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (filledIn)
          Chip(
            key: Key('fill_in_filled_badge_${diff.slot.wireName}'),
            label: const Text('Filled in'),
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          )
        else
          Chip(
            key: Key('fill_in_chip_${diff.slot.wireName}_$chipState'),
            label: Text(chipState),
            visualDensity: VisualDensity.compact,
            backgroundColor: overCap
                ? Theme.of(context).colorScheme.errorContainer
                : null,
          ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.match});

  final FillInSlotMatch match;

  @override
  Widget build(BuildContext context) {
    final state = _stateLabel(match);
    final chipColor = _chipColor(context, match);
    return Row(
      key: Key('fill_in_slot_${match.slot.wireName}'),
      children: [
        Expanded(
          child: Text(
            fillInSlotLabel(match.slot),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (!_isWeaponMatch(match) && match.isHeld)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${match.poolHeldCount}/${match.cap}',
              key: Key('fill_in_held_count_${match.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (match.overCapLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              match.overCapLabel!,
              key: Key('fill_in_over_cap_${match.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        Chip(
          key: Key('fill_in_chip_${match.slot.wireName}_$state'),
          label: Text(state),
          visualDensity: VisualDensity.compact,
          backgroundColor: chipColor,
        ),
      ],
    );
  }
}

FillInSlotMatch? _matchForSlot(
  List<FillInSlotMatch> slots,
  EquipmentSlot slot,
) {
  for (final match in slots) {
    if (match.slot == slot) return match;
  }
  return null;
}

bool _isWeaponMatch(FillInSlotMatch match) {
  return _isWeaponSlot(match.slot);
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

/// Deep-ish copy used for Apply/Undo baselines (exact row list restore).
MockBuild _snapshotBuild(MockBuild build) {
  return MockBuild(
    id: build.id,
    name: build.name,
    subclass: build.subclass,
    exoticArmor: build.exoticArmor,
    exoticWeapon: build.exoticWeapon,
    slots: List<MockSlotAssignment>.unmodifiable([
      for (final s in build.slots) s.copyWith(),
    ]),
    loop: build.loop,
    artifact: build.artifact,
    setBonuses: build.setBonuses,
    stats: build.stats,
    splitWhy: build.splitWhy,
    creator: build.creator,
    dimLink: build.dimLink,
    exoticWeaponType: build.exoticWeaponType,
    exoticWeaponDamageType: build.exoticWeaponDamageType,
    exoticWeaponSlot: build.exoticWeaponSlot,
  );
}

/// True when [label] is a real item name, not an equipment wire placeholder
/// such as `heavy` / `primary` / `helmet` used when a slot has no piece yet.
bool _isRealItemLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  final lower = trimmed.toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return false;
  }
  return true;
}

EquipmentSlot? _slotFromMockWire(String wire) {
  switch (wire) {
    case 'helmet':
      return EquipmentSlot.helmet;
    case 'arms':
      return EquipmentSlot.arms;
    case 'chest':
      return EquipmentSlot.chest;
    case 'legs':
      return EquipmentSlot.legs;
    case 'class_item':
      return EquipmentSlot.classItem;
    default:
      return EquipmentSlot.tryParse(wire);
  }
}

String _stateLabel(FillInSlotMatch match) {
  if (match.exceedsCap) return 'over cap';
  if (match.isHeld) return 'held';
  return 'missing';
}

Color? _chipColor(BuildContext context, FillInSlotMatch match) {
  final scheme = Theme.of(context).colorScheme;
  if (match.exceedsCap) return scheme.errorContainer;
  if (match.isHeld) return scheme.secondaryContainer;
  return scheme.surfaceContainerHighest;
}
