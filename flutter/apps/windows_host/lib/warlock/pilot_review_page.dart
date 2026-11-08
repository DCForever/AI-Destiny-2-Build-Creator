import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loads the bundled trimmed fixture. It does not read live inventory.
Future<PilotBoard> loadBundledPilotBoard() async {
  final matrix = await rootBundle.loadString(
    'assets/pilot/contrast_matrix.json',
  );
  final csvText = await rootBundle.loadString(
    'assets/pilot/contrast_queue.csv',
  );
  return loadPilotBoard(matrixJson: matrix, csvText: csvText);
}

class PilotReviewLoader extends StatefulWidget {
  const PilotReviewLoader({super.key});

  @override
  State<PilotReviewLoader> createState() => _PilotReviewLoaderState();
}

class _PilotReviewLoaderState extends State<PilotReviewLoader> {
  late final Future<PilotBoard> _future = loadBundledPilotBoard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PilotBoard>(
      future: _future,
      builder: (context, snapshot) {
        final board = snapshot.data;
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('${snapshot.error}')));
        }
        if (board == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PilotReviewPage(board: board);
      },
    );
  }
}

/// Local review of the five contrasting rows.
class PilotReviewPage extends StatelessWidget {
  const PilotReviewPage({super.key, required this.board});

  final PilotBoard board;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline build pilot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SYNTHETIC inventory, proposals, and DIM JSON are fixtures. '
              'They are not owned gear and not an account-verified loadout.',
              key: Key('pilot_synthetic_banner'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Run: from the flutter/ directory, '
              'dart test packages/domain/test/pilot_parse_test.dart '
              'packages/domain/test/pilot_gate_test.dart '
              'and from apps/windows_host, '
              'flutter test test/pilot_review_page_test.dart. '
              'In the app, open Warlocks and choose Offline pilot. '
              'The bundled files are a trimmed copy of five community rows, '
              'not a guardian inventory.',
            ),
            const SizedBox(height: 16),
            for (final review in board.cases) _CaseSection(review: review),
            _ProposalSection(board: board),
            const _ShapeSample(),
          ],
        ),
      ),
    );
  }
}

class _CaseSection extends StatelessWidget {
  const _CaseSection({required this.review});

  final PilotCaseReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('pilot_case_${review.caseId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review.caseId, style: Theme.of(context).textTheme.titleMedium),
            const Text('Title is a label, not the gameplay loop.'),
            for (final note in review.ambiguityNotes) Text(note),
            Text(
              'No personal DIM output',
              key: Key('pilot_no_export_${review.caseId}'),
            ),
            Text('Export allowed: ${review.exportAllowed}'),
            for (final reason in review.caseReasons) Text('Case: $reason'),
            for (final row in review.records) _RecordBlock(row: row),
          ],
        ),
      ),
    );
  }
}

class _RecordBlock extends StatelessWidget {
  const _RecordBlock({required this.row});

  final PilotRecordReview row;

  @override
  Widget build(BuildContext context) {
    final record = row.record;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Title: ${record.buildName}'),
          Text('Creator: ${record.creator}'),
          Text(record.sourceDetail),
          Text('Original link: ${record.originalDimLink}'),
          Text('Personal link: ${_show(record.personalDimLink)}'),
          Text('Does: ${_show(record.doesText)}'),
          Text('Loop: ${_show(record.loopText)}'),
          Text('Subclass: ${_show(record.subclassText)}'),
          Text(
            'Perks: ${_show(record.classItemPerk1)} + ${_show(record.classItemPerk2)}',
          ),
          Text(
            'Ergo: ${_show(record.ergoTrait)} / ${_show(record.ergoElement)} / ${_show(record.ergoFrame)}',
          ),
          Text('Set proposal: ${record.armorSetProposal}'),
          Text(row.reasons.isEmpty
              ? 'Row gaps: none'
              : 'Row gaps: ${row.reasons.join(', ')}'),
        ],
      ),
    );
  }
}

class _ProposalSection extends StatelessWidget {
  const _ProposalSection({required this.board});

  final PilotBoard board;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Exact perk checks against the synthetic catalog'),
        for (final check in board.perkChecks)
          Text(
            check.matched
                ? '${check.itemId} matches ${check.matchedDetails.join('; ')}'
                : '${check.itemId} is not a match',
            key: Key('pilot_perk_${check.itemId}'),
          ),
        const SizedBox(height: 12),
        const Text('Proposals are not applied'),
        for (final proposal in board.proposals)
          Text(
            '${proposal.caseId} ${proposal.kind}: ${proposal.summary}',
            key: Key('pilot_proposal_${proposal.caseId}_${proposal.kind}'),
          ),
        for (final overlap in board.overlaps)
          Text(
            '${overlap.instanceId}: ${overlap.note}',
            key: Key('pilot_overlap_${overlap.instanceId}'),
          ),
      ],
    );
  }
}

class _ShapeSample extends StatelessWidget {
  const _ShapeSample();

  @override
  Widget build(BuildContext context) {
    final sample = syntheticDimShapeSample();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        sample.toString(),
        key: const Key('pilot_shape_sample'),
      ),
    );
  }
}

String _show(PilotText text) {
  if (!text.present) return '(absent)';
  if (text.isBlank) return '(blank)';
  return text.value;
}
