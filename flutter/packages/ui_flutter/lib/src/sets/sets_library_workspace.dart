import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../library_workspace.dart';
import '../neon_fonts.dart';
import 'sets_armor_library_row.dart';
import 'sets_honesty_empty.dart';
import 'sets_models.dart';

/// Dual-pane Sets library: Armor flap rail + detail rail.
class SetsLibraryWorkspace extends StatelessWidget {
  const SetsLibraryWorkspace({
    super.key,
    required this.rows,
    this.detail,
    this.honesty,
    this.onSelectRow,
    this.onNewSet,
    this.searchController,
    this.onSearchChanged,
    this.typeFilter,
    this.onTypeFilterChanged,
    this.loading = false,
    this.railHeader,
  });

  final List<SetsArmorLibraryRowData> rows;
  final Widget? detail;
  final SetsHonestyEmpty? honesty;
  final ValueChanged<String>? onSelectRow;
  final VoidCallback? onNewSet;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? typeFilter;
  final ValueChanged<String?>? onTypeFilterChanged;
  final bool loading;
  final Widget? railHeader;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final rail = Column(
      key: const Key('sets_library_rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(kSpace8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sets',
                  style: neonBody(
                    color: palette.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const Key('sets_library_new'),
                tooltip: 'New set',
                onPressed: onNewSet,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        if (railHeader != null) railHeader!,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpace8),
          child: TextField(
            key: const Key('sets_library_search'),
            controller: searchController,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Search sets…',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: kSpace8),
        const SetsArmorLibraryHeader(),
        Expanded(
          child: loading
              ? const SetsHonestyEmpty(
                  kind: SetsHonestyKind.loading,
                  message: 'Loading sets…',
                )
              : honesty != null
                  ? honesty!
                  : rows.isEmpty
                      ? const SetsHonestyEmpty(
                          kind: SetsHonestyKind.noMatches,
                          message: 'No sets match filters',
                        )
                      : ListView.builder(
                          key: const Key('sets_armor_library_list'),
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final r = rows[i];
                            return SetsArmorLibraryRow(
                              data: r,
                              onTap: onSelectRow == null
                                  ? null
                                  : () => onSelectRow!(r.id),
                            );
                          },
                        ),
        ),
      ],
    );

    final detailChild = detail ??
        Center(
          child: Text(
            'Select a set',
            key: const Key('sets_library_detail_empty'),
            style: neonBody(color: palette.muted, fontSize: 13),
          ),
        );

    return LibraryWorkspace(
      key: const Key('sets_library_workspace'),
      rail: rail,
      detail: detailChild,
    );
  }
}
