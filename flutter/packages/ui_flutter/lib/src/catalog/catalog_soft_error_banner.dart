import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Dismissible soft error banner for catalog soft failures (not hard empty).
///
/// Presentation only — host owns message + dismiss callback.
class CatalogSoftErrorBanner extends StatelessWidget {
  const CatalogSoftErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      key: const Key('catalog_soft_error_banner'),
      color: palette.warning.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: palette.warning.withValues(alpha: 0.28),
              width: kFlapRuleThickness,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kSpace12,
          vertical: kSpace8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key: const Key('catalog_soft_error_flag'),
              'SOFT',
              style: neonMono(
                color: palette.warning,
                fontSize: 8,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: kSpace8),
            Expanded(
              child: Text(
                message,
                key: const Key('catalog_soft_error_message'),
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
            ),
            if (onDismiss != null)
              TextButton(
                key: const Key('catalog_soft_error_dismiss'),
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'DISMISS',
                  style: neonMono(color: palette.muted, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
