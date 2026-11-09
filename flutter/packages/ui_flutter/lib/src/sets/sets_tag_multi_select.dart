import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// Free multi-select tags with Synergy Type hard-block feedback.
class SetsTagMultiSelect extends StatefulWidget {
  const SetsTagMultiSelect({
    super.key,
    required this.selected,
    this.suggestions = const [],
    this.onChanged,
    this.isBlocked,
    this.enabled = true,
  });

  final List<SetsTagData> selected;
  final List<SetsTagData> suggestions;
  final ValueChanged<List<SetsTagData>>? onChanged;

  /// When true, tag label is hard-blocked (Synergy Type vocab).
  final bool Function(String label)? isBlocked;
  final bool enabled;

  @override
  State<SetsTagMultiSelect> createState() => _SetsTagMultiSelectState();
}

class _SetsTagMultiSelectState extends State<SetsTagMultiSelect> {
  final _controller = TextEditingController();
  String? _blockMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryAdd(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return;
    final blocked = widget.isBlocked?.call(label) ?? false;
    if (blocked) {
      setState(() {
        _blockMessage = '"$label" is a Synergy Type label and cannot be a free tag';
      });
      return;
    }
    final next = [
      ...widget.selected,
      SetsTagData(id: label.toLowerCase(), label: label),
    ];
    // de-dupe
    final seen = <String>{};
    final deduped = <SetsTagData>[];
    for (final t in next) {
      if (seen.add(t.id)) deduped.add(t);
    }
    setState(() => _blockMessage = null);
    _controller.clear();
    widget.onChanged?.call(deduped);
  }

  void _remove(SetsTagData tag) {
    final next = [for (final t in widget.selected) if (t.id != tag.id) t];
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('sets_tag_multi_select'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in widget.selected)
              InputChip(
                key: Key('sets_tag_chip_${t.id}'),
                label: Text(t.label),
                onDeleted: widget.enabled ? () => _remove(t) : null,
              ),
          ],
        ),
        if (widget.enabled) ...[
          const SizedBox(height: kSpace8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('sets_tag_input'),
                  controller: _controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Add tag…',
                  ),
                  onSubmitted: _tryAdd,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('sets_tag_add'),
                onPressed: () => _tryAdd(_controller.text),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
        if (_blockMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: kSpace8),
            child: Text(
              _blockMessage!,
              key: const Key('sets_tag_blocked_message'),
              style: neonBody(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: kSpace8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in widget.suggestions)
                ActionChip(
                  key: Key('sets_tag_suggestion_${s.id}'),
                  label: Text(
                    s.label,
                    style: TextStyle(
                      color: s.blocked ? palette.muted : palette.foreground,
                    ),
                  ),
                  onPressed: !widget.enabled || s.blocked
                      ? null
                      : () => _tryAdd(s.label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
