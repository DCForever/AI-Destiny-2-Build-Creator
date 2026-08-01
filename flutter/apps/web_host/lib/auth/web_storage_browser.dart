/// Browser [WebStringStorage] adapters using `package:web` (DART-045).
///
/// Only imported from the client entrypoint / browser-only modules.
/// Unit tests use [MemoryWebStringStorage] instead.
library;

import 'package:web/web.dart' as web;

import 'token_store.dart';
import 'web_auth_navigator.dart';

/// `window.localStorage` adapter.
class BrowserLocalStorage implements WebStringStorage {
  @override
  String? getItem(String key) {
    final value = web.window.localStorage.getItem(key);
    return value;
  }

  @override
  void setItem(String key, String value) {
    web.window.localStorage.setItem(key, value);
  }

  @override
  void removeItem(String key) {
    web.window.localStorage.removeItem(key);
  }
}

/// `window.sessionStorage` adapter (pending PKCE).
class BrowserSessionStorage implements WebStringStorage {
  @override
  String? getItem(String key) {
    final value = web.window.sessionStorage.getItem(key);
    return value;
  }

  @override
  void setItem(String key, String value) {
    web.window.sessionStorage.setItem(key, value);
  }

  @override
  void removeItem(String key) {
    web.window.sessionStorage.removeItem(key);
  }
}

/// Production navigator using `window.location`.
class BrowserWebAuthNavigator implements WebAuthNavigator {
  @override
  Uri get currentUri => Uri.parse(web.window.location.href);

  @override
  String get origin => web.window.location.origin;

  @override
  void assign(String url) {
    web.window.location.assign(url);
  }
}
