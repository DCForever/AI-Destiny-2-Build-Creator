/// In-Game Loadouts page for Jaspr (DART-055).
library;

import 'dart:async';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../compose/compose_styles.dart';
import 'loadouts_controller.dart';

/// Bungie character loadouts list (component 206).
class LoadoutsPage extends StatefulComponent {
  const LoadoutsPage({
    this.controller,
    super.key,
  });

  final LoadoutsController? controller;

  static const String titleText = 'In-Game Loadouts';
  static const String subtitleText =
      'Bungie character loadouts with real icon and color (same source as DIM). '
      'Sign in to sync from your profile.';
  static const String signedOutText =
      'Sign in with Bungie to view your in-game loadout slots and icons.';
  static const String emptyText =
      'No in-game loadouts to show. Equip a loadout in Destiny or turn off '
      '“Hiding empty”.';

  @override
  State<LoadoutsPage> createState() => _LoadoutsPageState();
}

class _LoadoutsPageState extends State<LoadoutsPage> {
  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final c = component.controller;
    if (c != null) {
      c.addListener(_onController);
      unawaited(c.refresh());
    }
  }

  @override
  void didUpdateComponent(covariant LoadoutsPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      oldComponent.controller?.removeListener(_onController);
      component.controller?.addListener(_onController);
      final c = component.controller;
      if (c != null) unawaited(c.refresh());
    }
  }

  @override
  void dispose() {
    component.controller?.removeListener(_onController);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final c = component.controller;
    return section(
      classes: 'compose-page loadouts-page',
      attributes: {'data-page': 'loadouts'},
      [
        header(classes: 'compose-header', [
          h1([.text(LoadoutsPage.titleText)]),
          p(classes: 'compose-subtitle', [.text(LoadoutsPage.subtitleText)]),
        ]),
        if (c == null)
          p(
            classes: 'compose-hint',
            attributes: {'data-testid': 'loadouts-no-services'},
            [
              .text(
                'Loadouts requires a signed-in session and profile client. '
                'Open Settings to sign in.',
              ),
            ],
          )
        else if (!c.isSignedIn)
          p(
            classes: 'compose-hint',
            attributes: {'data-testid': 'loadouts-signed-out'},
            [.text(LoadoutsPage.signedOutText)],
          )
        else ...[
          div(
            classes: 'loadouts-filters',
            attributes: {'data-testid': 'loadouts-filters'},
            [
              button(
                classes: c.hideEmpty ? 'chip active' : 'chip',
                attributes: {'data-testid': 'loadouts-hide-empty'},
                onClick: () => c.setHideEmpty(!c.hideEmpty),
                [.text(c.hideEmpty ? 'Hiding empty' : 'Show empty')],
              ),
              for (final cls in const ['Titan', 'Hunter', 'Warlock'])
                button(
                  classes: c.classFilter == cls ? 'chip active' : 'chip',
                  attributes: {'data-testid': 'loadouts-class-$cls'},
                  onClick: () => c.setClassFilter(
                    c.classFilter == cls ? null : cls,
                  ),
                  [.text(cls)],
                ),
              button(
                classes: 'chip',
                attributes: {'data-testid': 'loadouts-refresh'},
                onClick: c.isLoading ? null : () => unawaited(c.refresh()),
                [.text(c.isLoading ? 'Loading…' : 'Refresh')],
              ),
            ],
          ),
          if (c.errorMessage != null)
            p(
              classes: 'compose-error',
              attributes: {'data-testid': 'loadouts-error'},
              [.text(c.errorMessage!)],
            ),
          if (c.hintMessage != null && c.errorMessage == null)
            p(
              classes: 'compose-hint',
              attributes: {'data-testid': 'loadouts-hint'},
              [.text(c.hintMessage!)],
            ),
          p(
            classes: 'compose-meta',
            attributes: {'data-testid': 'loadouts-count'},
            [
              .text(
                'Bungie slots · ${c.displayLoadouts.length}'
                '${c.allLoadouts.length != c.displayLoadouts.length ? ' of ${c.allLoadouts.length}' : ''}',
              ),
            ],
          ),
          if (c.isLoading && !c.hasLoadedOnce)
            p([.text('Loading Bungie loadouts…')])
          else if (c.displayLoadouts.isEmpty)
            p(
              attributes: {'data-testid': 'loadouts-empty'},
              [.text(LoadoutsPage.emptyText)],
            )
          else
            ul(
              classes: 'loadouts-list',
              attributes: {'data-testid': 'loadouts-list'},
              [
                for (final lo in c.displayLoadouts) _loadoutItem(lo),
              ],
            ),
        ],
      ],
    );
  }

  Component _loadoutItem(BungieInGameLoadout lo) {
    final subtitle = StringBuffer()
      ..write(lo.className)
      ..write(' · Light ')
      ..write(lo.characterLight)
      ..write(' · Slot ')
      ..write(lo.index + 1);
    if (lo.empty) {
      subtitle.write(' · Empty');
    } else {
      subtitle.write(' · ${lo.itemInstanceIds.length} items');
    }
    return li(
      classes: 'loadout-item',
      attributes: {'data-loadout-id': lo.id},
      [
        if (lo.iconUrl != null)
          img(
            src: lo.iconUrl!,
            alt: '',
            attributes: {'width': '28', 'height': '28'},
          ),
        div([
          strong([.text(lo.name)]),
          p(classes: 'compose-meta', [.text(subtitle.toString())]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
        ...composePageStyles,
        css('.loadouts-filters', [
          css('&').styles(
            display: .flex,
            margin: .only(bottom: 0.75.rem),
            flexDirection: .row,
            flexWrap: .wrap,
            gap: Gap(row: 0.35.rem, column: 0.35.rem),
          ),
          css('.chip').styles(
            padding: .symmetric(horizontal: 0.65.rem, vertical: 0.3.rem),
            border: .all(style: .solid, width: 1.px),
            cursor: .pointer,
            fontSize: 0.8.rem,
          ),
        ]),
        css('.loadouts-list', [
          css('&').styles(
            margin: .zero,
            padding: .zero,
            listStyle: .none,
          ),
          css('.loadout-item').styles(
            display: .flex,
            margin: .only(bottom: 0.5.rem),
            padding: .all(0.75.rem),
            border: .all(style: .solid, width: 1.px),
            gap: Gap(column: 0.75.rem),
            alignItems: .center,
          ),
        ]),
      ];
}
