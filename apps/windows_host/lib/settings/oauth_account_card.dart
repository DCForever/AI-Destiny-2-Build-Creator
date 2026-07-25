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
                if (error != null && status == OAuthSessionStatus.error) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    key: const Key('oauth_error_text'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
                const SizedBox(height: 12),
                if (busy)
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Waiting for browser sign-in…',
                        key: Key('oauth_signing_in'),
                      ),
                    ],
                  )
                else if (signedIn)
                  OutlinedButton.icon(
                    key: const Key('oauth_sign_out'),
                    onPressed: () => session.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  )
                else
                  FilledButton.icon(
                    key: const Key('oauth_sign_in'),
                    onPressed: configured ? () => session.signIn() : null,
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
