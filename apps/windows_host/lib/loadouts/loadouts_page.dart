import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import 'loadout_presentation_loader.dart';
import 'loadouts_controller.dart';

/// In-Game Loadouts browser (Bungie character loadouts / component 206) — DART-055.
class LoadoutsPage extends StatefulWidget {
  const LoadoutsPage({
    super.key,
    required this.services,
    this.controller,
  });

  final AppServices services;

  /// Optional injectable controller (tests).
  final LoadoutsController? controller;

  static const String titleText = 'In-Game Loadouts';
  static const String signedOutText =
      'Sign in with Bungie to view your in-game loadout slots and icons.';

  @override
  State<LoadoutsPage> createState() => _LoadoutsPageState();
}

class _LoadoutsPageState extends State<LoadoutsPage> {
  late final LoadoutsController _controller;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownController = true;
      _controller = LoadoutsController(
        session: widget.services.oauthSession,
        profileClient: widget.services.profileClient,
        presentationTablesLoader: () =>
            loadLoadoutPresentationTablesFromStorage(
          widget.services.storageRoot,
        ),
      );
    }
    _controller.addListener(_onController);
    widget.services.oauthSession.addListener(_onSession);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    widget.services.oauthSession.removeListener(_onSession);
    if (_ownController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _onSession() {
    _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = _controller.displayLoadouts;
    final all = _controller.allLoadouts;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const Key('loadouts_page_body'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LoadoutsPage.titleText,
                  key: const Key('loadouts_title'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (_controller.isSignedIn)
                TextButton.icon(
                  key: const Key('loadouts_refresh'),
                  onPressed:
                      _controller.isLoading ? null : () => _controller.refresh(),
                  icon: _controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bungie character loadouts with real icon and color (same source as DIM). '
            'Sign in to sync from your profile.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_controller.membershipDisplayName != null) ...[
            const SizedBox(height: 4),
            Text(
              _controller.membershipDisplayName!,
              key: const Key('loadouts_membership'),
              style: theme.textTheme.labelMedium,
            ),
          ],
          if (_controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage!,
              key: const Key('loadouts_error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (_controller.hintMessage != null &&
              _controller.errorMessage == null) ...[
            const SizedBox(height: 8),
            Text(
              _controller.hintMessage!,
              key: const Key('loadouts_hint'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          if (!_controller.isSignedIn)
            Text(
              LoadoutsPage.signedOutText,
              key: const Key('loadouts_signed_out'),
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            _FilterBar(controller: _controller),
            const SizedBox(height: 8),
            Text(
              'Bungie slots · ${display.length}'
              '${all.length != display.length ? ' of ${all.length}' : ''}',
              key: const Key('loadouts_count'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_controller.isLoading && !_controller.hasLoadedOnce)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    key: Key('loadouts_loading'),
                  ),
                ),
              )
            else if (display.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No in-game loadouts to show. Equip a loadout in Destiny '
                    'or turn off “Hiding empty”.',
                    key: const Key('loadouts_empty'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  key: const Key('loadouts_list'),
                  itemCount: display.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final lo = display[i];
                    return _LoadoutTile(loadout: lo);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final LoadoutsController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('loadouts_filters'),
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          key: const Key('loadouts_filter_hide_empty'),
          label: Text(controller.hideEmpty ? 'Hiding empty' : 'Show empty'),
          selected: controller.hideEmpty,
          onSelected: (v) => controller.setHideEmpty(v),
        ),
        for (final cls in const ['Titan', 'Hunter', 'Warlock'])
          FilterChip(
            key: Key('loadouts_filter_class_$cls'),
            label: Text(cls),
            selected: controller.classFilter == cls,
            onSelected: (selected) {
              controller.setClassFilter(selected ? cls : null);
            },
          ),
      ],
    );
  }
}

class _LoadoutTile extends StatelessWidget {
  const _LoadoutTile({required this.loadout});

  final BungieInGameLoadout loadout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = StringBuffer()
      ..write(loadout.className)
      ..write(' · Light ')
      ..write(loadout.characterLight)
      ..write(' · Slot ')
      ..write(loadout.index + 1);
    if (loadout.empty) {
      subtitle.write(' · Empty');
    } else {
      subtitle.write(' · ${loadout.itemInstanceIds.length} items');
    }

    Widget leading;
    if (loadout.iconUrl != null) {
      leading = Image.network(
        loadout.iconUrl!,
        width: 32,
        height: 32,
        errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports),
      );
    } else {
      leading = const Icon(Icons.sports_esports);
    }

    return Card(
      key: Key('loadout_tile_${loadout.id}'),
      child: ListTile(
        leading: leading,
        title: Text(loadout.name),
        subtitle: Text(subtitle.toString()),
        trailing: loadout.empty
            ? Text(
                'Empty',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}
