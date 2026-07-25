import 'package:flutter/material.dart';

import '../auth/windows_oauth_session.dart';

/// Settings account card: Sign in / Sign out + membership status (DART-023).
class OAuthAccountCard extends StatelessWidget {
  const OAuthAccountCard({
    super.key,
    required this.session,
  });

  final WindowsOAuthSession session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final status = session.status;
        final membership = session.membershipId;
        final error = session.errorMessage;
        final busy = status == OAuthSessionStatus.signingIn;
        final signedIn = session.isSignedIn;
        final configured = session.isConfigured;

        return Card(
          key: const Key('oauth_account_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bungie account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusLabel(status, membership, configured),
                  key: const Key('oauth_status_text'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (signedIn && membership != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Membership: $membership',
                    key: const Key('oauth_membership_id'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                // Show whenever present (not only error status) so hangs that
                // later fail are still visible after navigation.
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error,
                        key: const Key('oauth_error_text'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                if (!configured) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Set BUNGIE_CLIENT_ID (and optional BUNGIE_REDIRECT_URI) via '
                    '--dart-define to enable sign-in. Never pass CLIENT_SECRET.',
                    key: const Key('oauth_config_hint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                // Always show redirect so operators can match Bungie app registration.
                // Do not reuse Next.js https://127.0.0.1:3000/api/auth/callback here.
                const SizedBox(height: 8),
                SelectableText(
                  'Redirect URI (must match Public Bungie app exactly):\n'
                  '${session.redirectUri}',
                  key: const Key('oauth_redirect_uri'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use a Public + PKCE Bungie application — not the Confidential '
                  'Next.js client. Register the redirect above exactly '
                  '(https://127.0.0.1:8765/callback). First browser visit may '
                  'warn about a self-signed certificate — continue to 127.0.0.1. '
                  'Do not use https://127.0.0.1:3000/api/auth/callback.',
                  key: const Key('oauth_public_app_hint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (busy) ...[
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Waiting for browser… Finish Bungie login until the '
                          'page says “Signed in”, then return here. If nothing '
                          'happens, the app is still waiting on '
                          'http://127.0.0.1:8765/callback',
                          key: Key('oauth_signing_in'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('oauth_cancel_sign_in'),
                    onPressed: () => session.cancelSignIn(),
                    child: const Text('Cancel sign-in'),
                  ),
                ] else if (signedIn)
                  OutlinedButton.icon(
                    key: const Key('oauth_sign_out'),
                    onPressed: () => session.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  )
                else
                  FilledButton.icon(
                    key: const Key('oauth_sign_in'),
                    onPressed: configured
                        ? () async {
                            await session.signIn();
                            if (!context.mounted) return;
                            final msg = session.errorMessage;
                            if (msg != null &&
                                msg.isNotEmpty &&
                                session.status == OAuthSessionStatus.error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  duration: const Duration(seconds: 12),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _statusLabel(
    OAuthSessionStatus status,
    String? membership,
    bool configured,
  ) {
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
}
