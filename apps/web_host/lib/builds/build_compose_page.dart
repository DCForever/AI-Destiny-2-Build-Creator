/// Linear build compose detail (DART-046) + equip/DIM (DART-047).
library;

import 'dart:async';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../compose/compose_styles.dart';
import '../compose/finish_gaps_format.dart';
import '../compose/soft_guidance_format.dart';
import '../dim_export/dim_export_controller.dart';
import '../dim_export/dim_export_format.dart';
import '../equip/equip_controller.dart';
import '../equip/equip_format.dart';
import 'builds_controller.dart';
import 'builds_page.dart';

/// Build detail: identity → variants → attachments/pins → soft → equip → DIM.
class BuildComposePage extends StatefulComponent {
  const BuildComposePage({
    required this.buildId,
    this.controller,
    this.equipController,
    this.dimExportController,
    super.key,
  });

  final String buildId;
  final BuildsController? controller;
  final EquipController? equipController;
  final DimExportController? dimExportController;

  @override
  State<BuildComposePage> createState() => _BuildComposePageState();
}

class _BuildComposePageState extends State<BuildComposePage> {
  String _variantName = '';
  String _attachSetId = '';
  String _pinInstance = '';
  final Map<String, String> _softStatFields = {
    for (final s in ArmorStatName.all) s.wireName: '',
  };
  String? _status;
  bool _busy = false;
  String? _boundVariantKey;

  void _onController() {
    if (mounted) {
      final c = component.controller;
      if (c != null) _syncSoftStatFields(c);
      setState(() {});
      unawaited(_syncEquipExportBindings());
    }
  }

  @override
  void initState() {
    super.initState();
    final c = component.controller;
    if (c != null) {
      c.addListener(_onController);
      unawaited(_open(c));
    }
    component.equipController?.addListener(_onController);
    component.dimExportController?.addListener(_onController);
  }

  Future<void> _open(BuildsController c) async {
    await c.openBuild(component.buildId);
    if (!mounted) return;
    _syncSoftStatFields(c);
    setState(() {});
    await _syncEquipExportBindings();
  }

  void _syncSoftStatFields(BuildsController c) {
    for (final stat in ArmorStatName.all) {
      final v = c.softStatTargets[stat];
      _softStatFields[stat.wireName] = v?.toString() ?? '';
    }
  }

  Future<void> _syncEquipExportBindings() async {
    final builds = component.controller;
    final equip = component.equipController;
    final dim = component.dimExportController;
    if (builds == null) return;

    final uid = builds.userId;
    final sel = builds.selected;
    final variant = builds.selectedVariant;
    if (uid == null || sel == null || variant == null) {
      if (_boundVariantKey != null) {
        _boundVariantKey = null;
        equip?.clearBinding();
        dim?.clearBinding();
      }
      return;
    }

    final key = '${uid}:${sel.build.id}:${variant.id}';
    if (key == _boundVariantKey) return;
    _boundVariantKey = key;

    await dim?.bind(
      userId: uid,
      buildId: sel.build.id,
      variantId: variant.id,
    );
    await equip?.bind(
      userId: uid,
      buildId: sel.build.id,
      variantId: variant.id,
      buildClass: sel.build.className,
    );
  }

