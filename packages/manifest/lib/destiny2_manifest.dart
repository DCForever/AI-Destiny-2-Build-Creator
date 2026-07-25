/// Entity store reader + MVP extractors + hard-constraint adapters (DART-017).
///
/// Pure Dart I/O via [StorageRoot]. No network download (DART-018), no secrets.
library;

export 'src/adapters/hard_constraints_adapters.dart';
export 'src/adapters/mod_energy.dart';
export 'src/entity_cache.dart';
export 'src/extractors/abilities.dart';
export 'src/extractors/aspects.dart';
export 'src/extractors/exotic_armor.dart';
export 'src/extractors/fragments.dart';
export 'src/extractors/mods.dart';
export 'src/extractors/registry.dart';
export 'src/extractors/weapons.dart';
export 'src/item_resolver.dart';
export 'src/normalize.dart';
export 'src/perk_validator.dart';
export 'src/types/records.dart';
export 'src/types/services.dart';
export 'src/types/stores.dart';
