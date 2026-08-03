/// Synergies library page with dual-pane manage (DART-046 / DART-066).
library;

import 'dart:async';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../builds/builds_page.dart' show BuildsPage;
import '../compose/compose_styles.dart';
import 'synergies_controller.dart';

/// Synergies list, filters, detail edit/links, catalog evidence picker, delete.
class SynergiesPage extends StatefulComponent {
  const SynergiesPage({
    this.controller,
    this.catalogItems,
    super.key,
  });

  final SynergiesController? controller;
  final List<CatalogItem>? catalogItems;

  static const String titleText = 'Synergies';
  static const String subtitleText =
      'Designation is immutable after create. Catalog evidence picker omits '
      'already-linked targets. Soft never auto-applies.';
  static const String emptyText = 'No synergies yet.';

  @override
  State<SynergiesPage> createState() => _SynergiesPageState();
}

class _SynergiesPageState extends State<SynergiesPage> {
  String _name = '';
  String _type = 'melee';
  String _subType = '';
  String _editName = '';
  String _editDesc = '';
  String _linkKind = 'weapon';
  String _evidenceQuery = '';
  String _searchQuery = '';
  String? _formError;
  bool _busy = false;
  bool _deleteConfirm = false;

  void _onController() {
    final sel = component.controller?.selected;
    if (sel != null) {
      _editName = sel.name;
      _editDesc = sel.description;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final c = component.controller;
    if (c != null) {
      if (component.catalogItems != null && c.catalogItems.isEmpty) {
        c.catalogItems = component.catalogItems!;
      }
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
    final err = await c.createSynergy(
      name: _name.trim().isEmpty ? 'Untitled synergy' : _name.trim(),
      type: _type.trim().isEmpty ? 'melee' : _type.trim(),
      subType: _subType.trim().isEmpty ? null : _subType.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
      if (err == null) {
        _name = '';
        _subType = '';
      }
    });
  }

  Future<void> _saveIdentity() async {
    final c = component.controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    final err = await c.updateSelectedIdentity(
      name: _editName,
      description: _editDesc,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
    });
  }

