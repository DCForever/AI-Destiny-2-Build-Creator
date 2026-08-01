/// Settings Bungie account card (DART-045 Public+PKCE).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';
import '../theme/theme.dart';

/// Sign in / Sign out + membership status for Settings.
class OAuthAccountCard extends StatefulComponent {
  const OAuthAccountCard({
    required this.session,
    super.key,
  });

  final WebOAuthSession session;

  @override
  State<OAuthAccountCard> createState() => _OAuthAccountCardState();
}

class _OAuthAccountCardState extends State<OAuthAccountCard> {
  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    component.session.addListener(_onSession);
  }

  @override
  void didUpdateComponent(covariant OAuthAccountCard oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.session != component.session) {
      oldComponent.session.removeListener(_onSession);
      component.session.addListener(_onSession);
    }
  }

  @override
  void dispose() {
    component.session.removeListener(_onSession);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final session = component.session;
    final status = session.status;
    final membership = session.membershipId;
    final error = session.errorMessage;
    final busy = status == OAuthSessionStatus.signingIn;
    final signedIn = session.isSignedIn;
    final configured = session.isConfigured;

    return div(
      classes: 'oauth-card',
      attributes: {'data-testid': 'oauth-account-card'},
      [
        h2([.text('Bungie account')]),
        p(
          classes: 'oauth-status',
          attributes: {'data-testid': 'oauth-status-text'},
          [.text(_statusLabel(status, configured))],
        ),
        if (signedIn && membership != null)
          p(
            classes: 'oauth-membership',
            attributes: {'data-testid': 'oauth-membership-id'},
            [.text('Membership: $membership')],
          ),
        if (error != null && status == OAuthSessionStatus.error)
          p(
            classes: 'oauth-error',
            attributes: {'data-testid': 'oauth-error-text'},
            [.text(error)],
          ),
        if (!configured)
          p(
            classes: 'oauth-hint',
            attributes: {'data-testid': 'oauth-config-hint'},
            [
              .text(
                'Set BUNGIE_CLIENT_ID (and optional BUNGIE_REDIRECT_URI) via '
                '--dart-define to enable sign-in. Never pass CLIENT_SECRET.',
              ),
            ],
          ),
        div(classes: 'oauth-actions', [
          if (busy)
            p(
              attributes: {'data-testid': 'oauth-signing-in'},
              [.text('Waiting for browser sign-in…')],
            )
          else if (signedIn)
            button(
              classes: 'oauth-btn oauth-btn-out',
              attributes: {'data-testid': 'oauth-sign-out', 'type': 'button'},
              events: {
                'click': (event) {
                  session.signOut();
                },
              },
              [.text('Sign out')],
            )
          else
            button(
              classes: 'oauth-btn oauth-btn-in',
              attributes: {
                'data-testid': 'oauth-sign-in',
                'type': 'button',
                if (!configured) 'disabled': 'true',
              },
              events: {
                'click': (event) {
                  if (configured) session.signIn();
                },
              },
              [.text('Sign in')],
            ),
        ]),
      ],
    );
  }

  static String _statusLabel(OAuthSessionStatus status, bool configured) {
    switch (status) {
      case OAuthSessionStatus.signedIn:
        return 'Signed in';
      case OAuthSessionStatus.signingIn:
        return 'Signing in…';
      case OAuthSessionStatus.error:
        return 'Sign-in error';
      case OAuthSessionStatus.signedOut:
        return configured ? 'Signed out' : 'Not configured';
    }
  }

  @css
  static List<StyleRule> get styles => [
        css('.oauth-card', [
          css('&').styles(
            width: 100.percent,
            margin: .only(top: 1.rem),
            padding: .all(1.rem),
            border: .only(top: .solid(color: flapLineColor, width: 1.px)),
            backgroundColor: flapSurfaceColor,
          ),
          css('h2').styles(
            margin: .only(bottom: 0.5.rem),
            fontSize: 0.85.rem,
            fontWeight: .w600,
            letterSpacing: 0.06.em,
            color: flapMutedColor,
            textTransform: .upperCase,
          ),
          css('.oauth-status').styles(
            margin: .only(bottom: 0.35.rem),
            color: flapForegroundColor,
            fontSize: 0.95.rem,
          ),
          css('.oauth-membership').styles(
            margin: .only(bottom: 0.35.rem),
            color: flapMutedColor,
            fontSize: 0.9.rem,
          ),
          css('.oauth-error').styles(
            margin: .only(bottom: 0.5.rem),
            color: Color('#c45c26'),
            fontSize: 0.9.rem,
          ),
          css('.oauth-hint').styles(
            margin: .only(bottom: 0.5.rem),
            color: flapMutedColor,
            fontSize: 0.85.rem,
            lineHeight: 1.4.em,
          ),
          css('.oauth-actions').styles(
            margin: .only(top: 0.5.rem),
          ),
          css('.oauth-btn').styles(
            padding: .symmetric(horizontal: 0.9.rem, vertical: 0.45.rem),
            border: .all(style: .solid, color: flapLineColor, width: 1.px),
            radius: .all(.circular(0.px)),
            color: flapForegroundColor,
            fontWeight: .w600,
            fontSize: 0.9.rem,
            backgroundColor: flapBackgroundColor,
            cursor: Cursor.pointer,
          ),
          css('.oauth-btn-in').styles(
            border: .all(style: .solid, color: flapAccentColor, width: 1.px),
            color: flapBackgroundColor,
            backgroundColor: flapAccentColor,
          ),
          css('.oauth-btn:disabled').styles(
            opacity: 0.5,
            cursor: Cursor.notAllowed,
          ),
        ]),
      ];
}
