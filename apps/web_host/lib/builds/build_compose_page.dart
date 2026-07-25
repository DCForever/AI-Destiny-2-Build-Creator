/// Linear build compose detail (DART-046).
library;

import 'dart:async';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../compose/compose_styles.dart';
import '../compose/soft_guidance_format.dart';
import 'builds_controller.dart';
import 'builds_page.dart';

/// Build detail: identity → variants → attachments/pins → soft guidance.
class BuildComposePage extends StatefulComponent {
  const BuildComposePage({
    required this.buildId,
    this.controller,
    super.key,
  });

  final String buildId;
  final BuildsController? controller;

  @override
  State<BuildComposePage> createState() => _BuildComposePageState();
}

class _BuildComposePageState extends State<BuildComposePage> {
  String _variantName = '';
  String _attachSetId = '';
  String _pinInstance = '';
  String _healthTarget = '';
  String? _status;
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
      unawaited(_open(c));
    }
  }

  Future<void> _open(BuildsController c) async {
    await c.openBuild(component.buildId);
    if (!mounted) return;
    final h = c.softStatTargets[ArmorStatName.health];
    setState(() {
      _healthTarget = h?.toString() ?? '';
    });
  }

  @override
  void didUpdateComponent(covariant BuildComposePage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller ||
        oldComponent.buildId != component.buildId) {
      oldComponent.controller?.removeListener(_onController);
      component.controller?.addListener(_onController);
      final c = component.controller;
      if (c != null) unawaited(_open(c));
    }
  }

  @override
  void dispose() {
    component.controller?.removeListener(_onController);
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() op) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final err = await op();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = err;
    });
  }

  @override
  Component build(BuildContext context) {
    final c = component.controller;
    if (c == null) {
      return section(
        classes: 'compose-page',
        attributes: {
          'data-page': 'build-compose',
          'data-testid': 'compose-blocked',
        },
        [
          h1([.text('Build compose')]),
          p([.text(BuildsPage.blockedText)]),
          p([Link(to: '/builds', child: .text('← Builds'))]),
        ],
      );
    }

    final sel = c.selected;
    if (sel == null) {
      return section(
        classes: 'compose-page',
        attributes: {'data-testid': 'compose-loading'},
        [
          h1([.text('Build compose')]),
          p([.text(c.loading ? 'Loading…' : (c.error ?? 'Build not found'))]),
          p([Link(to: '/builds', child: .text('← Builds'))]),
        ],
      );
    }

    final b = sel.build;
    return section(
      classes: 'compose-page',
      attributes: {
        'data-page': 'build-compose',
        'data-testid': 'build-compose-page',
      },
      [
        p([Link(to: '/builds', child: .text('← Builds'))]),
        h1([.text(c.titleOf(b))]),
        if (_status != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'compose-status-error'},
            [.text(_status!)],
          ),
        if (c.error != null && _status == null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'compose-controller-error'},
            [.text(c.error!)],
          ),
        div(
          classes: 'compose-section',
          attributes: {
            'data-testid': 'compose-section-identity',
            'id': 'compose_section_identity',
          },
          [
            h2([.text('Identity')]),
            p([.text(c.identitySummaryOf(b))]),
            p([.text('Synergies: ${c.synergySummaryOf(b)}')]),
          ],
        ),
        div(
          classes: 'compose-section',
          attributes: {
            'data-testid': 'compose-section-variants',
            'id': 'compose_section_variants',
          },
          [
            h2([.text('Variants')]),
            ul(
              [
                for (final v in c.variants)
                  li([
                    button(
                      classes: c.selectedVariant?.id == v.id
                          ? 'compose-btn'
                          : 'compose-btn-ghost',
                      attributes: {
                        'type': 'button',
                        'data-testid': 'variant-${v.id}',
                      },
                      events: {
                        'click': (_) => unawaited(c.selectVariant(v.id)),
                      },
                      [
                        .text(
                          '${v.name}${v.isDefault ? ' (default)' : ''}'
                          '${c.selectedVariant?.id == v.id ? ' · selected' : ''}',
                        ),
                      ],
                    ),
                  ]),
              ],
              attributes: {'data-testid': 'variant-list'},
            ),
            label([
              .text('New non-default variant'),
              input(
                type: InputType.text,
                value: _variantName,
                attributes: {
                  'data-testid': 'create-variant-name',
                  'placeholder': 'Variant name',
                },
                onInput: (v) => setState(() => _variantName = '$v'),
              ),
            ]),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'create-variant-submit',
                if (_busy) 'disabled': 'true',
              },
              events: {
                'click': (_) => unawaited(
                      _run(() => c.createVariant(name: _variantName)),
                    ),
              },
              [.text('Create variant')],
            ),
          ],
        ),
        div(
          classes: 'compose-section',
          attributes: {
            'data-testid': 'compose-section-attachments',
            'id': 'compose_section_attachments',
          },
          [
            h2([.text('Attachments & pins')]),
            if (c.attachments.isEmpty)
              p(
                attributes: {'data-testid': 'attachments-empty'},
                [.text('No sets attached.')],
              )
            else
              ul(
                [
                  for (final a in c.attachments)
                    li([
                      .text(a.summary),
                      button(
                        attributes: {
                          'type': 'button',
                          'data-testid': 'detach-${a.record.setId}',
                        },
                        events: {
                          'click': (_) => unawaited(
                                _run(() => c.detachSet(a.record.setId)),
                              ),
                        },
                        [.text(' Detach')],
                      ),
                    ]),
                ],
                attributes: {'data-testid': 'attachments-list'},
              ),
            if (c.slotPins.isNotEmpty)
              ul(
                [
                  for (final pin in c.slotPins)
                    li(
                      [
                        .text(
                          '${pin.slot}: ${pin.itemName} · ${pin.pinDetail}',
                        ),
                      ],
                      attributes: {
                        'data-testid': 'slot-pin-${pin.slot}',
                        'data-pin-label': pin.pinLabel,
                      },
                    ),
                ],
                attributes: {'data-testid': 'slot-pins-list'},
              ),
            label([
              .text('Attach set id'),
              input(
                type: InputType.text,
                value: _attachSetId,
                attributes: {
                  'data-testid': 'attach-set-id',
                  'placeholder': 'Library set id',
                },
                onInput: (v) => setState(() => _attachSetId = '$v'),
              ),
            ]),
            if (c.attachableSets.isNotEmpty)
              p(
                attributes: {'data-testid': 'attachable-sets-hint'},
                [
                  .text(
                    'Available: ${c.attachableSets.map((s) => '${s.name}(${s.id})').join(', ')}',
                  ),
                ],
              ),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'attach-set-submit',
                if (_busy) 'disabled': 'true',
              },
              events: {
                'click': (_) => unawaited(
                      _run(() => c.attachSet(_attachSetId)),
                    ),
              },
              [.text('Attach set')],
            ),
            if (c.slotPins.any((p) => p.canEditPin)) ...[
              label([
                .text('Pin instance id (first live pin)'),
                input(
                  type: InputType.text,
                  value: _pinInstance,
                  attributes: {
                    'data-testid': 'pin-instance-id',
                    'placeholder': 'instance id or empty to clear',
                  },
                  onInput: (v) => setState(() => _pinInstance = '$v'),
                ),
              ]),
              button(
                classes: 'compose-btn',
                attributes: {
                  'type': 'button',
                  'data-testid': 'pin-instance-submit',
                },
                events: {
                  'click': (_) {
                    final pin = c.slotPins.firstWhere((p) => p.canEditPin);
                    unawaited(
                      _run(
                        () => c.pinSlot(
                          setId: pin.setId,
                          slot: pin.slot,
                          instanceId: _pinInstance.trim().isEmpty
                              ? null
                              : _pinInstance.trim(),
                          setItemId: pin.setItemId,
                        ),
                      ),
                    );
                  },
                },
                [.text('Save pin')],
              ),
            ],
          ],
        ),
        div(
          classes: 'compose-section',
          attributes: {
            'data-testid': 'builds-soft-guidance',
            'id': 'builds_soft_guidance',
          },
          [
            h2([.text('Soft guidance')]),
            p(
              classes: 'soft-advisory',
              attributes: {'data-testid': 'soft-advisory'},
              [.text(c.softGuidanceAdvisory)],
            ),
            div(
              attributes: {'data-testid': 'soft-chips'},
              [
                if (c.synergyCoverageRows.isEmpty)
                  p([.text('No synergy coverage rows.')])
                else
                  for (final row in c.synergyCoverageRows)
                    span(
                      classes: 'soft-chip ${coverageTierToneKey(row.tier)}',
                      attributes: {
                        'data-testid': 'soft-chip-${row.synergyId}',
                        'data-tier': row.tier.wireName,
                      },
                      [.text(formatSynergyCoverageChipLabel(row))],
                    ),
              ],
            ),
            label([
              .text('Health soft target'),
              input(
                type: InputType.text,
                value: _healthTarget,
                attributes: {
                  'data-testid': 'soft-stat-health',
                  'placeholder': 'e.g. 100',
                },
                onInput: (v) => setState(() => _healthTarget = '$v'),
              ),
            ]),
            button(
              classes: 'compose-btn',
              attributes: {
                'type': 'button',
                'data-testid': 'soft-stat-save',
              },
              events: {
                'click': (_) => unawaited(
                      _run(
                        () => c.saveSoftStatTargetsFromFields({
                          ArmorStatName.health.wireName: _healthTarget,
                        }),
                      ),
                    ),
              },
              [.text('Save soft targets')],
            ),
            if (c.softStatTargetsSummary.isNotEmpty)
              p(
                attributes: {'data-testid': 'soft-stat-summary'},
                [.text('Saved: ${c.softStatTargetsSummary}')],
              ),
          ],
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
