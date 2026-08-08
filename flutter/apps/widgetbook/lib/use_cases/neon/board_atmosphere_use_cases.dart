import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Shell blooms + horizon',
  type: NeonShellBackground,
  path: '[Neon]/Atmosphere',
)
Widget neonShellFull(BuildContext context) {
  return NeonShellBackground(
    child: Center(
      child: NeonZone(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Neon shell · blooms + horizon',
          style: neonDisplay(fontSize: 16),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Shell blooms only (no horizon)',
  type: NeonShellBackground,
  path: '[Neon]/Atmosphere',
)
Widget neonShellBloomsOnly(BuildContext context) {
  return NeonShellBackground(
    showHorizon: false,
    child: Center(
      child: NeonZone(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Blooms only',
          style: neonBody(fontSize: 14),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'NeonZone soft surface',
  type: NeonZone,
  path: '[Neon]/Atmosphere',
)
Widget neonZone(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: NeonZone(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONE', style: neonMono(fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'Soft content zone — no cyan cage.',
            style: neonBody(fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Flap board header + rows (sets template)',
  type: FlapBoardHeader,
  path: '[Neon]/Board',
)
Widget flapBoardSets(BuildContext context) {
  final template = kFlapColumnsSets;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlapBoardHeader(template: template),
        FlapBoardRow(
          template: template,
          onTap: () {},
          cells: [
            for (final label in template.headerLabels)
              FlapTextCell(
                text: label.toLowerCase() == 'name' ? 'Solar Well' : '—',
                primary: label.toLowerCase() == 'name',
              ),
          ],
        ),
        FlapBoardRow(
          template: template,
          selected: true,
          onTap: () {},
          cells: [
            for (var i = 0; i < template.headerLabels.length; i++)
              FlapTextCell(text: i == 0 ? 'Void Loop' : 'demo', primary: i == 0),
          ],
        ),
        FlapBoardRow(
          template: template,
          onTap: () {},
          cells: [
            for (var i = 0; i < template.headerLabels.length; i++)
              FlapTextCell(text: i == 0 ? 'Arc Chain' : 'demo', primary: i == 0),
          ],
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Flap board · builds template',
  type: FlapBoardHeader,
  path: '[Neon]/Board',
)
Widget flapBoardBuilds(BuildContext context) {
  final template = kFlapColumnsBuilds;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlapBoardHeader(template: template),
        FlapBoardRow(
          template: template,
          cells: [
            for (var i = 0; i < template.headerLabels.length; i++)
              FlapTextCell(
                text: i == 0 ? 'Prism Hunter' : '—',
                primary: i == 0,
              ),
          ],
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Blooms / horizon / caption',
  type: NeonShellBackground,
  path: '[Neon]/Atmosphere/Knobs',
)
Widget neonAtmosphereKnobs(BuildContext context) {
  final blooms = context.knobs.boolean(label: 'Blooms', initialValue: true);
  final horizon = context.knobs.boolean(label: 'Horizon', initialValue: true);
  final label = context.knobs.string(
    label: 'Caption',
    initialValue: 'Neon Network',
  );
  return NeonShellBackground(
    showBlooms: blooms,
    showHorizon: horizon,
    child: Center(
      child: NeonZone(
        padding: const EdgeInsets.all(20),
        child: Text(label, style: neonDisplay(fontSize: 18)),
      ),
    ),
  );
}
