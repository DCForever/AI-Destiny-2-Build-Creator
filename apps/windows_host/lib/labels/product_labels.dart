import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/material.dart';

/// Human labels for wire tokens in library UI (BUG-20260726-010).
String displaySynergyTypeWire(String wire) {
  if (wire.isEmpty) return wire;
  return wire
      .split('_')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

String displaySetType(SetType type) {
  switch (type) {
    case SetType.weapon:
      return 'Weapon';
    case SetType.armor:
      return 'Armor';
    case SetType.mod:
      return 'Mod';
    case SetType.pair:
      return 'Pair';
    case SetType.fashion:
      return 'Fashion';
  }
}

String displaySetTypeWire(String wire) {
  final t = SetType.tryParse(wire);
  return t != null ? displaySetType(t) : displaySynergyTypeWire(wire);
}

String displayGuardianClass(GuardianClass value) {
  switch (value) {
    case GuardianClass.hunter:
      return 'Hunter';
    case GuardianClass.titan:
      return 'Titan';
    case GuardianClass.warlock:
      return 'Warlock';
  }
}

/// Shared empty-detail body for dual-pane libraries (BUG-20260726-011).
class LibraryDetailEmpty extends StatelessWidget {
  const LibraryDetailEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
