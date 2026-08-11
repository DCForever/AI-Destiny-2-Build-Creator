import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'sets/sets_armor_capture_fixtures.dart';
import 'theme/flap_theme.dart';

/// Sets Armor + Create wizard dual-truth Capture entrypoint (`drive: host-fixture`).
///
/// Scenario rail keys: `capture_scenario_<matrix-id>` — tap then screenshot.
/// Writes under:
/// - `docs/ux-redesign/sets/implementation-shots/001-armor/`
/// - `docs/ux-redesign/sets/implementation-shots/002-create-wizard/`
///
/// ```text
/// flutter run -d windows -t lib/main_sets_armor_capture.dart
/// ```
///
/// Ship widgets only (SetsLibraryWorkspace / SetsCreateWizard / SetsArmorBoard /
/// SetsOwnedCompareTable / SetsOptimizeConfirmShell / SetsDeleteConfirm /
/// SetsHonestyEmpty). Host god-page residual is a COMPARE note, not this harness.
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_sets_armor_capture: Flutter Driver on · sets armor host-fixture scenarios',
  );
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SetsArmorCaptureApp());
}

class SetsArmorCaptureApp extends StatelessWidget {
  const SetsArmorCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sets Armor capture',
      debugShowCheckedModeBanner: true,
      theme: buildFlapTheme(),
      home: const SetsArmorCaptureHome(),
    );
  }
}

class SetsArmorCaptureHome extends StatefulWidget {
  const SetsArmorCaptureHome({super.key});

  @override
  State<SetsArmorCaptureHome> createState() => _SetsArmorCaptureHomeState();
}

class _SetsArmorCaptureHomeState extends State<SetsArmorCaptureHome> {
  String _scenario = kSetsArmorMustShotIds.first;

