/// Sets library page with dense rows + embedded catalog fill (DART-046/065).
library;

import 'dart:async';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    show
        ArmorSetStatTotals,
        CatalogInstanceProjection,
        armorBaseStatKeys,
        sumArmorSetStats,
        ArmorStatPieceInput;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../builds/builds_page.dart' show BuildsPage;
import '../catalog/owned_catalog_bridge.dart';
import '../compose/compose_styles.dart';
import '../compose/set_slot_mapping.dart';
import 'sets_controller.dart';

/// Sets list, create, dense detail, and catalog slot fill.
class SetsPage extends StatefulComponent {
  const SetsPage({
    this.controller,
    this.bridge,
    this.catalogItems,
    super.key,
  });

  final SetsController? controller;

  /// Owned × catalog join for fill density + instance perks (optional).
  final OwnedCatalogBridge? bridge;

  /// Injected catalog rows for tests when [bridge] is null.
  final List<CatalogItem>? catalogItems;

  static const String titleText = 'Sets';
  static const String subtitleText =
      'Library sets for variant attach. Dense rows, armor base-roll board, '
      'catalog fill (named search — not hash-only). Soft never auto-applies.';
  static const String emptyText = 'No sets yet.';

  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  String _name = '';
  String _typeWire = SetType.weapon.wireName;
  String? _formError;
  bool _busy = false;

  /// Slot currently being filled (null = no fill panel).
  String? _fillSlot;
  String _fillQuery = '';
  CatalogScope _fillScope = CatalogScope.all;
  CatalogItem? _fillSelected;
  List<CatalogInstanceProjection> _fillInstances = const [];
  String? _pendingReplaceName;
  SetSlotPickResult? _pendingPick;
  bool _bridgeReady = false;

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
    unawaited(_ensureBridge());
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