  Future<void> _saveLinks() async {
    final c = component.controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    final err = await c.saveDraftLinks();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = err;
    });
  }

  Future<void> _delete() async {
    final c = component.controller;
    if (c == null || _busy) return;
    if (!_deleteConfirm) {
      setState(() => _deleteConfirm = true);
      return;
    }
    setState(() {
      _busy = true;
      _deleteConfirm = false;
    });
    final err = await c.deleteSelected();
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

    final sel = c.selected;
    final evidenceHits = sel == null
        ? const <SynergyPickerHit>[]
        : c.searchEvidence(linkKind: _linkKind, query: _evidenceQuery);

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
        div(
          classes: 'compose-card',
          attributes: {'data-testid': 'synergies-filters'},
          [
            label([
              .text('Search library'),
              input(
                type: InputType.text,
                value: _searchQuery,
                attributes: {'data-testid': 'synergies-search'},
                onInput: (v) {
                  final q = '$v';
                  setState(() => _searchQuery = q);
                  c.setSearchQuery(q);
                },
              ),
            ]),
            div(
              attributes: {'data-testid': 'synergies-type-filters'},
              [
                for (final t in creatableSynergyTypeWires.take(8))
                  button(
                    classes: c.typeFacets.contains(t)
                        ? 'compose-btn'
                        : 'compose-btn-outline',
                    attributes: {
                      'type': 'button',
                      'data-testid': 'synergies-type-chip-$t',
                    },
                    events: {
                      'click': (_) {
                        c.toggleTypeFacet(t);
                        setState(() {});
                      },
                    },
                    [.text(t)],
                  ),
              ],
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
                li([
                  button(
                    attributes: {
                      'type': 'button',
                      'data-testid': 'synergy-row-${s.id}',
                    },
                    events: {
                      'click': (_) => unawaited(c.selectSynergy(s.id)),
                    },
                    [
                      .text(
                        '${s.name} · ${c.designationOf(s)}'
                        '${s.links.isEmpty ? '' : ' · ${s.links.length} link(s)'}'
                        '${c.selected?.id == s.id ? ' · selected' : ''}',
                      ),
                    ],
                  ),
                ]),
            ],
            classes: 'compose-list',
            attributes: {'data-testid': 'synergies-list'},
          ),
        if (sel != null)
          div(
            classes: 'compose-section',
            attributes: {'data-testid': 'synergy-detail'},
            [
              h2([.text('Selected: ${sel.name}')]),
              p(
                attributes: {'data-testid': 'synergy-detail-designation'},
                [
                  .text(
                    'Designation locked: ${c.designationOf(sel)}',
                  ),
                ],
              ),
              label([
                .text('Name'),
                input(
                  type: InputType.text,
                  value: _editName,
                  attributes: {'data-testid': 'synergy-edit-name'},
                  onInput: (v) => setState(() => _editName = '$v'),
                ),
              ]),
              label([
                .text('Description'),
                input(
                  type: InputType.text,
                  value: _editDesc,
                  attributes: {'data-testid': 'synergy-edit-description'},
                  onInput: (v) => setState(() => _editDesc = '$v'),
                ),
              ]),
              button(
                classes: 'compose-btn',
                attributes: {
                  'type': 'button',
                  'data-testid': 'synergy-save-identity',
                  if (_busy) 'disabled': 'true',
                },
                events: {'click': (_) => unawaited(_saveIdentity())},
                [.text('Save')],
              ),
              button(
                classes: 'compose-btn-outline',
                attributes: {
                  'type': 'button',
                  'data-testid': 'synergy-delete',
                  if (_busy) 'disabled': 'true',
                },
                events: {'click': (_) => unawaited(_delete())},
                [
                  .text(
                    _deleteConfirm ? 'Confirm delete' : 'Delete',
                  ),
                ],
              ),
              h3([.text('Evidence links')]),
              if (c.draftLinks.isEmpty)
                p(
                  attributes: {'data-testid': 'synergies-links-empty'},
                  [.text('No evidence links yet.')],
                )
              else
                ul(
                  attributes: {'data-testid': 'synergies-links-list'},
                  [
                    for (var i = 0; i < c.draftLinks.length; i++)
                      li(
                        attributes: {'data-testid': 'synergies-link-row-$i'},
                        [
                          .text(
                            '${c.draftLinks[i].kind}: ${c.draftLinks[i].displayName}'
                            '${c.draftLinks[i].required ? ' [required]' : ''}',
                          ),
                          button(
                            attributes: {
                              'type': 'button',
                              'data-testid': 'synergies-link-required-$i',
                              'data-required':
                                  c.draftLinks[i].required ? 'true' : 'false',
                            },
                            events: {
                              'click': (_) {
                                c.setDraftLinkRequired(
                                  i,
                                  !c.draftLinks[i].required,
                                );
                                setState(() {});
                              },
                            },
                            [
                              .text(
                                c.draftLinks[i].required
                                    ? 'Required ✓'
                                    : 'Mark required',
                              ),
                            ],
                          ),
                          button(
                            attributes: {
                              'type': 'button',
                              'data-testid': 'synergies-link-remove-$i',
                            },
                            events: {
                              'click': (_) {
                                c.removeDraftLinkAt(i);
                                setState(() {});
                              },
                            },
                            [.text('Remove')],
                          ),
                        ],
                      ),
                  ],
                ),
              h3([.text('Catalog evidence picker')]),
              label([
                .text('Kind'),
                input(
                  type: InputType.text,
                  value: _linkKind,
                  attributes: {'data-testid': 'synergies-link-kind'},
                  onInput: (v) => setState(() => _linkKind = '$v'),
                ),
              ]),
              label([
                .text('Search catalog'),
                input(
                  type: InputType.text,
                  value: _evidenceQuery,
                  attributes: {'data-testid': 'synergies-evidence-search'},
                  onInput: (v) => setState(() => _evidenceQuery = '$v'),
                ),
              ]),
              if (evidenceHits.isEmpty)
                p(
                  attributes: {'data-testid': 'synergies-evidence-empty'},
                  [.text('No catalog hits (already-linked omitted).')],
                )
              else
                ul(
                  attributes: {'data-testid': 'synergies-evidence-results'},
                  [
                    for (final hit in evidenceHits.take(12))
                      li([
                        .text(
                          '${hit.name}'
                          '${hit.sourceLabel != null ? ' · ${hit.sourceLabel}' : ''}'
                          ' · #${hit.hash ?? '-'}',
                        ),
                        button(
                          attributes: {
                            'type': 'button',
                            'data-testid':
                                'synergies-evidence-add-${hit.hash ?? hit.name}',
                          },
                          events: {
                            'click': (_) {
                              final err = c.addPickerHitToDraft(hit);
                              setState(() => _formError = err);
                            },
                          },
                          [.text('Add')],
                        ),
                      ]),
                  ],
                ),
              button(
                classes: 'compose-btn',
                attributes: {
                  'type': 'button',
                  'data-testid': 'synergies-links-save',
                  if (_busy) 'disabled': 'true',
                },
                events: {'click': (_) => unawaited(_saveLinks())},
                [.text('Save links')],
              ),
            ],
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
