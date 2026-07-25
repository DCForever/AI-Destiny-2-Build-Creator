/// Synergies library page (DART-046).
library;

import 'dart:async';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../builds/builds_page.dart' show BuildsPage;
import '../compose/compose_styles.dart';
import 'synergies_controller.dart';

/// Synergies list and create form.
class SynergiesPage extends StatefulComponent {
  const SynergiesPage({
    this.controller,
    super.key,
  });

  final SynergiesController? controller;

  static const String titleText = 'Synergies';
  static const String subtitleText =
      'Designation is immutable after create. Evidence links optional.';
  static const String emptyText = 'No synergies yet.';

  @override
  State<SynergiesPage> createState() => _SynergiesPageState();
}

class _SynergiesPageState extends State<SynergiesPage> {
  String _name = '';
  String _type = 'melee';
  String _subType = '';
  String _linkName = '';
  String _linkHash = '';
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
  void didUpdateComponent(covariant SynergiesPage oldComponent) {
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
    final links = <SynergyLinkWrite>[];
    final hash = int.tryParse(_linkHash.trim());
    if (_linkName.trim().isNotEmpty && hash != null) {
      links.add(
        SynergyLinkWrite(
          kind: 'weapon',
          displayName: _linkName.trim(),
          itemHash: hash,
        ),
      );
    }
    final err = await c.createSynergy(
      name: _name.trim().isEmpty ? 'Untitled synergy' : _name.trim(),
      type: _type.trim().isEmpty ? 'melee' : _type.trim(),
      subType: _subType.trim().isEmpty ? null : _subType.trim(),
      links: links,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
    });
  }

  @override
  Component build(BuildContext context) {
    final c = component.controller;
    if (c == null) {
      return section(
        classes: 'compose-page',
        attributes: {
          'data-page': 'synergies',
          'data-testid': 'synergies-blocked',
        },
        [
          h1([.text(SynergiesPage.titleText)]),
          p([.text(BuildsPage.blockedText)]),
        ],
      );
    }

    return section(
      classes: 'compose-page',
      attributes: {'data-page': 'synergies', 'data-testid': 'synergies-page'},
      [
        h1([.text(SynergiesPage.titleText)]),
        p(classes: 'compose-sub', [.text(SynergiesPage.subtitleText)]),
        div(
          classes: 'compose-card',
          attributes: {'data-testid': 'create-synergy-form'},
          [
            h2([.text('Create synergy')]),
            label([
              .text('Name'),
              input(
                type: InputType.text,
                value: _name,
                attributes: {'data-testid': 'create-synergy-name'},
                onInput: (v) => setState(() => _name = '$v'),
              ),
            ]),
            label([
              .text('Type'),
              input(
                type: InputType.text,
                value: _type,
                attributes: {'data-testid': 'create-synergy-type'},
                onInput: (v) => setState(() => _type = '$v'),
              ),
            ]),
            label([
              .text('Sub-type (optional)'),
              input(
                type: InputType.text,
                value: _subType,
                attributes: {'data-testid': 'create-synergy-subtype'},
                onInput: (v) => setState(() => _subType = '$v'),
              ),
            ]),
            label([
              .text('Evidence weapon name (optional)'),
              input(
                type: InputType.text,
                value: _linkName,
                attributes: {'data-testid': 'create-synergy-link-name'},
                onInput: (v) => setState(() => _linkName = '$v'),
              ),
            ]),
            label([
              .text('Evidence item hash (optional)'),
              input(
                type: InputType.text,
                value: _linkHash,
                attributes: {'data-testid': 'create-synergy-link-hash'},
                onInput: (v) => setState(() => _linkHash = '$v'),
              ),
            ]),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'create-synergy-submit',
                if (_busy) 'disabled': 'true',
              },
              events: {'click': (_) => unawaited(_create())},
              [.text('Create synergy')],
            ),
          ],
        ),
        if (c.synergies.isEmpty)
          p(
            attributes: {'data-testid': 'synergies-empty'},
            [.text(SynergiesPage.emptyText)],
          )
        else
          ul(
            [
              for (final s in c.synergies)
                li(
                  [
                    .text(
                      '${s.name} · ${c.designationOf(s)}'
                      '${s.links.isEmpty ? '' : ' · ${s.links.length} link(s)'}',
                    ),
                  ],
                  attributes: {'data-testid': 'synergy-row-${s.id}'},
                ),
            ],
            classes: 'compose-list',
            attributes: {'data-testid': 'synergies-list'},
          ),
        if (_formError != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'synergies-error'},
            [.text(_formError!)],
          ),
        if (c.error != null) p(classes: 'compose-error', [.text(c.error!)]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
