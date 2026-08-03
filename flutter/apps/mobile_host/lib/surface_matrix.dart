/// Published mobile AppShell surface matrix (DART-057 / GAP-MOB-01).
///
/// Status vocabulary matches cutover/feature-gap language:
/// PASS / PARTIAL / MISS / N/A (+ deferred for intentional later work).
///
/// **UX rebuild baseline (2026-08):** bottom nav is **Settings only**. Other
/// product areas are deferred until rebuilt via the area UX redesign loop.
library;

/// Matrix status for one mobile surface.
enum MobileSurfaceStatus {
  pass('PASS'),
  partial('PARTIAL'),
  miss('MISS'),
  na('N/A'),
  deferred('deferred');

  const MobileSurfaceStatus(this.label);
  final String label;
}

/// One AppShell / compose→equip surface on mobile.
class MobileSurfaceEntry {
  const MobileSurfaceEntry({
    required this.key,
    required this.status,
    required this.note,
    this.bottomNav = false,
  });

  /// Stable matrix key (build, synergy, sets, catalog, settings, loadouts,
  /// equip, dim, optimizer).
  final String key;

  final MobileSurfaceStatus status;
  final String note;

  /// Whether this surface is a bottom-nav destination.
  final bool bottomNav;
}

/// Canonical mobile surface matrix during Settings-only UX rebuild baseline.
const List<MobileSurfaceEntry> kMobileSurfaceMatrix = [
  MobileSurfaceEntry(
    key: 'build',
    status: MobileSurfaceStatus.deferred,
    note: 'Stripped for UX rebuild; returns via area-ux-redesign',
  ),
  MobileSurfaceEntry(
    key: 'synergy',
    status: MobileSurfaceStatus.deferred,
    note: 'No top-level nav until area rebuild',
  ),
  MobileSurfaceEntry(
    key: 'sets',
    status: MobileSurfaceStatus.deferred,
    note: 'No top-level nav until area rebuild',
  ),
  MobileSurfaceEntry(
    key: 'catalog',
    status: MobileSurfaceStatus.deferred,
    note: 'Next area after Settings baseline (weapons slice first)',
  ),
  MobileSurfaceEntry(
    key: 'settings',
    status: MobileSurfaceStatus.partial,
    note:
        'Only product surface during UX rebuild baseline (full body; bottom nav returns when second area lands)',
    bottomNav: true,
  ),
  MobileSurfaceEntry(
    key: 'loadouts',
    status: MobileSurfaceStatus.deferred,
    note: 'Windows-first historically; mobile deferred until rebuild',
  ),
  MobileSurfaceEntry(
    key: 'equip',
    status: MobileSurfaceStatus.na,
    note: 'Requires OAuth + write clients + equip-ready pins — use Windows/Jaspr',
  ),
  MobileSurfaceEntry(
    key: 'dim',
    status: MobileSurfaceStatus.na,
    note: 'DIM jsonOnly needs equip-ready owned pins; path is Windows/Jaspr',
  ),
  MobileSurfaceEntry(
    key: 'optimizer',
    status: MobileSurfaceStatus.deferred,
    note: 'GAP-FEAT-01 Windows-only unless product elevates',
  ),
];

/// Bottom-nav destination keys that MUST match [kMobileSurfaceMatrix] rows
/// with [MobileSurfaceEntry.bottomNav] == true (Settings only during baseline).
const List<String> kMobileBottomNavKeys = ['settings'];

/// Matrix keys required by exit criteria (AppShell + equip/DIM/optimizer).
const List<String> kMobileMatrixRequiredKeys = [
  'build',
  'synergy',
  'sets',
  'catalog',
  'settings',
  'loadouts',
  'equip',
  'dim',
  'optimizer',
];

MobileSurfaceEntry? mobileSurfaceByKey(String key) {
  for (final e in kMobileSurfaceMatrix) {
    if (e.key == key) return e;
  }
  return null;
}

/// Nav labels shown in the shell (paired with [kMobileBottomNavKeys]).
const List<String> kMobileBottomNavLabels = ['Settings'];
