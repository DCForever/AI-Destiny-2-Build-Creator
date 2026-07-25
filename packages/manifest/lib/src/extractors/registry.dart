import '../types/services.dart';
import 'abilities.dart';
import 'aspects.dart';
import 'exotic_armor.dart';
import 'fragments.dart';
import 'mods.dart';
import 'weapons.dart';

/// Ordered registry of MVP entity extractors (DART-017).
final List<EntityExtractor> mvpExtractors = [
  ExoticArmorExtractor(),
  WeaponsExtractor(),
  AspectsExtractor(),
  FragmentsExtractor(),
  AbilitiesExtractor(),
  ModsExtractor(),
];
