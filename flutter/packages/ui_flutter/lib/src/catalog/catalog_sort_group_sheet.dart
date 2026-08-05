import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Progressive sheet: reorder sort keys + active group-by dimensions.
///
/// Never rewrites filter facets (BR-CAT-007). Session host owns persistence.
class CatalogSortGroupSheet extends StatefulWidget {
  const CatalogSortGroupSheet({
    super.key,
    required this.sortKeys,
    required this.groupDimensions,
    required this.availableGroupDimensions,
    required this.onApply,
    this.onCancel,
  });

  final List<CatalogSortKey> sortKeys;
  final List<CatalogGroupDimension> groupDimensions;
  final List<({CatalogGroupDimension id, String label})> availableGroupDimensions;
  final void Function(
    List<CatalogSortKey> sortKeys,
    List<CatalogGroupDimension> groupDimensions,
  ) onApply;
  final VoidCallback? onCancel;

  @override
  State<CatalogSortGroupSheet> createState() => _CatalogSortGroupSheetState();
}

class _CatalogSortGroupSheetState extends State<CatalogSortGroupSheet> {
  late List<CatalogSortKey> _sortKeys;
  late List<CatalogGroupDimension> _groupDims;

  @override
  void initState() {
    super.initState();
    _sortKeys = List<CatalogSortKey>.from(widget.sortKeys);
    _groupDims = List<CatalogGroupDimension>.from(widget.groupDimensions);
  }

  String _sortLabel(CatalogSortKey key) =>
      kCatalogSortKeyLabels[key] ?? key.name;

  String _groupLabel(CatalogGroupDimension dim) {
    for (final d in widget.availableGroupDimensions) {
      if (d.id == dim) return d.label;
    }
    return dim.name;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final inactive = widget.availableGroupDimensions
        .where((d) => !_groupDims.contains(d.id))
        .toList();

    return Material(
      key: const Key('catalog_sort_group_sheet'),
      color: palette.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kSpace12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SORT & GROUP',
                style: neonDisplay(
                  color: palette.foreground,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reorder priority. Does not change filters.',
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
              const SizedBox(height: kSpace12),
              Text(
                'SORT PRIORITY',
                style: neonMono(
                  color: palette.muted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              ReorderableListView.builder(
                key: const Key('catalog_sort_keys_list'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _sortKeys.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _sortKeys.removeAt(oldIndex);
                    _sortKeys.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final key = _sortKeys[index];
                  return ListTile(
                    key: Key('sort_key_${key.name}'),
                    dense: true,
                    title: Text(
                      _sortLabel(key),
                      style: neonBody(color: palette.foreground, fontSize: 13),
                    ),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: palette.muted),
                    ),
                    trailing: Text(
                      '${index + 1}',
                      style: neonMono(color: palette.muted, fontSize: 11),
                    ),
                  );
                },
              ),
              const SizedBox(height: kSpace12),
              Text(
                'GROUP BY (ACTIVE ORDER)',
                style: neonMono(
                  color: palette.muted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              if (_groupDims.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No group dimensions active',
                    key: const Key('catalog_group_dims_empty'),
                    style: neonBody(color: palette.muted, fontSize: 12),
                  ),
                )
              else
                ReorderableListView.builder(
                  key: const Key('catalog_group_dims_list'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _groupDims.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _groupDims.removeAt(oldIndex);
                      _groupDims.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final dim = _groupDims[index];
                    return ListTile(
                      key: Key('group_dim_${dim.name}'),
                      dense: true,
                      title: Text(
                        _groupLabel(dim),
                        style:
                            neonBody(color: palette.foreground, fontSize: 13),
                      ),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_handle, color: palette.muted),
                      ),
                      trailing: IconButton(
                        key: Key('group_dim_remove_${dim.name}'),
                        icon: Icon(Icons.close, size: 18, color: palette.muted),
                        onPressed: () {
                          setState(() => _groupDims.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  key: const Key('catalog_group_dims_add'),
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final d in inactive)
                      ActionChip(
                        key: Key('group_dim_add_${d.id.name}'),
                        label: Text(d.label),
                        onPressed: () {
                          setState(() => _groupDims.add(d.id));
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: kSpace16),
              Row(
                children: [
                  TextButton(
                    key: const Key('catalog_sort_group_cancel'),
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('catalog_sort_group_apply'),
                    onPressed: () {
                      widget.onApply(
                        List<CatalogSortKey>.from(_sortKeys),
                        List<CatalogGroupDimension>.from(_groupDims),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Host helper: show [CatalogSortGroupSheet] as a modal bottom sheet.
Future<void> showCatalogSortGroupSheet({
  required BuildContext context,
  required List<CatalogSortKey> sortKeys,
  required List<CatalogGroupDimension> groupDimensions,
  required List<({CatalogGroupDimension id, String label})>
      availableGroupDimensions,
  required void Function(
    List<CatalogSortKey> sortKeys,
    List<CatalogGroupDimension> groupDimensions,
  ) onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.85;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: CatalogSortGroupSheet(
            sortKeys: sortKeys,
            groupDimensions: groupDimensions,
            availableGroupDimensions: availableGroupDimensions,
            onApply: (sort, group) {
              Navigator.pop(ctx);
              onApply(sort, group);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
        ),
      );
    },
  );
}
