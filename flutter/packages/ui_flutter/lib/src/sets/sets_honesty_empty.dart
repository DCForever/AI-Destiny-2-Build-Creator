import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// Honesty empty surface for Sets library / fill (no fake owned armor).
class SetsHonestyEmpty extends StatelessWidget {
  const SetsHonestyEmpty({
    super.key,
    required this.kind,
    required this.message,
    this.onSignIn,
    this.onSync,
    this.onClearFilters,
  });

  final SetsHonestyKind kind;
  final String message;
  final VoidCallback? onSignIn;
  final VoidCallback? onSync;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpace24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == SetsHonestyKind.loading)
              const Padding(
                padding: EdgeInsets.only(bottom: kSpace16),
                child: CircularProgressIndicator(
                  key: Key('sets_loading_skeleton'),
                ),
              )
            else
              Icon(
                kind == SetsHonestyKind.signedOut
                    ? Icons.lock_outline
                    : kind == SetsHonestyKind.needSync
                        ? Icons.sync_problem
                        : Icons.inbox_outlined,
                key: Key('sets_honesty_icon_${kind.name}'),
                size: 36,
                color: palette.muted,
              ),
            const SizedBox(height: kSpace12),
            Text(
              message,
              key: Key('sets_honesty_${kind.name}'),
              textAlign: TextAlign.center,
              style: neonBody(color: palette.foreground, fontSize: 14),
            ),
            const SizedBox(height: kSpace16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (kind == SetsHonestyKind.signedOut && onSignIn != null)
                  FilledButton(
                    key: const Key('sets_honesty_sign_in'),
                    onPressed: onSignIn,
                    child: const Text('Sign in'),
                  ),
                if (kind == SetsHonestyKind.needSync && onSync != null)
                  FilledButton(
                    key: const Key('sets_honesty_sync'),
                    onPressed: onSync,
                    child: const Text('Sync inventory'),
                  ),
                if (kind == SetsHonestyKind.noMatches && onClearFilters != null)
                  OutlinedButton(
                    key: const Key('sets_honesty_clear_filters'),
                    onPressed: onClearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
