/// Entity store reader + MVP extractors + Windows manifest refresh + offline catalog.
///
/// Pure Dart I/O via [StorageRoot]. Download + Settings API in DART-018.
/// Offline catalog facets/browse in DART-020 (no inventory).
/// No Node sidecar; no CLIENT_SECRET (public API key host-injected only).
library;

export 'src/adapters/hard_constraints_adapters.dart';
export 'src/adapters/mod_energy.dart';
export 'src/catalog/catalog_item.dart';
export 'src/catalog/catalog_projector.dart';
export 'src/catalog/facet_filter.dart';
export 'src/catalog/filter_catalog.dart';
export 'src/catalog/filter_options.dart';
export 'src/catalog/offline_catalog.dart';
export 'src/catalog/owned_catalog.dart';
export 'src/entity_cache.dart';
export 'src/extractors/abilities.dart';
export 'src/extractors/aspects.dart';
export 'src/extractors/exotic_armor.dart';
export 'src/extractors/fragments.dart';
export 'src/extractors/mods.dart';
export 'src/extractors/registry.dart';
export 'src/extractors/weapons.dart';
export 'src/http_client.dart';
export 'src/isolate_rebuild.dart';
export 'src/item_resolver.dart';
export 'src/manifest_refresh.dart';
export 'src/manifest_service.dart';
export 'src/normalize.dart';
export 'src/perk_validator.dart';
export 'src/types/records.dart';
export 'src/types/services.dart';
export 'src/types/stores.dart';
