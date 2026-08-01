/// OAuth callback route handler (DART-045).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';
import '../theme/theme.dart';

/// Completes Public+PKCE exchange after Bungie redirects to `/auth/callback`.
class AuthCallbackPage extends StatefulComponent {
  const AuthCallbackPage({
    this.session,
    super.key,
  });

  final WebOAuthSession? session;

  static const String titleText = 'Signing in…';
  static const String waitingText =
      'Completing Bungie sign-in. You will return to Settings shortly.';
  static const String missingSessionText =
      'OAuth session is not available. Return to Settings and try again.';

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  String? _message;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    final session = component.session;
    if (session == null) {
      _message = AuthCallbackPage.missingSessionText;
      return;
    }
    unawaited(
      session.completeCallback().then((_) {
        if (mounted && session.status == OAuthSessionStatus.error) {
          setState(() {
            _message = session.errorMessage ?? 'Sign-in failed';
          });
        }
      }),
    );
  }

  @override
  Component build(BuildContext context) {
    final err = _message;
    return section(
      classes: 'auth-callback-page',
      attributes: {'data-page': 'auth-callback', 'data-testid': 'auth-callback'},
      [
        h1([.text(AuthCallbackPage.titleText)]),
        p(
          attributes: {'data-testid': 'auth-callback-status'},
          [
            .text(err ?? AuthCallbackPage.waitingText),
          ],
        ),
        if (err != null)
          p([
            a(
              href: '/settings',
              attributes: {'data-testid': 'auth-callback-back'},
              [.text('Back to Settings')],
            ),
          ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
        css('.auth-callback-page', [
          css('&').styles(
            display: .flex,
            width: 100.percent,
            maxWidth: 40.rem,
            padding: .symmetric(horizontal: 1.25.rem, vertical: 1.5.rem),
            flexDirection: .column,
            gap: Gap(row: 0.75.rem),
          ),
          css('p').styles(
            color: flapForegroundColor,
            lineHeight: 1.5.em,
          ),
          css('a').styles(
            color: flapAccentColor,
            fontWeight: .w600,
          ),
        ]),
      ];
}
