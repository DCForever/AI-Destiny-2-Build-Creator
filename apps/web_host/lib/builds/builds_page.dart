/// Builds library list + create form (DART-046).
library;

import 'dart:async';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../compose/compose_styles.dart';
import 'builds_controller.dart';

/// Builds list and create intent form.
class BuildsPage extends StatefulComponent {
  const BuildsPage({
    this.controller,
    super.key,
  });

  /// Null when writer DB is unavailable (blocked tab).
  final BuildsController? controller;

  static const String titleText = 'Builds';
  static const String blockedText =
      'Compose requires the writer tab. This tab is blocked from opening '
      'the local database. Close other tabs or use the writer tab.';
  static const String emptyText = 'No builds yet. Create one to start compose.';
  static const String subtitleText =
      'Intent → compose. Hard Destiny limits block; soft guidance never auto-applies.';

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  String _name = '';
  String _classWire = GuardianClass.hunter.wireName;
  String _synergyType = 'melee';
  String? _formError;
  bool _busy = false;

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
  void didUpdateComponent(covariant BuildsPage oldComponent) {
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

  Future<void> _create() async {
    final c = component.controller;
    if (c == null || _busy) return;
    setState(() {
      _busy = true;
      _formError = null;
    });
    final className =
        GuardianClass.tryParse(_classWire) ?? GuardianClass.hunter;
    final err = await c.createBuild(
      name: _name.trim().isEmpty ? null : _name.trim(),
      className: className,
      synergyTypes: [
        DraftSynergyType(
          type: _synergyType.trim().isEmpty ? 'melee' : _synergyType,
        ),
      ],
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
    });
    if (err == null && c.selected != null) {
      final id = c.selected!.build.id;
      Router.of(context).push('/builds/$id');
    }
  }

  @override
  Component build(BuildContext context) {
    final c = component.controller;
    if (c == null) {
      return section(
        classes: 'compose-page',
        attributes: {'data-page': 'builds', 'data-testid': 'builds-blocked'},
        [
          h1([.text(BuildsPage.titleText)]),
          p(
            classes: 'compose-blocked',
            attributes: {'data-testid': 'builds-blocked-message'},
            [.text(BuildsPage.blockedText)],
          ),
        ],
      );
    }

    return section(
      classes: 'compose-page',
      attributes: {'data-page': 'builds', 'data-testid': 'builds-page'},
      [
        h1([.text(BuildsPage.titleText)]),
        p(classes: 'compose-sub', [.text(BuildsPage.subtitleText)]),
        div(
          classes: 'compose-card',
          attributes: {'data-testid': 'create-build-form'},
          [
            h2([.text('Create build')]),
            label([
              .text('Name'),
              input(
                type: InputType.text,
                value: _name,
                attributes: {
                  'data-testid': 'create-build-name',
                  'placeholder': 'Optional name',
                },
                onInput: (v) => setState(() => _name = '$v'),
              ),
            ]),
            label([
              .text('Class (Titan, Hunter, Warlock)'),
              input(
                type: InputType.text,
                value: _classWire,
                attributes: {
                  'data-testid': 'create-build-class',
                  'placeholder': 'Hunter',
                },
                onInput: (v) => setState(() => _classWire = '$v'),
              ),
            ]),
            label([
              .text('Synergy type'),
              input(
                type: InputType.text,
                value: _synergyType,
                attributes: {
                  'data-testid': 'create-build-synergy',
                  'placeholder': 'e.g. melee',
                },
                onInput: (v) => setState(() => _synergyType = '$v'),
              ),
            ]),
            if (_formError != null)
              p(
                classes: 'compose-error',
                attributes: {'data-testid': 'create-build-error'},
                [.text(_formError!)],
              ),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'create-build-submit',
                if (_busy) 'disabled': 'true',
              },
              events: {
                'click': (_) => unawaited(_create()),
              },
              [.text(_busy ? 'Creating…' : 'Create build')],
            ),
          ],
        ),
        if (c.loading && c.builds.isEmpty)
          p(
            attributes: {'data-testid': 'builds-loading'},
            [.text('Loading builds…')],
          ),
        if (c.error != null && c.builds.isEmpty)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'builds-error'},
            [.text(c.error!)],
          ),
        if (!c.loading && c.builds.isEmpty)
          p(
            attributes: {'data-testid': 'builds-empty'},
            [.text(BuildsPage.emptyText)],
          ),
        if (c.builds.isNotEmpty)
          ul(
            [
              for (final b in c.builds)
                li(
                  [
                    Link(
                      to: '/builds/${b.id}',
                      child: .text(
                        '${c.titleOf(b)} · ${c.identitySummaryOf(b)} · '
                        '${c.synergySummaryOf(b)}',
                      ),
                    ),
                  ],
                  classes: 'compose-list-item',
                  attributes: {'data-testid': 'build-row-${b.id}'},
                ),
            ],
            classes: 'compose-list',
            attributes: {'data-testid': 'builds-list'},
          ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
