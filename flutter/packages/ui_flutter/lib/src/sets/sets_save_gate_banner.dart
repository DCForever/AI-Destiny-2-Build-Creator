import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Save disabled / under-min / incomplete goals banner.
class SetsSaveGateBanner extends StatelessWidget {
  const SetsSaveGateBanner({
    super.key,
    required this.message,
    this.canSave = false,
  });

  final String message;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('sets_save_gate_banner'),
      padding: const EdgeInsets.all(kSpace8),
      color: canSave
          ? scheme.primaryContainer.withValues(alpha: 0.4)
          : scheme.errorContainer.withValues(alpha: 0.5),
      child: Text(
        message,
        key: Key(canSave ? 'sets_save_gate_ok' : 'sets_save_gate_blocked'),
        style: neonBody(
          color: canSave ? palette.foreground : scheme.onErrorContainer,
          fontSize: 12,
        ),
      ),
    );
  }
}
