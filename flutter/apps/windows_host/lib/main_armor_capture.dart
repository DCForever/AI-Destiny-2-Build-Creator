import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'catalog/armor_capture_fixtures.dart';
import 'theme/flap_theme.dart';

/// Catalog Armor dual-truth Capture entrypoint (`drive: host-fixture`).
///
/// Scenario rail keys: `capture_scenario_<matrix-id>` — tap then screenshot.
/// Writes under `docs/ux-redesign/catalog/implementation-shots/001-armor/`.
///
/// ```text
/// flutter run -d windows -t lib/main_armor_capture.dart
/// ```
///
/// Ship widgets only (CatalogArmorGrid / CatalogArmorDetail / empty / soft
/// error). Set-bonus uses presentation DTOs — CatalogPage definition map is
/// still unbound (COMPARE residual).
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_armor_capture: Flutter Driver on · armor host-fixture scenarios',
  );
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArmorCaptureApp());
}

class ArmorCaptureApp extends StatelessWidget {
  const ArmorCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armor capture',
      debugShowCheckedModeBanner: true,
      theme: buildFlapTheme(),
      home: const ArmorCaptureHome(),
    );
  }
}

class ArmorCaptureHome extends StatefulWidget {
  const ArmorCaptureHome({super.key});

  @override
  State<ArmorCaptureHome> createState() => _ArmorCaptureHomeState();
}

