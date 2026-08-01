import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/material.dart';

import 'builds_controller.dart';

/// Modal bottom sheet: create build (class + synergy type + optional name).
///
/// Returns the new build id on success, or null if dismissed / failed.
Future<String?> showCreateBuildSheet(
  BuildContext context, {
  required BuildsController controller,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: _CreateBuildSheetBody(controller: controller),
      );
    },
  );
}

class _CreateBuildSheetBody extends StatefulWidget {
  const _CreateBuildSheetBody({required this.controller});

  final BuildsController controller;

  @override
  State<_CreateBuildSheetBody> createState() => _CreateBuildSheetBodyState();
}

class _CreateBuildSheetBodyState extends State<_CreateBuildSheetBody> {
  final _nameCtrl = TextEditingController();
  final _synergyCtrl = TextEditingController(text: 'melee');
  GuardianClass _className = GuardianClass.hunter;
  bool _saving = false;
  String? _localError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _synergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _synergyCtrl.text.trim();
    if (type.isEmpty) {
      setState(() => _localError = 'At least one synergy type is required');
      return;
    }
    setState(() {
      _saving = true;
      _localError = null;
    });
    final err = await widget.controller.createBuild(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      className: _className,
      synergyTypes: [DraftSynergyType(type: type)],
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _localError = err;
      });
      return;
    }
    final id = widget.controller.selected?.build.id;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('create_build_sheet'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create build', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('create_build_name'),
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GuardianClass>(
              key: const Key('create_build_class'),
              // ignore: deprecated_member_use
              value: _className,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in GuardianClass.values)
                  DropdownMenuItem(value: c, child: Text(c.wireName)),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _className = v);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('create_build_synergy'),
              controller: _synergyCtrl,
              decoration: const InputDecoration(
                labelText: 'Synergy type (required)',
                hintText: 'e.g. melee',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            if (_localError != null) ...[
              const SizedBox(height: 12),
              Text(
                _localError!,
                key: const Key('create_build_error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('create_build_submit'),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
