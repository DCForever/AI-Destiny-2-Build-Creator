import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:flutter/material.dart';

import 'builds_controller.dart';

/// Modal bottom sheet: pick a library set to attach to the selected variant.
///
/// Returns the chosen set id, or null if dismissed.
Future<String?> showAttachSetSheet(
  BuildContext context, {
  required BuildsController controller,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _AttachSetSheetBody(controller: controller);
    },
  );
}

class _AttachSetSheetBody extends StatelessWidget {
  const _AttachSetSheetBody({required this.controller});

  final BuildsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attached = {for (final a in controller.attachments) a.record.setId};
    final sets = controller.attachableSets
        .where((s) => !attached.contains(s.id))
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Attach set', style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: sets.isEmpty
                  ? const Center(
                      child: Text(
                        'No library sets available to attach.',
                        key: Key('attach_set_empty'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      key: const Key('attach_set_sheet'),
                      itemCount: sets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final SetRecord s = sets[index];
                        return ListTile(
                          key: Key('attach_set_row_${s.id}'),
                          title: Text(s.name.trim().isEmpty ? s.id : s.name),
                          subtitle: Text(s.type),
                          trailing: const Icon(Icons.add),
                          onTap: () => Navigator.of(context).pop(s.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
