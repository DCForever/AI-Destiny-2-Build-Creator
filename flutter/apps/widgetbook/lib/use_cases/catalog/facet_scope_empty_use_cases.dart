import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Off → include → exclude cycle',
  type: NeonFacetChip,
  path: '[Catalog]/Facets',
)
Widget facetCycle(BuildContext context) {
  return const _FacetCycleDemo();
}

@widgetbook.UseCase(
  name: 'iconOnly element row',
  type: NeonFacetChip,
  path: '[Catalog]/Facets',
)
Widget facetIconOnly(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final el in ['Solar', 'Void', 'Arc', 'Stasis', 'Strand'])
          NeonFacetChip(
            label: el,
            value: el,
            state: el == 'Strand' ? FacetChipState.include : FacetChipState.off,
            iconOnly: true,
            onCycle: () {},
          ),
      ],
    ),
  );
}

@widgetbook.UseCase(
  name: 'All / OWNED · N',
  type: CatalogScopeControl,
  path: '[Catalog]/Scope',
)
Widget scopeControl(BuildContext context) {
  return const _ScopeDemo();
}

@widgetbook.UseCase(
  name: 'Zero match (Clear filters)',
  type: CatalogEmptyState,
  path: '[Catalog]/Empty',
)
Widget emptyZeroMatch(BuildContext context) {
  return CatalogEmptyState(
    kind: CatalogEmptyKind.zeroMatch,
    message: 'No weapons match the current filters.',
    onClearFilters: () {},
  );
}

@widgetbook.UseCase(
  name: 'Owned empty (Sync + Settings)',
  type: CatalogEmptyState,
  path: '[Catalog]/Empty',
)
Widget emptyOwned(BuildContext context) {
  return CatalogEmptyState(
    kind: CatalogEmptyKind.ownedEmpty,
    message: 'No owned weapons in local inventory.',
    onSync: () {},
    onOpenSettings: () {},
  );
}

@widgetbook.UseCase(
  name: 'Signed-out owned scope',
  type: CatalogEmptyState,
  path: '[Catalog]/Empty',
)
Widget emptySignedOut(BuildContext context) {
  return CatalogEmptyState(
    kind: CatalogEmptyKind.ownedSignedOut,
    message: 'Sign in to browse owned weapons.',
    onOpenSettings: () {},
  );
}

class _FacetCycleDemo extends StatefulWidget {
  const _FacetCycleDemo();

  @override
  State<_FacetCycleDemo> createState() => _FacetCycleDemoState();
}

class _FacetCycleDemoState extends State<_FacetCycleDemo> {
  FacetChipState _state = FacetChipState.off;

  void _cycle() {
    setState(() {
      switch (_state) {
        case FacetChipState.off:
          _state = FacetChipState.include;
        case FacetChipState.include:
          _state = FacetChipState.exclude;
        case FacetChipState.exclude:
          _state = FacetChipState.off;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NeonFacetChip(
        label: 'Void',
        value: 'Void',
        state: _state,
        onCycle: _cycle,
      ),
    );
  }
}

class _ScopeDemo extends StatefulWidget {
  const _ScopeDemo();

  @override
  State<_ScopeDemo> createState() => _ScopeDemoState();
}

class _ScopeDemoState extends State<_ScopeDemo> {
  CatalogScope _scope = CatalogScope.all;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CatalogScopeControl(
        scope: _scope,
        ownedLabel: 'OWNED · 12',
        onChanged: (s) => setState(() => _scope = s),
      ),
    );
  }
}
