import 'package:url_launcher/url_launcher.dart';

/// Opens the system browser to an OAuth authorize URL.
abstract class BrowserLauncher {
  Future<void> open(String url);
}

/// Production launcher using `url_launcher`.
class UrlLauncherBrowser implements BrowserLauncher {
  const UrlLauncherBrowser();

  @override
  Future<void> open(String url) async {
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
    opened.add(url);
  }
}
