/// Official Destiny icon paths + tints for catalog chrome.
///
/// HTML mockups use Unicode/placeholder glyphs and approximate hues because
/// they have no Bungie CDN. Production UI must prefer these official assets:
/// - Element: [DestinyDamageTypeDefinition] icons + colors
/// - Ammo: Ammo Finder family (same paths DIM/catalog web use)
/// - Weapon frames: intrinsic plug icons (DIM archetype family)
///
/// Paths are relative Bungie CDN roots (`https://www.bungie.net` + path).
library;

import 'package:flutter/material.dart';

/// Official filter/meta visual (icon path + game-UI tint).
class DestinyOfficialVisual {
  const DestinyOfficialVisual({
    required this.iconPath,
    required this.color,
  });

  /// Relative path under bungie.net (e.g. `/common/destiny2_content/icons/…`).
  final String iconPath;

  /// Official / game-UI tint for borders and washes.
  final Color color;

  /// Absolute CDN URL for [Image.network].
  String get iconUrl {
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return iconPath;
    }
    final p = iconPath.startsWith('/') ? iconPath : '/$iconPath';
    return 'https://www.bungie.net$p';
  }
}

const Color _kMuted = Color(0xFFB4B4BE);

// ---------------------------------------------------------------------------
// Element — DestinyDamageTypeDefinition.color + displayProperties.icon
// ---------------------------------------------------------------------------

/// Official damage-type visuals (keys lower-case).
const Map<String, DestinyOfficialVisual> kElementOfficial = {
  'kinetic': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_3385a924fd3ccb92c343ade19f19a370.png',
    color: Color(0xFFFFFFFF),
  ),
  'arc': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_092d066688b879c807c3b460afdd61e6.png',
    color: Color(0xFF85C5EC),
  ),
  'solar': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_2a1773e10968f2d088b97c22b22bba9e.png',
    color: Color(0xFFF2721B),
  ),
  'void': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_ceb2f6197dccf3958bb31cc783eb97a0.png',
    color: Color(0xFFB184C5),
  ),
  'stasis': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_530c4c3e7981dc2aefd24fd3293482bf.png',
    color: Color(0xFF4D88FF),
  ),
  'strand': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/DestinyDamageTypeDefinition_b2fe51a94f3533f97079dfa0d27a4096.png',
    color: Color(0xFF35E366),
  ),
  'prismatic': DestinyOfficialVisual(
    // No damage-type def; Prismatic subclass glyph is standard UI art.
    iconPath:
        '/common/destiny2_content/icons/fab506e62fa4f188bfe2fb6d56b39614.png',
    color: Color(0xFFD67EE2),
  ),
};

// ---------------------------------------------------------------------------
// Ammo — game language tints + Ammo Finder icons (DIM family)
// ---------------------------------------------------------------------------

/// Official ammo visuals (keys lower-case).
///
/// Heavy uses **purple** game chrome (same family as void) — differentiate by
/// the ammo icon shape, not an invented gold hue.
const Map<String, DestinyOfficialVisual> kAmmoOfficial = {
  'primary': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/56761c8361e33a367c6fa94f397d8692.png',
    color: Color(0xFFDCDCDC),
  ),
  'special': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/35e9d5635599be5c0fc306732f881459.png',
    color: Color(0xFF7AC143),
  ),
  'heavy': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/fdcbb78db8f38cec62ec7ca2dbab12cc.png',
    color: Color(0xFFB184C5),
  ),
};

// ---------------------------------------------------------------------------
// Weapon frames — intrinsic plug icons (DIM weapon archetype)
// ---------------------------------------------------------------------------

/// Full display-name keys as stored on catalog `frame`.
const Map<String, DestinyOfficialVisual> kWeaponFrameOfficial = {
  'Adaptive Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/967fb4abc6ab98f74639d6c08e5f56ee.png',
    color: _kMuted,
  ),
  'Aggressive Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/64209c4fd20513b33109c374179d0958.png',
    color: _kMuted,
  ),
  'Area Denial Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/d1c2cea4a7325962a493283c5615d260.png',
    color: _kMuted,
  ),
  'Caster Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/21cba9f6f6b34dced5a3cd8a6fd53c52.png',
    color: _kMuted,
  ),
  'Command Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/7e49ea5c8547243fbd5e5d8361bcacb4.png',
    color: _kMuted,
  ),
  'Compressed Wave Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/00c13147258a00b339f472516328267f.png',
    color: _kMuted,
  ),
  'High-Impact Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/34573143849cf910d2381554bb57a10d.png',
    color: _kMuted,
  ),
  'Legacy PR-55 Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/a3402f39212e2996a198d4c3882ef15d.png',
    color: _kMuted,
  ),
  'Lightweight Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/6db8cd21c2b3e6fffeb6f111d6c70dd2.png',
    color: _kMuted,
  ),
  'Micro-Missile Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/0362f949c16fe72358a5c7bb93be3f60.png',
    color: _kMuted,
  ),
  'Pinpoint Slug Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/e9dd736124e8ef94048901a279a5bb18.png',
    color: _kMuted,
  ),
  'Precision Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/e9dd736124e8ef94048901a279a5bb18.png',
    color: _kMuted,
  ),
  'Rapid-Fire Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/801d62d1f9783bee81d5700c54c24fda.png',
    color: _kMuted,
  ),
  'Support Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/922b3354dd900848ecf72bcf9e1ae022.png',
    color: _kMuted,
  ),
  'Vortex Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/23e50e126159f0f22983f73d6a246f0d.png',
    color: _kMuted,
  ),
  'Wave Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/30428876335fdd1e164128b9e5a6e4ad.png',
    color: _kMuted,
  ),
  'Wave Sword Frame': DestinyOfficialVisual(
    iconPath:
        '/common/destiny2_content/icons/a036d40aac06df275ffbb37ab370d7b7.png',
    color: _kMuted,
  ),
};

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Official element visual, or null if unknown.
DestinyOfficialVisual? officialElementVisual(String? element) {
  if (element == null || element.trim().isEmpty) return null;
  return kElementOfficial[element.trim().toLowerCase()];
}

/// Official ammo visual, or null if unknown.
DestinyOfficialVisual? officialAmmoVisual(String? ammo) {
  if (ammo == null || ammo.trim().isEmpty) return null;
  return kAmmoOfficial[ammo.trim().toLowerCase()];
}

/// Official weapon-frame visual; tolerates missing "Frame" suffix.
DestinyOfficialVisual? officialWeaponFrameVisual(String? frame) {
  if (frame == null || frame.trim().isEmpty) return null;
  final raw = frame.trim();
  final direct = kWeaponFrameOfficial[raw];
  if (direct != null) return direct;
  final withFrame = raw.toLowerCase().endsWith('frame') ? raw : '$raw Frame';
  final hit = kWeaponFrameOfficial[withFrame];
  if (hit != null) return hit;
  final key = _norm(raw);
  for (final e in kWeaponFrameOfficial.entries) {
    if (_norm(e.key) == key) return e.value;
    if (_norm(e.key.replaceAll(RegExp(r'\s*frame$', caseSensitive: false), '')) ==
        key) {
      return e.value;
    }
  }
  return null;
}

/// Prefer official element color; fall back to token palette via caller.
Color? officialElementColor(String? element) =>
    officialElementVisual(element)?.color;

/// Prefer official ammo color.
Color? officialAmmoColor(String? ammo) => officialAmmoVisual(ammo)?.color;
