/// Sanitizes a Bungie manifest version string for use as a single path segment.
///
/// Parity with product `versionToDirName` in `src/lib/manifest/cachePaths.ts`:
/// replace any run of characters outside `[A-Za-z0-9._-]` with `_`.
String versionToDirName(String version) {
  return version.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
}
