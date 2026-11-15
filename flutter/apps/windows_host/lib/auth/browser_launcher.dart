import 'package:url_launcher/url_launcher.dart';

/// Fixed copy when the authorize URL is not an allowlisted Bungie URL.
const String kUnsafeAuthorizeUrlMessage =
    'Sign-in link is not valid - please try again.';

/// True only for `https://www.bungie.net/…` with no userinfo and no explicit port.
///
/// **Port policy:** any explicit port after the host is refused — including
/// `:443`. Dart normalizes `Uri.hasPort` / `authority` so default HTTPS `:443`
/// disappears from the parsed URI; we therefore also inspect the raw string
/// for `host:` immediately after the host. Default HTTPS without a port
/// (`https://www.bungie.net/…`) is allowed.
///
/// Refuses `https://www.bungie.net@evil.example/…` (userinfo + wrong host) and
/// any non-https scheme or non-`www.bungie.net` host.
bool isAllowedBungieAuthorizeUrl(String url) {
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (uri.scheme.toLowerCase() != 'https') return false;
  if (uri.host.toLowerCase() != 'www.bungie.net') return false;
  if (uri.userInfo.isNotEmpty) return false;
  if (uri.hasPort) return false;
  // Dart drops default :443 from authority — detect `host:` in the raw URL.
  final host = uri.host;
  final hostIdx = trimmed.toLowerCase().indexOf(host.toLowerCase());
  if (hostIdx < 0) return false;
  final afterHost = trimmed.substring(hostIdx + host.length);
  if (afterHost.startsWith(':')) return false;
  return true;
}

/// Opens the system browser to an OAuth authorize URL.
abstract class BrowserLauncher {
  Future<void> open(String url);
}

/// Production launcher using `url_launcher`.
class UrlLauncherBrowser implements BrowserLauncher {
  const UrlLauncherBrowser();

  @override
  Future<void> open(String url) async {
    if (!isAllowedBungieAuthorizeUrl(url)) {
      throw StateError(kUnsafeAuthorizeUrlMessage);
    }
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw StateError('Could not open browser for OAuth authorize URL');
    }
  }
}

/// Test double that records opened URLs.
class FakeBrowserLauncher implements BrowserLauncher {
  final List<String> opened = <String>[];

  @override
  Future<void> open(String url) async {
    if (!isAllowedBungieAuthorizeUrl(url)) {
      throw StateError(kUnsafeAuthorizeUrlMessage);
    }
    opened.add(url);
  }
}