  Future<void> _ensureBridge() async {
    final b = component.bridge;
    if (b == null) {
      if (mounted) setState(() => _bridgeReady = true);
      return;
    }
    try {
      await b.refresh(reloadEntities: true);
    } catch (_) {
      // Fill still works from injected catalogItems.
    }
    if (mounted) setState(() => _bridgeReady = true);
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

  List<CatalogItem> _catalogBase() {
    final b = component.bridge;
    if (b != null && b.annotatedBase.isNotEmpty) {
      return b.browse(const CatalogClientFilters());
    }
    return component.catalogItems ?? const [];
  }

  List<CatalogItem> _fillResults(String slot) {
    final q = _fillQuery.trim().toLowerCase();
    var items = _catalogBase()
        .where((i) => catalogItemMatchesSetSlot(i.slot, slot))
        .toList();
    if (_fillScope == CatalogScope.owned) {
      items = items.where((i) => i.owned).toList();
    }
    if (q.isNotEmpty) {
      items = items
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                '${i.hash}'.contains(q) ||
                (i.itemTypeName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return items;
  }

  void _openFill(String slot) {
    setState(() {
      _fillSlot = slot;
      _fillQuery = '';
      _fillScope = CatalogScope.all;
      _fillSelected = null;
      _fillInstances = const [];
      _pendingReplaceName = null;
      _pendingPick = null;
      _formError = null;
    });
  }

  void _selectFillItem(CatalogItem item) {
    final b = component.bridge;
    final treatArmor = isArmorBoardSlot(item.slot ?? '') ||
        (item.sourceStore?.contains('armor') ?? false);
    final instances =
        b?.instancesFor(item.hash, treatAsArmor: treatArmor) ?? const [];
    setState(() {
      _fillSelected = item;
      _fillInstances = instances;
    });
  }

  Future<void> _tryCommit(SetSlotPickResult pick) async {
    final c = component.controller;
    final slot = _fillSlot;
    if (c == null || slot == null || _busy) return;

    if (c.needsReplaceConfirm(slot) && _pendingPick == null) {
      final occ = c.occupantForSlot(slot);
      setState(() {
        _pendingPick = pick;
        _pendingReplaceName = occ?.itemName ?? 'current item';
      });
      return;
    }

    setState(() {
      _busy = true;
      _formError = null;
      _pendingPick = null;
      _pendingReplaceName = null;
    });
    final err = await c.fillSlot(slot, pick);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
      if (err == null) {
        _fillSlot = null;
        _fillSelected = null;
        _fillInstances = const [];
      }
    });
  }

  Future<void> _confirmReplace() async {
    final pick = _pendingPick;
    if (pick == null) return;
    await _tryCommit(pick);
  }

  void _cancelReplace() {
    setState(() {
      _pendingPick = null;
      _pendingReplaceName = null;
      _formError = 'Replace cancelled';
    });
  }

  void _pinInstance(CatalogInstanceProjection inst) {
    final item = _fillSelected;
    if (item == null) return;
    unawaited(
      _tryCommit(
        SetSlotPickResult(
          itemHash: item.hash,
          itemName: item.name,
          instanceId: inst.instanceId,
          selectedPerks: selectedPerksFromInstance(inst),
        ),
      ),
    );
  }

  void _pinWishlist() {
    final item = _fillSelected;
    if (item == null) return;
    unawaited(
      _tryCommit(
        SetSlotPickResult(
          itemHash: item.hash,
          itemName: item.name,
        ),
      ),
    );
  }

  ArmorSetStatTotals? _armorTotals(SetsController c) {
    final sel = c.selected;
    if (sel == null) return null;
    if (sel.set.type != SetType.armor.wireName) return null;
    final b = component.bridge;
    final pieces = <ArmorStatPieceInput>[];
    for (final item in sel.activeItems) {
      if (!isArmorBoardSlot(item.slot)) continue;
      CatalogInstanceProjection? inst;
      if (item.instanceId != null && b != null) {
        final list = b.instancesFor(item.itemHash, treatAsArmor: true);
        for (final i in list) {
          if (i.instanceId == item.instanceId) {
            inst = i;
            break;
          }
        }
      }
      pieces.add(
        ArmorStatPieceInput.fromBoard(
          inst?.armorStats,
          instanceId: item.instanceId,
        ),
      );
    }
    return sumArmorSetStats(pieces);
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

    final sel = c.selected;
    final setType =
        sel != null ? (SetType.tryParse(sel.set.type) ?? SetType.weapon) : null;
    final boardSlots = setType != null ? slotsForSetType(setType) : const <String>[];
    final armorTotals = _armorTotals(c);

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
        if (sel != null) ...[
          div(
            classes: 'compose-section',
            attributes: {'data-testid': 'set-detail'},
            [
              h2([.text('Selected: ${sel.set.name}')]),
              p([
                .text(
                  'Type: ${sel.set.type} · items: ${sel.activeItems.length}',
                ),
              ]),
              if (armorTotals != null)
                div(
                  attributes: {'data-testid': 'sets-armor-stat-board'},
                  [
                    h3([
                      .text(
                        'Armor base-roll totals'
                        '${armorTotals.incomplete ? ' (incomplete)' : ''}',
                      ),
                    ]),
                    p([
                      .text(
                        [
                          for (final k in armorBaseStatKeys)
                            '$k ${armorTotals.statValues[k] ?? '—'}',
                          'Total ${armorTotals.grandTotal}',
                        ].join(' · '),
                      ),
                    ]),
                  ],
                ),
              for (final slot in boardSlots)
                _slotRow(c, sel, slot),
            ],
          ),
          if (_fillSlot != null) _fillPanel(_fillSlot!),
          if (_pendingReplaceName != null)
            div(
              classes: 'compose-card',
              attributes: {'data-testid': 'sets-replace-confirm'},
              [
                p([
                  .text(
                    'Replace "$_pendingReplaceName" in this slot?',
                  ),
                ]),
                button(
                  classes: 'compose-btn',
                  attributes: {
                    'type': 'button',
                    'data-testid': 'sets-replace-confirm-btn',
                  },
                  events: {'click': (_) => unawaited(_confirmReplace())},
                  [.text('Confirm replace')],
                ),
                button(
                  attributes: {
                    'type': 'button',
                    'data-testid': 'sets-replace-cancel-btn',
                  },
                  events: {'click': (_) => _cancelReplace()},
                  [.text('Cancel')],
                ),
              ],
            ),
        ],
        if (_formError != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'sets-error'},
            [.text(_formError!)],
          ),
        if (c.error != null) p(classes: 'compose-error', [.text(c.error!)]),
        if (!_bridgeReady)
          p(
            attributes: {'data-testid': 'sets-bridge-loading'},
            [.text('Loading catalog…')],
          ),
      ],
    );
  }

  Component _slotRow(SetsController c, SetDetail sel, String slot) {
    final items = sel.activeItems
        .where((i) => i.slot == slot || i.slot.startsWith('$slot:'))
        .toList();
    final filled = items.isNotEmpty;
    final item = filled ? items.first : null;
    final hasInstance =
        item?.instanceId != null && item!.instanceId!.isNotEmpty;

    CatalogItem? catalog;
    if (item != null) {
      for (final i in _catalogBase()) {
        if (i.hash == item.itemHash) {
          catalog = i;
          break;
        }
      }
    }

    CatalogInstanceProjection? inst;
    if (item != null && hasInstance && component.bridge != null) {
      final list = component.bridge!.instancesFor(
        item.itemHash,
        treatAsArmor: isArmorBoardSlot(slot),
      );
      for (final i in list) {
        if (i.instanceId == item.instanceId) {
          inst = i;
          break;
        }
      }
    }

    final meta = item == null
        ? const <String>[]
        : buildSetItemMetaChips(
            isExotic: catalog?.isExotic,
            element: catalog?.element,
            ammo: catalog?.ammo,
            itemTypeName: catalog?.itemTypeName,
            frame: catalog?.frame,
            power: inst?.power,
            location: inst?.location,
            hasInstance: hasInstance,
          );

    final traits = item == null
        ? const <SetItemPerkDisplay>[]
        : traitPerksForDisplay(
            selectedPerks: item.selectedPerks,
            plugCards: inst?.plugCards ?? const [],
            plugNameByHash: component.bridge?.plugNameByHash ?? const {},
          );

    final linked = <SetItemLinkedSynergy>[];
    if (catalog != null && component.bridge != null) {
      for (final b in component.bridge!.badgesFor(catalog)) {
        linked.add(SetItemLinkedSynergy(id: b.id, label: b.name));
      }
    }

    return div(
      classes: 'compose-card',
      attributes: {
        'data-testid': 'sets-slot-row-$slot',
        if (filled) 'data-filled': 'true',
      },
      [
        strong([.text(setSlotDisplayLabel(slot))]),
        if (!filled)
          p(
            attributes: {'data-testid': 'sets-slot-empty-$slot'},
            [.text('Empty')],
          )
        else ...[
          p(
            attributes: {
              'data-testid': 'sets-slot-filled-$slot',
              'data-item-hash': '${item!.itemHash}',
              if (hasInstance) 'data-instance': item.instanceId!,
              'data-pin-kind': hasInstance ? 'instance' : 'wishlist',
            },
            [
              .text(
                '${item.itemName} (${item.itemHash})',
              ),
            ],
          ),
          p(
            attributes: {'data-testid': 'sets-slot-meta-$slot'},
            [.text(meta.join(' · '))],
          ),
          if (traits.isNotEmpty)
            p(
              attributes: {'data-testid': 'sets-slot-traits-$slot'},
              [
                .text(
                  'Traits: ${traits.map((t) => t.name).join(', ')}',
                ),
              ],
            ),
          if (linked.isNotEmpty)
            p(
              attributes: {'data-testid': 'sets-slot-synergies-$slot'},
              [
                .text(
                  'Linked synergies: ${linked.map((s) => s.label).join(', ')}',
                ),
              ],
            ),
          if (isArmorBoardSlot(slot))
            p(
              attributes: {'data-testid': 'sets-slot-stats-$slot'},
              [
                .text(
                  inst?.armorStats != null
                      ? [
                          for (final k in armorBaseStatKeys)
                            if (inst!.armorStats!.stats[k] != null)
                              '$k ${inst.armorStats!.stats[k]}',
                        ].join(' · ')
                      : hasInstance
                          ? 'No armor stats on this copy — re-sync inventory.'
                          : 'Wishlist — no instance rolls.',
                ),
              ],
            ),
        ],
        button(
          classes: 'compose-btn',
          attributes: {
            'type': 'button',
            'data-testid': 'sets-slot-fill-$slot',
          },
          events: {'click': (_) => _openFill(slot)},
          [.text(filled ? 'Replace' : 'Fill')],
        ),
      ],
    );
  }

  Component _fillPanel(String slot) {
    final results = _fillResults(slot);
    return div(
      classes: 'compose-card',
      attributes: {
        'data-testid': 'sets-fill-panel',
        'data-fill-slot': slot,
      },
      [
        h3([.text('Fill ${setSlotDisplayLabel(slot)}')]),
        p([
          .text(
            'Search catalog by name. All | Owned. Pin instance or wishlist. '
            'Not hash-only.',
          ),
        ]),
        label([
          .text('Search'),
          input(
            type: InputType.text,
            value: _fillQuery,
            attributes: {'data-testid': 'sets-fill-query'},
            onInput: (v) => setState(() => _fillQuery = '$v'),
          ),
        ]),
        div([
          button(
            attributes: {
              'type': 'button',
              'data-testid': 'sets-fill-scope-all',
              if (_fillScope == CatalogScope.all) 'data-selected': 'true',
            },
            events: {
              'click': (_) => setState(() => _fillScope = CatalogScope.all),
            },
            [.text('All')],
          ),
          button(
            attributes: {
              'type': 'button',
              'data-testid': 'sets-fill-scope-owned',
              if (_fillScope == CatalogScope.owned) 'data-selected': 'true',
            },
            events: {
              'click': (_) => setState(() => _fillScope = CatalogScope.owned),
            },
            [.text('Owned')],
          ),
        ]),
        if (results.isEmpty)
          p(
            attributes: {'data-testid': 'sets-fill-empty'},
            [
              .text(
                _catalogBase().isEmpty
                    ? 'No catalog items loaded. Open Catalog to load entity bundles, or inject fixtures.'
                    : 'No items match this slot / search.',
              ),
            ],
          )
        else
          ul(
            attributes: {'data-testid': 'sets-fill-list'},
            [
              for (final item in results.take(40))
                li([
                  button(
                    attributes: {
                      'type': 'button',
                      'data-testid': 'sets-fill-item-${item.hash}',
                      if (_fillSelected?.hash == item.hash)
                        'data-selected': 'true',
                    },
                    events: {'click': (_) => _selectFillItem(item)},
                    [
                      .text(
                        [
                          item.name,
                          if (item.isExotic) 'Exotic',
                          if (item.element != null) item.element!,
                          if (item.itemTypeName != null) item.itemTypeName!,
                          if (item.owned) 'owned×${item.ownedCount}',
                        ].join(' · '),
                      ),
                    ],
                  ),
                ]),
            ],
          ),
        if (_fillSelected != null) ...[
          p([
            .text('Selected: ${_fillSelected!.name}'),
          ]),
          if (_fillInstances.isEmpty)
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'sets-fill-wishlist',
              },
              events: {'click': (_) => _pinWishlist()},
              [.text('Pin as wishlist (definition only)')],
            )
          else ...[
            ul(
              attributes: {'data-testid': 'sets-fill-instances'},
              [
                for (final inst in _fillInstances)
                  li([
                    button(
                      attributes: {
                        'type': 'button',
                        'data-testid':
                            'sets-fill-instance-${inst.instanceId}',
                      },
                      events: {'click': (_) => _pinInstance(inst)},
                      [
                        .text(
                          'Power ${inst.power} · ${inst.location}'
                          '${inst.plugCards.where((c) => c.isTrait).isNotEmpty ? ' · ${inst.plugCards.where((c) => c.isTrait).map((c) => c.displayName).take(2).join(", ")}' : ''}',
                        ),
                      ],
                    ),
                  ]),
              ],
            ),
            button(
              attributes: {
                'type': 'button',
                'data-testid': 'sets-fill-wishlist',
              },
              events: {'click': (_) => _pinWishlist()},
              [.text('Definition only (wishlist)')],
            ),
          ],
        ],
        button(
          attributes: {
            'type': 'button',
            'data-testid': 'sets-fill-close',
          },
          events: {
            'click': (_) => setState(() {
                  _fillSlot = null;
                  _fillSelected = null;
                  _pendingPick = null;
                  _pendingReplaceName = null;
                }),
          },
          [.text('Close fill')],
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
