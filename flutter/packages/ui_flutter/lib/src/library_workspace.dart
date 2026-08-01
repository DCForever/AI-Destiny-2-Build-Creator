import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Dual-pane library shell: fixed rail + detail (Windows Matte Flap Workspace).
///
/// Mobile Focus Swap should not force this layout — use only on desktop-class hosts.
class LibraryWorkspace extends StatelessWidget {
  const LibraryWorkspace({
    super.key,
    required this.rail,
    required this.detail,
    this.railWidth = kFlapLibraryRailWidth,
    this.maxWidth = kPageFrameMaxWidth,
  });

  final Widget rail;
  final Widget detail;
  final double railWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: railWidth, child: rail),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: detail),
          ],
        ),
      ),
    );
  }
}