class _ArmorCaptureHomeState extends State<ArmorCaptureHome> {
  String _scenario = 'desktop-grid';
  String? _selectedInstanceId;
  late final TextEditingController _query;
  FacetFilter _classFacet = const FacetFilter();
  FacetFilter _slotFacet = const FacetFilter();
  bool? _exotic;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    final owned = armorOwnedStripItems();
    if (owned.isNotEmpty) {
      _selectedInstanceId = owned.first.instanceId;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _selectScenario(String id) {
    setState(() {
      _scenario = id;
      if (id == 'desktop-detail-owned' ||
          id == 'desktop-instance-strip' ||
          id == 'desktop-set-bonus' ||
          id == 'desktop-mods-energy' ||
          id == 'desktop-exotic-callout') {
        final owned = armorOwnedStripItems();
        _selectedInstanceId =
            owned.isEmpty ? null : owned.first.instanceId;
      } else if (id == 'desktop-live-null-copy') {
        final liveNull = armorLiveNullStripItems();
        _selectedInstanceId =
            liveNull.isEmpty ? null : liveNull.first.instanceId;
      } else {
        _selectedInstanceId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Scaffold(
      key: const Key('armor_capture_root'),
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
                  for (final id in kArmorCaptureMatrixIds) ...[
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
      case 'desktop-grid':
        return _gridScenario(showOwned: true, selectSynthoceps: false);
      case 'desktop-detail-owned':
        return _ownedDossier(
          instances: armorOwnedStripItems(),
          setBonus: kArmorSetBonusTechsec,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-instance-strip':
        return _ownedDossier(
          instances: armorOwnedStripItems(),
          setBonus: kArmorSetBonusTechsec,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-detail-unowned':
        return _unownedDossier();
      case 'desktop-set-bonus':
        return _ownedDossier(
          instances: armorOwnedStripItems(),
          setBonus: kArmorSetBonusTechsec,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-mods-energy':
        return _ownedDossier(
          instances: armorOwnedStripItems(),
          setBonus: null,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-exotic-callout':
        return _ownedDossier(
          instances: armorOwnedStripItems(),
          setBonus: null,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-owned-empty':
        return CatalogEmptyState(
          kind: CatalogEmptyKind.ownedEmpty,
          message:
              'No owned armor in local inventory. Sync from Settings, then reload Catalog.',
          onSync: () {},
          onOpenSettings: () {},
        );
      case 'desktop-signed-out-owned':
        return CatalogEmptyState(
          kind: CatalogEmptyKind.ownedSignedOut,
          message:
              'Sign in to see owned armor. Owned scope never invents inventory.',
          onOpenSettings: () {},
        );
      case 'desktop-live-null-copy':
        return _ownedDossier(
          instances: armorLiveNullStripItems(),
          setBonus: null,
          exotic: kSynthocepsExoticPerk(),
        );
      case 'desktop-soft-error':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogSoftErrorBanner(
              message:
                  'Armor definition join soft-failed for 2 items. Showing partial catalog.',
              onDismiss: () {},
            ),
            Expanded(
              child: _gridScenario(showOwned: true, selectSynthoceps: false),
            ),
          ],
        );
      default:
        return Center(child: Text('Unknown scenario: $_scenario'));
    }
  }

  Widget _facetBar() {
    return CatalogFilterBar(
      queryController: _query,
      onQueryChanged: (_) {},
      exotic: _exotic,
      onCycleExotic: () {
        setState(() {
          if (_exotic == null) {
            _exotic = true;
          } else if (_exotic == true) {
            _exotic = false;
          } else {
            _exotic = null;
          }
        });
      },
      primaryGroups: [
        CatalogFacetGroup(
          id: 'class',
          values: catalogClassNames,
          facet: _classFacet,
          onCycle: (v) {
            setState(() {
              _classFacet = cycleFacetValue(_classFacet, v);
            });
          },
        ),
        CatalogFacetGroup(
          id: 'slot',
          values: catalogArmorSlots,
          facet: _slotFacet,
          onCycle: (v) {
            setState(() {
              _slotFacet = cycleFacetValue(_slotFacet, v);
            });
          },
        ),
      ],
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            key: const Key('scope_chip_all'),
            label: const Text('All'),
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: 4),
          FilterChip(
            key: const Key('scope_chip_owned'),
            label: const Text('Owned'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      ),
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            key: const Key('mode_chip_weapons'),
            label: const Text('Weapons'),
            selected: false,
            onSelected: (_) {},
          ),
          const SizedBox(width: 4),
          FilterChip(
            key: const Key('mode_chip_armor'),
            label: const Text('Armor'),
            selected: true,
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _gridScenario({
    required bool showOwned,
    required bool selectSynthoceps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _facetBar(),
        Expanded(
          child: CatalogWeaponsWorkspace(
            main: CatalogArmorGrid(
              items: kArmorCaptureItems,
              selectedHash:
                  selectSynthoceps ? kArmorSynthoceps.hash : null,
              showOwned: showOwned,
              onSelect: (_) {},
            ),
            detail: selectSynthoceps
                ? CatalogArmorDetail(
                    item: kArmorSynthoceps,
                    instances: armorOwnedStripItems(),
                    selectedInstanceId: _selectedInstanceId,
                    onSelectInstance: (c) {
                      setState(() => _selectedInstanceId = c.instanceId);
                    },
                    setBonus: kArmorSetBonusTechsec,
                    exoticPerk: kSynthocepsExoticPerk(),
                    showOwnedMeta: showOwned,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _ownedDossier({
    required List<ArmorInstanceStripItem> instances,
    ArmorSetBonusData? setBonus,
    ArmorExoticPerkData? exotic,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _facetBar(),
        Expanded(
          child: CatalogWeaponsWorkspace(
            main: CatalogArmorGrid(
              items: kArmorCaptureItems,
              selectedHash: kArmorSynthoceps.hash,
              showOwned: true,
              onSelect: (_) {},
            ),
            detail: CatalogArmorDetail(
              item: kArmorSynthoceps,
              instances: instances,
              selectedInstanceId: _selectedInstanceId,
              onSelectInstance: (c) {
                setState(() => _selectedInstanceId = c.instanceId);
              },
              setBonus: setBonus,
              exoticPerk: exotic,
              showOwnedMeta: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _unownedDossier() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _facetBar(),
        Expanded(
          child: CatalogWeaponsWorkspace(
            main: CatalogArmorGrid(
              items: kArmorCaptureItems,
              selectedHash: kArmorFieldPlate.hash,
              showOwned: true,
              onSelect: (_) {},
            ),
            detail: const CatalogArmorDetail(
              item: kArmorFieldPlate,
              instances: [],
              showOwnedMeta: true,
            ),
          ),
        ),
      ],
    );
  }
}
