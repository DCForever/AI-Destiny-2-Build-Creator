import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../neon_segmented.dart';

/// All / Owned scope segmented control for catalog browse.
///
/// Presentation only — host owns scope state and signed-in label copy.
class CatalogScopeControl extends StatelessWidget {
  const CatalogScopeControl({
    super.key,
    required this.scope,
    required this.onChanged,
    this.ownedLabel = 'Owned',
    this.dense = true,
  });

  final CatalogScope scope;
  final ValueChanged<CatalogScope> onChanged;
  final String ownedLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return NeonSegmentedTabs(
      key: const Key('catalog_scope_control'),
      dense: dense,
      selectedId: scope.name,
      onSelected: (id) {
        onChanged(
          id == CatalogScope.owned.name
              ? CatalogScope.owned
              : CatalogScope.all,
        );
      },
      options: [
        const NeonSegmentOption(
          id: 'all',
          label: 'All',
          key: Key('scope_chip_all'),
        ),
        NeonSegmentOption(
          id: 'owned',
          label: ownedLabel,
          key: const Key('scope_chip_owned'),
        ),
      ],
    );
  }
}
