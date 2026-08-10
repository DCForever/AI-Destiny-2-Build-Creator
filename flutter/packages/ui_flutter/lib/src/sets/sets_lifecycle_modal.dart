import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Large modal shell over the Sets library for create / board / compare / optimize.
class SetsLifecycleModal extends StatelessWidget {
  const SetsLifecycleModal({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.width = 960,
    this.height = 720,
    this.footer,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double width;
  final double height;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Dialog(
      key: const Key('sets_lifecycle_modal'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSpace16,
                  kSpace12,
                  kSpace8,
                  kSpace8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        key: const Key('sets_lifecycle_modal_title'),
                        style: neonBody(
                          color: palette.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('sets_lifecycle_modal_close'),
                      onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: kFlapRuleThickness, color: palette.line),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(kSpace16),
                  child: child,
                ),
              ),
              if (footer != null) ...[
                Divider(
                  height: 1,
                  thickness: kFlapRuleThickness,
                  color: palette.line,
                ),
                Padding(
                  padding: const EdgeInsets.all(kSpace12),
                  child: footer!,
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
  double width = 960,
  double height = 720,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SetsLifecycleModal(
      title: title,
      width: width,
      height: height,
      footer: footer,
      onClose: () => Navigator.of(ctx).pop(),
      child: child,
    ),
  );
}
