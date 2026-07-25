/// Shared compose spine services for the Jaspr web host (DART-046).
library;

import 'package:destiny2_db/destiny2_db.dart';

import '../builds/builds_controller.dart';
import '../sets/sets_controller.dart';
import '../synergies/synergies_controller.dart';

/// Writer-tab library + compose controllers.
///
/// Construct only when [AppDatabase] is available (single-tab writer).
class ComposeServices {
  ComposeServices({required this.db})
      : builds = BuildsController(db: db),
        sets = SetsController(db: db),
        synergies = SynergiesController(db: db);

  final AppDatabase db;
  final BuildsController builds;
  final SetsController sets;
  final SynergiesController synergies;

  /// Dispose controllers if they grow resources later.
  void dispose() {
    // ChangeNotifier has no dispose requirement in jaspr base; reserved.
  }
}
