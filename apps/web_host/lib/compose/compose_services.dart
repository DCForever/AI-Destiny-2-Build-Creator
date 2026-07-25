/// Shared compose + equip/export services for the Jaspr web host (DART-046/047).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';

import '../auth/web_oauth_session.dart';
import '../builds/builds_controller.dart';
import '../dim_export/dim_export_controller.dart';
import '../equip/equip_controller.dart';
import '../sets/sets_controller.dart';
import '../synergies/synergies_controller.dart';

/// Writer-tab library + compose + equip/export controllers.
///
/// Construct only when [AppDatabase] is available (single-tab writer).
/// Equip is optional: requires [session], [profileClient], and [writeClient].
class ComposeServices {
  ComposeServices({
    required this.db,
    this.session,
    this.profileClient,
    this.writeClient,
    DimClipboardWriter? clipboardWriter,
    String Function()? loadoutIdFactory,
    bool skipSyncIfStale = true,
    Map<int, int>? equipmentBucketLookup,
    EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder,
  })  : builds = BuildsController(db: db),
        sets = SetsController(db: db),
        synergies = SynergiesController(db: db),
        dimExport = DimExportController(
          db: db,
          clipboardWriter: clipboardWriter,
          loadoutIdFactory: loadoutIdFactory,
        ),
        equip = (session != null &&
                profileClient != null &&
                writeClient != null)
            ? EquipController(
                db: db,
                session: session,
                profileClient: profileClient,
                writeClient: writeClient,
                skipSyncIfStale: skipSyncIfStale,
                equipmentBucketLookup: equipmentBucketLookup,
                equipmentBucketLookupBuilder: equipmentBucketLookupBuilder,
              )
            : null;

  final AppDatabase db;
  final BuildsController builds;
  final SetsController sets;
  final SynergiesController synergies;
  final DimExportController dimExport;

  /// Null when OAuth / profile / write clients are not wired (DIM still works).
  final EquipController? equip;

  final WebOAuthSession? session;
  final BungieProfileClient? profileClient;
  final BungieWriteClient? writeClient;

  /// Dispose controllers if they grow resources later.
  void dispose() {
    // ChangeNotifier has no dispose requirement in jaspr base; reserved.
  }
}
