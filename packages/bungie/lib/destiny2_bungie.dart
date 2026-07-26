/// Shared Bungie Platform HTTP client + Public+PKCE OAuth + profile sync
/// (DART-021/022/024) + equip write client / best-effort orchestrator
/// (DART-037) + character list for equip UI (DART-038).
///
/// Public API key and public client id only — hosts inject credentials.
/// No `CLIENT_SECRET` / `client_secret` fields.
library;

export 'src/bungie_envelope.dart';
export 'src/bungie_errors.dart';
export 'src/bungie_http_client.dart';
export 'src/http_transport.dart';
export 'src/rate_limit.dart';
export 'src/oauth/bungie_oauth_client.dart';
export 'src/oauth/bungie_tokens.dart';
export 'src/oauth/oauth_errors.dart';
export 'src/oauth/oauth_pending.dart';
export 'src/oauth/oauth_state.dart';
export 'src/oauth/pkce.dart';
export 'src/oauth/redirect_uri_config.dart';
export 'src/oauth/prod_public_oauth_matrix.dart';

export 'src/inventory/build_stored_socket_plugs.dart';
export 'src/inventory/classify_weapon_socket.dart';
export 'src/inventory/roll_tag_lookups.dart';
export 'src/inventory/roll_tags.dart';
export 'src/inventory/weapon_socket_context.dart';
export 'src/profile/bungie_profile_client.dart';
export 'src/profile/character_loadouts.dart';
export 'src/profile/character_parse.dart';
export 'src/profile/equipment_bucket_lookup.dart';
export 'src/profile/inventory_buckets.dart';
export 'src/profile/inventory_parse.dart';
export 'src/profile/loadout_exotics.dart';
export 'src/profile/profile_types.dart';
export 'src/sync/format_last_sync.dart';
export 'src/sync/format_sync_diagnostics.dart';
export 'src/sync/sync_freshness.dart';
export 'src/sync/sync_inventory.dart';

export 'src/write/write_client.dart';
export 'src/write/equip_orchestrator.dart';

