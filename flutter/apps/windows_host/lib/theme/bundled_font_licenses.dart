import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SIL OFL 1.1 texts bundled beside `assets/google_fonts/*.ttf`.
const List<(String package, String asset)> kBundledFontLicenseAssets = [
  ('Inter', 'assets/google_fonts/Inter-OFL.txt'),
  ('JetBrains Mono', 'assets/google_fonts/JetBrainsMono-OFL.txt'),
  ('Orbitron', 'assets/google_fonts/Orbitron-OFL.txt'),
];

/// Registers OFL license entries for offline bundled font faces.
///
/// Call once after [WidgetsFlutterBinding.ensureInitialized].
void registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in kBundledFontLicenseAssets) {
      final text = await rootBundle.loadString(entry.$2);
      yield LicenseEntryWithLineBreaks([entry.$1], text);
    }
  });
}
