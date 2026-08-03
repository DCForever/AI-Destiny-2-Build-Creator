import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Catalog empty reasons that drive distinct CTAs (weapons UX brief).
enum CatalogEmptyKind {
  /// Filters produced zero matches — Clear only.
  zeroMatch,

  /// Signed-in owned scope with empty inventory — Sync primary + Settings.
  ownedEmpty,

  /// Entity cache / manifest missing — Reload + Settings.
  missingManifest,

  /// Signed-out on Owned scope — sign-in path.
  ownedSignedOut,

  /// Generic empty (no CTAs beyond optional reload).
  generic,
}

/// Actionable empty surface for catalog browse.
class CatalogEmptyState extends StatelessWidget {
  const CatalogEmptyState({
    super.key,
    required this.kind,
    required this.message,
    this.onClearFilters,
    this.onReload,
    this.onSync,
    this.onOpenSettings,
  });

  final CatalogEmptyKind kind;
  final String message;
  final VoidCallback? onClearFilters;
  final VoidCallback? onReload;
  final VoidCallback? onSync;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpace24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                key: const Key('catalog_empty'),
                textAlign: TextAlign.center,
                style: neonBody(color: palette.foreground, fontSize: 14),
              ),
              const SizedBox(height: kSpace16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _actions(context, palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, FlapPalette palette) {
    switch (kind) {
      case CatalogEmptyKind.zeroMatch:
        return [
          if (onClearFilters != null)
            FilledButton(
              key: const Key('catalog_empty_clear_filters'),
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
        ];
      case CatalogEmptyKind.ownedEmpty:
        return [
          if (onSync != null)
            FilledButton(
              key: const Key('catalog_empty_sync'),
              onPressed: onSync,
              child: const Text('Sync inventory'),
            ),
          if (onOpenSettings != null)
            OutlinedButton(
              key: const Key('catalog_empty_settings'),
              onPressed: onOpenSettings,
              child: const Text('Settings'),
            ),
          // Keep legacy reload key for host smoke wiring.
          if (onReload != null)
            TextButton(
              key: const Key('catalog_empty_reload'),
              onPressed: onReload,
              child: Text(
                'Reload catalog',
                style: neonMono(color: palette.muted, fontSize: 11),
              ),
            ),
        ];
      case CatalogEmptyKind.missingManifest:
        return [
          if (onReload != null)
            FilledButton.tonal(
              key: const Key('catalog_empty_reload'),
              onPressed: onReload,
              child: const Text('Reload catalog'),
            ),
          if (onOpenSettings != null)
            OutlinedButton(
              key: const Key('catalog_empty_settings'),
              onPressed: onOpenSettings,
              child: const Text('Settings'),
            )
          else
            Text(
              key: const Key('catalog_empty_settings_hint'),
              'Then open Settings → Refresh manifest',
              style: neonBody(color: palette.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ];
      case CatalogEmptyKind.ownedSignedOut:
        return [
          if (onOpenSettings != null)
            FilledButton(
              key: const Key('catalog_empty_settings'),
              onPressed: onOpenSettings,
              child: const Text('Sign in · Settings'),
            ),
          Text(
            key: const Key('catalog_empty_sync_hint'),
            'Sign in and Settings → Sync inventory if needed',
            style: neonBody(color: palette.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ];
      case CatalogEmptyKind.generic:
        return [
          if (onReload != null)
            FilledButton.tonal(
              key: const Key('catalog_empty_reload'),
              onPressed: onReload,
              child: const Text('Reload catalog'),
            ),
        ];
    }
  }
}

/// Loading skeleton for identity icon grid (not empty-state CTAs).
class CatalogLoadingSkeleton extends StatelessWidget {
  const CatalogLoadingSkeleton({super.key, this.cellCount = 8});

  final int cellCount;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return GridView.builder(
      key: const Key('catalog_loading'),
      padding: const EdgeInsets.all(kSpace12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 152,
        mainAxisSpacing: kSpace12,
        crossAxisSpacing: kSpace12,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        return Container(
          key: Key('catalog_skeleton_$index'),
          decoration: BoxDecoration(
            color: palette.surfaceRaised.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(kRadiusMax),
            border: Border.all(color: palette.line, width: kFlapRuleThickness),
          ),
        );
      },
    );
  }
}
