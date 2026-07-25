/// Sets library page (DART-046).
library;

import 'dart:async';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../builds/builds_page.dart' show BuildsPage;
import '../compose/compose_styles.dart';
import 'sets_controller.dart';

/// Sets list, create, and slot fill form.
class SetsPage extends StatefulComponent {
  const SetsPage({
    this.controller,
    super.key,
  });

  final SetsController? controller;

  static const String titleText = 'Sets';
  static const String subtitleText =
      'Library sets for variant attach. Fill slots with hash + name.';
  static const String emptyText = 'No sets yet.';

  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  String _name = '';
  String _typeWire = SetType.weapon.wireName;
  String _slot = 'primary';
  String _itemHash = '';
  String _itemName = '';
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
  void didUpdateComponent(covariant SetsPage oldComponent) {
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
    final type = SetType.tryParse(_typeWire) ?? SetType.weapon;
    final err = await c.createSet(
      name: _name.trim().isEmpty ? 'Untitled set' : _name.trim(),
      type: type,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
    });
  }

  Future<void> _fill() async {
    final c = component.controller;
    if (c == null || c.selected == null || _busy) return;
    final hash = int.tryParse(_itemHash.trim());
    if (hash == null || hash <= 0) {
      setState(() => _formError = 'Item hash must be a positive integer');
      return;
    }
    setState(() {
      _busy = true;
      _formError = null;
    });
    final err = await c.fillSlot(
      _slot.trim(),
      SetSlotPickResult(
        itemHash: hash,
        itemName: _itemName.trim().isEmpty ? 'Item $hash' : _itemName.trim(),
      ),
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
        attributes: {'data-page': 'sets', 'data-testid': 'sets-blocked'},
        [
          h1([.text(SetsPage.titleText)]),
          p([.text(BuildsPage.blockedText)]),
        ],
      );
    }

    return section(
      classes: 'compose-page',
      attributes: {'data-page': 'sets', 'data-testid': 'sets-page'},
      [
        h1([.text(SetsPage.titleText)]),
        p(classes: 'compose-sub', [.text(SetsPage.subtitleText)]),
        div(
          classes: 'compose-card',
          attributes: {'data-testid': 'create-set-form'},
          [
            h2([.text('Create set')]),
            label([
              .text('Name'),
              input(
                type: InputType.text,
                value: _name,
                attributes: {'data-testid': 'create-set-name'},
                onInput: (v) => setState(() => _name = '$v'),
              ),
            ]),
            label([
              .text('Type (weapon, armor, mod, pair, fashion)'),
              input(
                type: InputType.text,
                value: _typeWire,
                attributes: {'data-testid': 'create-set-type'},
                onInput: (v) => setState(() => _typeWire = '$v'),
              ),
            ]),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'create-set-submit',
                if (_busy) 'disabled': 'true',
              },
              events: {'click': (_) => unawaited(_create())},
              [.text('Create set')],
            ),
          ],
        ),
        if (c.sets.isEmpty)
          p(
            attributes: {'data-testid': 'sets-empty'},
            [.text(SetsPage.emptyText)],
          )
        else
          ul(
            [
              for (final s in c.sets)
                li([
                  button(
                    attributes: {
                      'type': 'button',
                      'data-testid': 'set-row-${s.id}',
                    },
                    events: {
                      'click': (_) => unawaited(c.selectSet(s.id)),
                    },
                    [
                      .text(
                        '${s.name} (${s.type})'
                        '${c.selected?.set.id == s.id ? ' · selected' : ''}',
                      ),
                    ],
                  ),
                ]),
            ],
            classes: 'compose-list',
            attributes: {'data-testid': 'sets-list'},
          ),
        if (c.selected != null)
          div(
            classes: 'compose-section',
            attributes: {'data-testid': 'set-detail'},
            [
              h2([.text('Selected: ${c.selected!.set.name}')]),
              p([
                .text(
                  'Id: ${c.selected!.set.id} · items: '
                  '${c.selected!.activeItems.length}',
                ),
              ]),
              if (c.selected!.activeItems.isNotEmpty)
                ul([
                  for (final i in c.selected!.activeItems)
                    li([
                      .text(
                        '${i.slot}: ${i.itemName} (${i.itemHash})'
                        '${i.instanceId != null ? ' · ${i.instanceId}' : ''}',
                      ),
                    ]),
                ]),
              label([
                .text('Slot'),
                input(
                  type: InputType.text,
                  value: _slot,
                  attributes: {'data-testid': 'fill-slot-name'},
                  onInput: (v) => setState(() => _slot = '$v'),
                ),
              ]),
              label([
                .text('Item hash'),
                input(
                  type: InputType.text,
                  value: _itemHash,
                  attributes: {'data-testid': 'fill-item-hash'},
                  onInput: (v) => setState(() => _itemHash = '$v'),
                ),
              ]),
              label([
                .text('Item name'),
                input(
                  type: InputType.text,
                  value: _itemName,
                  attributes: {'data-testid': 'fill-item-name'},
                  onInput: (v) => setState(() => _itemName = '$v'),
                ),
              ]),
              button(
                classes: 'compose-btn',
                attributes: {
                  'type': 'button',
                  'data-testid': 'fill-slot-submit',
                },
                events: {'click': (_) => unawaited(_fill())},
                [.text('Fill slot')],
              ),
            ],
          ),
        if (_formError != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'sets-error'},
            [.text(_formError!)],
          ),
        if (c.error != null) p(classes: 'compose-error', [.text(c.error!)]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
