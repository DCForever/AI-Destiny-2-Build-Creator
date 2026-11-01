import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/material.dart';

/// One read-only matrix row, including the Solipsism subclass flag.
class WarlockBuildRow extends StatelessWidget {
  const WarlockBuildRow({super.key, required this.entry});

  final WarlockMatrixBuild entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(_rowKey),
      title: Text(entry.name),
      subtitle: Text(_subtitle),
      trailing: entry.solipsismNotPrismatic ? const _SolipsismFlag() : null,
    );
  }

  String get _rowKey =>
      'warlock-row-${entry.exoticName}-${entry.subclassKey}-${entry.name}';

  String get _subtitle {
    final creator = entry.creator;
    final who = creator == null ? '' : ' · $creator';
    final label = warlockSubclassLabel(entry.subclassKey);
    return '${entry.exoticName} · $label$who';
  }
}

class _SolipsismFlag extends StatelessWidget {
  const _SolipsismFlag();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Text(
      'Solipsism only works with Prismatic',
      style: TextStyle(color: color),
    );
  }
}
