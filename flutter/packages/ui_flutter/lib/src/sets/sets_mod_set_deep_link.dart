import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Deep link to Mod Set only (no inline energy/mod edit on Armor board).
class SetsModSetDeepLink extends StatelessWidget {
  const SetsModSetDeepLink({
    super.key,
    this.linkedModSetId,
    this.linkedModSetName,
    this.onOpen,
    this.onLink,
  });

  final String? linkedModSetId;
  final String? linkedModSetName;
  final VoidCallback? onOpen;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final hasLink =
        linkedModSetId != null && linkedModSetId!.trim().isNotEmpty;
    return Row(
      key: const Key('sets_mod_set_deep_link'),
      children: [
        Icon(Icons.extension_outlined, size: 18, color: palette.muted),
        const SizedBox(width: kSpace8),
        Expanded(
          child: Text(
            hasLink
                ? (linkedModSetName?.trim().isNotEmpty == true
                    ? linkedModSetName!
                    : 'Mod Set $linkedModSetId')
                : 'No linked Mod Set',
            key: const Key('sets_mod_set_label'),
            style: neonBody(color: palette.foreground, fontSize: 13),
          ),
        ),
        if (hasLink)
          TextButton(
            key: const Key('sets_mod_set_open'),
            onPressed: onOpen,
            child: const Text('Open Mod Set'),
          )
        else
          TextButton(
            key: const Key('sets_mod_set_link'),
            onPressed: onLink,
            child: const Text('Link Mod Set'),
          ),
      ],
    );
  }
}
