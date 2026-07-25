/// Published mobile AppShell surface matrix (DART-057 / GAP-MOB-01).
///
/// Status vocabulary matches cutover/feature-gap language:
/// PASS / PARTIAL / MISS / N/A (+ deferred for intentional later work).
///
/// Product defaults (research A1): phone bottom nav stays Builds | Settings.
/// Equip/catalog/DIM require OAuth + inventory sync not present on mobile → N/A
/// (not silent MISS). Optimizer remains deferred (GAP-FEAT-01).
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

/// Canonical mobile surface matrix (DART-057).
const List<MobileSurfaceEntry> kMobileSurfaceMatrix = [
  MobileSurfaceEntry(
    key: 'build',
    status: MobileSurfaceStatus.pass,
    note: 'List + linear compose (variants, attach, pins, soft stats)',
    bottomNav: true,
  ),
  MobileSurfaceEntry(
    key: 'synergy',
    status: MobileSurfaceStatus.na,
    note: 'No top-level nav; create-build designates synergy types',
  ),
  MobileSurfaceEntry(
    key: 'sets',
    status: MobileSurfaceStatus.na,
    note: 'No top-level nav; compose attach sheet reaches set attach',
  ),
  MobileSurfaceEntry(
    key: 'catalog',
    status: MobileSurfaceStatus.na,
    note: 'Phone density; catalog browse on Windows/Jaspr (needs entity + sync)',
  ),
  MobileSurfaceEntry(
    key: 'settings',
    status: MobileSurfaceStatus.partial,
    note: 'Storage/DB path + manifest + surface matrix; OAuth/sync deferred',
    bottomNav: true,
  ),
  MobileSurfaceEntry(
    key: 'loadouts',
    status: MobileSurfaceStatus.na,
    note: 'Windows/Jaspr first (DART-055); phone top-level deferred',
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
/// with [MobileSurfaceEntry.bottomNav] == true (order: Builds, Settings).
const List<String> kMobileBottomNavKeys = ['build', 'settings'];

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
const List<String> kMobileBottomNavLabels = ['Builds', 'Settings'];
