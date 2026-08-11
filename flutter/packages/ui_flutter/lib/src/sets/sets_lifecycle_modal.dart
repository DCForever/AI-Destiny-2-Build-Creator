import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_neon_chrome.dart';

/// Large modal shell over the Sets library for create / board / compare / optimize.
///
/// Dual-truth: mockup `.modal` + `.modal-bar` (raised) + Orbitron title + hairline.
class SetsLifecycleModal extends StatelessWidget {
  const SetsLifecycleModal({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.width = 960,
    this.height = 720,
    this.footer,
    this.crumb,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double width;
  final double height;
  final Widget? footer;

  /// Optional mono crumb after title (e.g. `· type`).
  final String? crumb;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Dialog(
      key: const Key('sets_lifecycle_modal'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: height,
          minWidth: 480,
          minHeight: 360,
        ),
        child: Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kFlapRadius),
            side: BorderSide(
              color: palette.lineStrong,
              width: kFlapRuleThickness,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // modal-bar — raised strip + Orbitron title
              Container(
                color: palette.surfaceRaised,
                padding: const EdgeInsets.fromLTRB(
                  14,
                  10,
                  8,
                  10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title.toUpperCase(),
                              style: neonDisplay(
                                color: palette.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (crumb != null && crumb!.isNotEmpty)
                              TextSpan(
                                text: ' $crumb',
                                style: neonMono(
                                  color: palette.muted.withValues(alpha: 0.75),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                        key: const Key('sets_lifecycle_modal_title'),
                      ),
                    ),
                    TextButton(
                      key: const Key('sets_lifecycle_modal_close'),
                      style: setsNeonGhostStyle(
                        palette,
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        fontSize: 8,
                      ),
                      onPressed:
                          onClose ?? () => Navigator.of(context).maybePop(),
                      child: Text(
                        'ESC',
                        style: setsNeonBtnLabel(palette.muted, fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: kFlapRuleThickness, color: palette.line),
              Expanded(
                child: ColoredBox(
                  color: palette.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: child,
                  ),
                ),
              ),
              if (footer != null) ...[
                Divider(
                  height: 1,
                  thickness: kFlapRuleThickness,
                  color: palette.line,
                ),
                ColoredBox(
                  color: palette.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: footer!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Show [SetsLifecycleModal] fullscreen-ish dialog.
Future<T?> showSetsLifecycleModal<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  Widget? footer,
  String? crumb,
  double width = 960,
  double height = 720,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xB8020208),
    builder: (ctx) => SetsLifecycleModal(
      title: title,
      crumb: crumb,
      width: width,
      height: height,
      footer: footer,
      onClose: () => Navigator.of(ctx).pop(),
      child: child,
    ),
  );
}