  @override
  void didUpdateComponent(covariant BuildComposePage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller ||
        oldComponent.buildId != component.buildId ||
        oldComponent.equipController != component.equipController ||
        oldComponent.dimExportController != component.dimExportController) {
      oldComponent.controller?.removeListener(_onController);
      oldComponent.equipController?.removeListener(_onController);
      oldComponent.dimExportController?.removeListener(_onController);
      component.controller?.addListener(_onController);
      component.equipController?.addListener(_onController);
      component.dimExportController?.addListener(_onController);
      _boundVariantKey = null;
      final c = component.controller;
      if (c != null) unawaited(_open(c));
    }
  }

  @override
  void dispose() {
    component.controller?.removeListener(_onController);
    component.equipController?.removeListener(_onController);
    component.dimExportController?.removeListener(_onController);
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
    await _syncEquipExportBindingsAfterMutate();
  }

  Future<void> _syncEquipExportBindingsAfterMutate() async {
    // Re-evaluate readiness after pin/attach mutations.
    _boundVariantKey = null;
    await _syncEquipExportBindings();
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
    final equip = component.equipController;
    final dim = component.dimExportController;

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
                        'click': (_) => unawaited(() async {
                              await c.selectVariant(v.id);
                              _boundVariantKey = null;
                              await _syncEquipExportBindings();
                            }()),
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
            p(
              classes: 'soft-advisory',
              attributes: {'data-testid': 'soft-stat-editor-caption'},
              [
                .text(
                  'Soft stat targets (all Armor 3.0 stats). Explicit save only — '
                  'never auto-applied.',
                ),
              ],
            ),
            for (final stat in ArmorStatName.all)
              label([
                .text('${stat.wireName} soft target'),
                input(
                  type: InputType.text,
                  value: _softStatFields[stat.wireName] ?? '',
                  attributes: {
                    'data-testid': 'soft-stat-${stat.wireName.toLowerCase()}',
                    'placeholder': 'e.g. 100',
                  },
                  onInput: (v) => setState(
                    () => _softStatFields[stat.wireName] = '$v',
                  ),
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
                        () => c.saveSoftStatTargetsFromFields(
                          Map<String, String>.from(_softStatFields),
                        ),
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
        _buildFinishGapsSection(c),
        _buildEquipSection(equip, finishComplete: c.finishComplete),
        _buildDimSection(dim, finishComplete: c.finishComplete),
      ],
    );
  }

  Component _buildFinishGapsSection(BuildsController c) {
    final gaps = c.finishGaps;
    return div(
      classes: 'compose-section',
      attributes: {
        'data-testid': 'finish_gaps_panel',
        'id': 'finish_gaps_panel',
      },
      [
        h2([.text('Finish readiness')]),
        p(
          classes: 'soft-advisory',
          attributes: {'data-testid': 'finish_gaps_policy'},
          [.text(kFinishGapsPolicyCaption)],
        ),
        if (gaps == null)
          p(
            attributes: {'data-testid': 'finish_gaps_empty'},
            [.text('Select a variant to evaluate finish gaps.')],
          )
        else ...[
          p(
            attributes: {
              'data-testid': 'finish_gaps_complete_summary',
              'data-finish-complete': gaps.complete ? 'true' : 'false',
            },
            [.text(formatFinishGapsCompleteSummary(gaps))],
          ),
          ul(
            [
              for (final gap in gaps.gaps)
                li(
                  attributes: {
                    'data-testid': 'finish_gap_${gap.category.wireName}',
                  },
                  [.text(formatFinishGapRowSummary(gap))],
                ),
            ],
            attributes: {'data-testid': 'finish_gaps_list'},
          ),
        ],
      ],
    );
  }

  Component _buildEquipSection(
    EquipController? equip, {
    required bool finishComplete,
  }) {
    if (equip == null) {
      return div(
        classes: 'compose-section',
        attributes: {
          'data-testid': 'equip_panel',
          'id': 'equip_panel',
        },
        [
          h2([.text('Equip')]),
          p(
            attributes: {'data-testid': 'equip-unavailable'},
            [
              .text(
                'Optional equip requires sign-in wiring (profile + write clients). '
                'DIM export still available below when finish-complete and equip-ready.',
              ),
            ],
          ),
        ],
      );
    }

    final equipCtaEnabled = canEnableEquipCta(
      signedIn: equip.isSignedIn,
      equipReady: equip.equipReady,
      characterId: equip.selectedCharacterId,
      equipping: equip.equipping,
      loading: equip.loadingCharacters || equip.loadingReadiness,
      finishComplete: finishComplete,
    );

    return div(
      classes: 'compose-section',
      attributes: {
        'data-testid': 'equip_panel',
        'id': 'equip_panel',
      },
      [
        h2([.text('Equip')]),
        p(
          classes: 'soft-advisory',
          attributes: {'data-testid': 'equip-soft-advisory'},
          [.text(equip.softAdvisory)],
        ),
        if (!finishComplete)
          p(
            attributes: {'data-testid': 'equip_finish_incomplete_hint'},
            [.text(kFinishIncompleteCtaCaption)],
          ),
        p(
          attributes: {
            'data-testid': 'equip_ready_summary',
            'data-equip-ready': equip.equipReady ? 'true' : 'false',
            'data-finish-complete': finishComplete ? 'true' : 'false',
          },
          [.text(equip.readinessSummary)],
        ),
        if (equip.pinStatuses.isNotEmpty)
          ul(
            [
              for (final s in equip.pinStatuses)
                li([.text(formatPinStatusLabel(s))]),
            ],
            attributes: {'data-testid': 'equip_pin_gaps'},
          ),
        if (!equip.isSignedIn)
          p(
            attributes: {'data-testid': 'equip-sign-in-hint'},
            [.text('Sign in to equip to a character.')],
          )
        else ...[
          if (equip.matchingCharacters.isEmpty)
            p(
              attributes: {'data-testid': 'equip-no-matching-class'},
              [.text(formatNoMatchingClassMessage(equip.buildClass))],
            )
          else ...[
            p(
              attributes: {'data-testid': 'equip_character_select'},
              [.text('Character:')],
            ),
            ul(
              [
                for (final ch in equip.matchingCharacters)
                  li([
                    button(
                      classes: equip.selectedCharacterId == ch.characterId
                          ? 'compose-btn'
                          : 'compose-btn-ghost',
                      attributes: {
                        'type': 'button',
                        'data-testid': 'equip_character_${ch.characterId}',
                      },
                      events: {
                        'click': (_) => equip.selectCharacter(ch.characterId),
                      },
                      [.text(formatCharacterOptionLabel(ch))],
                    ),
                  ]),
              ],
              attributes: {'data-testid': 'equip_character_list'},
            ),
          ],
          button(
            classes: 'compose-btn',
            attributes: {
              'type': 'button',
              'data-testid': 'equip_apply_button',
              if (!equipCtaEnabled) 'disabled': 'true',
            },
            events: {
              'click': (_) => unawaited(() async {
                    if (!equipCtaEnabled) return;
                    await equip.requestEquip();
                    if (mounted) setState(() {});
                  }()),
            },
            [.text(equip.equipping ? 'Equipping…' : 'Apply to character')],
          ),
          if (equip.pendingGaps != null)
            div(
              attributes: {'data-testid': 'equip_gaps_confirm'},
              [
                p([.text(kEquipGapsConfirmCaption)]),
                p([
                  .text(
                    formatEmptyCombatGapsSummary(
                      equip.pendingGaps!.emptyCombatSlots,
                    ),
                  ),
                ]),
                button(
                  classes: 'compose-btn',
                  attributes: {
                    'type': 'button',
                    'data-testid': 'equip_gaps_confirm_btn',
                  },
                  events: {
                    'click': (_) =>
                        unawaited(equip.confirmGapsAndEquip()),
                  },
                  [.text('Confirm equip with gaps')],
                ),
                button(
                  classes: 'compose-btn-ghost',
                  attributes: {
                    'type': 'button',
                    'data-testid': 'equip_gaps_cancel_btn',
                  },
                  events: {
                    'click': (_) {
                      equip.cancelGapsConfirm();
                    },
                  },
                  [.text('Cancel')],
                ),
              ],
            ),
          if (equip.lastStatus != null) ...[
            p(
              attributes: {'data-testid': 'equip_status_summary'},
              [.text(equip.statusMessage ?? '')],
            ),
            ul(
              [
                for (final line in equip.stepReportLines) li([.text(line)]),
              ],
              attributes: {'data-testid': 'equip_step_report'},
            ),
          ],
        ],
        if (equip.error != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'equip_error'},
            [.text(equip.error!)],
          ),
        if (equip.statusMessage != null && equip.lastStatus == null)
          p(
            attributes: {'data-testid': 'equip_status_message'},
            [.text(equip.statusMessage!)],
          ),
      ],
    );
  }

  Component _buildDimSection(
    DimExportController? dim, {
    required bool finishComplete,
  }) {
    if (dim == null) {
      return div(
        classes: 'compose-section',
        attributes: {'data-testid': 'dim_export_panel'},
        [
          h2([.text('DIM export')]),
          p([.text('DIM export unavailable.')]),
        ],
      );
    }

    final dimCtaEnabled = canEnableDimExportCta(
      equipReady: dim.equipReady,
      exporting: dim.exporting,
      loading: dim.loadingReadiness,
      hasVariant: true,
      finishComplete: finishComplete,
    );

    return div(
      classes: 'compose-section',
      attributes: {
        'data-testid': 'dim_export_panel',
        'id': 'dim_export_panel',
      },
      [
        h2([.text('DIM export')]),
        p(
          classes: 'soft-advisory',
          attributes: {'data-testid': 'dim_export_soft_advisory'},
          [.text(dim.softAdvisory)],
        ),
        if (!finishComplete)
          p(
            attributes: {'data-testid': 'dim_export_finish_incomplete_hint'},
            [.text(kFinishIncompleteCtaCaption)],
          ),
        p(
          attributes: {
            'data-testid': 'dim_export_ready_summary',
            'data-equip-ready': dim.equipReady ? 'true' : 'false',
            'data-finish-complete': finishComplete ? 'true' : 'false',
          },
          [.text(dim.readinessSummary)],
        ),
        if (dim.pinStatuses.isNotEmpty)
          ul(
            [
              for (final s in dim.pinStatuses)
                li([.text(formatDimExportPinStatusLabel(s))]),
            ],
            attributes: {'data-testid': 'dim_export_pin_gaps'},
          ),
        button(
          classes: 'compose-btn',
          attributes: {
            'type': 'button',
            'data-testid': 'dim_export_copy_button',
            if (!dimCtaEnabled) 'disabled': 'true',
          },
          events: {
            'click': (_) => unawaited(() async {
                  if (!dimCtaEnabled) return;
                  await dim.requestExport();
                }()),
          },
          [
            .text(
              dim.exporting ? 'Exporting…' : 'Copy DIM JSON',
            ),
          ],
        ),
        if (dim.statusMessage != null)
          p(
            attributes: {'data-testid': 'dim_export_status_message'},
            [.text(dim.statusMessage!)],
          ),
        if (dim.error != null)
          p(
            classes: 'compose-error',
            attributes: {'data-testid': 'dim_export_error'},
            [.text(dim.error!)],
          ),
        if (dim.jsonPreview != null)
          p(
            classes: 'dim-json-preview',
            attributes: {'data-testid': 'dim_export_json_preview'},
            [.text(dim.jsonPreview!)],
          ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => composePageStyles;
}