  void _selectScenario(String id) {
    setState(() => _scenario = id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Scaffold(
      key: const Key('sets_armor_capture_root'),
      backgroundColor: palette.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: palette.surfaceRaised,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  for (final id in kSetsArmorCaptureMatrixIds) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        key: Key('capture_scenario_$id'),
                        label: Text(
                          id.replaceFirst('desktop-', ''),
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: _scenario == id,
                        onSelected: (_) => _selectScenario(id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: palette.line),
          Expanded(
            child: KeyedSubtree(
              key: Key('capture_body_$_scenario'),
              child: _buildScenario(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenario(BuildContext context) {
    switch (_scenario) {
      case 'desktop-library-armor':
        return SetsLibraryWorkspace(
          rows: fixtureLibraryArmorRows(),
          onNewSet: () {},
          onSelectRow: (_) {},
          detail: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Raid Titan · TechSec'),
                SizedBox(height: 8),
                Text('Titan · 4 pcs · TechSec 2pc'),
                SizedBox(height: 8),
                Text('Used by: Main · default'),
                SizedBox(height: 12),
                SetsModSetDeepLink(
                  linkedModSetId: 'mod-1',
                  linkedModSetName: 'Raid mods',
                ),
              ],
            ),
          ),
        );
      case 'desktop-signed-out-honesty':
        return const SetsHonestyEmpty(
          kind: SetsHonestyKind.signedOut,
          message:
              'Sign in to manage owned armor sets. Owned scope never invents inventory.',
        );
      case 'desktop-create-type-class':
        // Legacy 001 id: step 0 type chrome (pieces hidden sentinel).
        return _createStepShell(
          context,
          step: 0,
          setType: 'armor',
          guardianClass: null,
        );
      case 'desktop-create-step-type':
        return _createStepShell(
          context,
          step: 0,
          setType: 'armor',
          guardianClass: null,
        );
      case 'desktop-create-step-class':
        return _createStepShell(
          context,
          step: 1,
          setType: 'armor',
          guardianClass: null,
        );
      case 'desktop-create-step-bonus':
        return _createStepShell(
          context,
          step: 2,
          setType: 'armor',
          guardianClass: 'Titan',
          families: const [
            SetsBonusFamilyOption(
              name: 'TechSec',
              twoPcDescription: 'Weapon damage after ability kill.',
              fourPcDescription: 'Ability energy on orb pickup.',
            ),
            SetsBonusFamilyOption(
              name: 'Twofer',
              twoPcDescription: 'Reload speed after kill.',
            ),
          ],
        );
      case 'desktop-create-step-name':
        return _createStepShell(
          context,
          step: 3,
          setType: 'armor',
          guardianClass: 'Titan',
          namePreview: 'Titan · — · —',
        );
      case 'desktop-create-post-board':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SetsArmorBoard(
            slots: fixtureEmptyBoardSlots(),
            onOptimize: () {},
            onPickSlot: (_) {},
          ),
        );
      case 'desktop-create-no-quick-create':
        // Library New only — no Quick create rail chrome.
        return SetsLibraryWorkspace(
          rows: fixtureLibraryArmorRows(),
          onNewSet: () {},
          onSelectRow: (_) {},
          detail: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Product path: New set opens stepped wizard (no Quick create).'),
          ),
        );
      case 'desktop-create-non-armor-thin':
        return _createStepShell(
          context,
          step: 1,
          setType: 'weapon',
          guardianClass: null,
        );
      case 'desktop-empty-board':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SetsArmorBoard(
            slots: fixtureEmptyBoardSlots(),
            onOptimize: () {},
            onPickSlot: (_) {},
          ),
        );
      case 'desktop-filled-board-coverage':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SetsArmorBoard(
            slots: fixtureFilledBoardSlots(),
            coverage: fixtureCoverageBand(),
            onOptimize: () {},
            onPickSlot: (_) {},
            showEnergyMods: false,
          ),
        );
      case 'desktop-owned-compare':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SetsOwnedCompareTable(
            rows: fixtureOwnedComparePresentationRows(),
            onSelect: (_) {},
          ),
        );
      case 'desktop-optimize-confirm':
        // Shell uses Expanded for the kit matrix — needs bounded height, not
        // SingleChildScrollView (unbounded height → size MISSING / hit-test fail).
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SetsOptimizeConfirmShell(
            kits: fixtureOptimizeKits(),
            selectedKitId: 'kit-a',
            hasPins: true,
            classLabel: 'Titan',
            exoticLabel: 'current',
            bonusGoalsLabel: 'TechSec 2pc',
            onSelectKit: (_) {},
            onConfirmApply: () {},
            onCancel: () {},
          ),
        );
      case 'desktop-delete-set-in-use':
        return Center(
          child: SetsDeleteConfirm(
            setName: 'Raid Titan · TechSec',
            usedBy: const [
              SetsUsedByData(
                buildId: 'b1',
                variantId: 'default',
                buildName: 'Main',
              ),
            ],
            onCancel: () {},
          ),
        );
      case 'desktop-tags-blocked':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SetsTagMultiSelect(
            selected: const [
              SetsTagData(id: 'raid', label: 'raid'),
              SetsTagData(id: 'pinnacle', label: 'pinnacle'),
            ],
            suggestions: const [
              SetsTagData(id: 'techsec', label: 'TechSec', blocked: true),
            ],
            isBlocked: (label) {
              final t = label.toLowerCase();
              return t == 'techsec' || t == 'verb' || t == 'melee';
            },
            onChanged: (_) {},
          ),
        );
      case 'desktop-need-sync':
        return const SetsHonestyEmpty(
          kind: SetsHonestyKind.needSync,
          message:
              'Inventory not synced. Sync from Settings before filling Armor sets.',
        );
      case 'desktop-non-armor-thin':
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SetsNonArmorThinDetail(
            data: SetsNonArmorThinData(
              id: 'w1',
              name: 'Kinetic pair',
              typeLabel: 'weapon',
              pieceSummary: '2 weapons',
              tags: ['raid'],
            ),
          ),
        );
      default:
        return Center(child: Text('Unknown scenario: $_scenario'));
    }
  }

  /// Create wizard step shell for Capture (modal-like chrome + one step).
  ///
  /// Not a [Dialog] — host-fixture body must stay in-tree for Driver shots.
  Widget _createStepShell(
    BuildContext context, {
    required int step,
    required String setType,
    String? guardianClass,
    String namePreview = '',
    List<SetsBonusFamilyOption> families = const [],
  }) {
    final palette = FlapPalette.of(context);
    final maxStep = setsCreateMaxStep(setType);
    final isFinal = step >= maxStep;
    final canContinue = setType == 'armor' && step == 1
        ? guardianClass != null && guardianClass.isNotEmpty
        : setType.isNotEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Material(
          key: const Key('sets_lifecycle_modal'),
          color: palette.surface,
          elevation: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Text(
                  setsCreateCrumb(setType: setType, step: step),
                  key: const Key('sets_lifecycle_modal_title'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Divider(height: 1, color: palette.line),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SetsCreateWizard(
                    step: step,
                    setType: setType,
                    guardianClass: guardianClass,
                    families: families,
                    availableFamilies: families.isEmpty
                        ? const ['TechSec', 'Twofer']
                        : const [],
                    namePreview: namePreview,
                  ),
                ),
              ),
              Divider(height: 1, color: palette.line),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SetsCreateWizardFooter(
                  step: step,
                  isFinalStep: isFinal,
                  canContinue: canContinue,
                  onBack: step > 0 ? () {} : null,
                  onCancel: () {},
                  onContinue: isFinal ? null : () {},
                  onCreate: isFinal ? () {} : null,
                  createLabel: setType == 'armor' ? 'Create' : 'Create shell',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
