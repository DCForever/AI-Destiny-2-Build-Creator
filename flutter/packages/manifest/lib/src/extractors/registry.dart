import '../types/services.dart';
import 'abilities.dart';
import 'aspects.dart';
import 'exotic_armor.dart';
import 'exotic_weapons.dart';
import 'fragments.dart';
import 'legendary_armor.dart';
import 'mods.dart';
import 'weapons.dart';

/// Ordered registry of MVP entity extractors (DART-017 / DART-062).
final List<EntityExtractor> mvpExtractors = [
  ExoticArmorExtractor(),
  LegendaryArmorExtractor(),
  ExoticWeaponsExtractor(),
  WeaponsExtractor(),
  AspectsExtractor(),
  FragmentsExtractor(),
  AbilitiesExtractor(),
  ModsExtractor(),
];
