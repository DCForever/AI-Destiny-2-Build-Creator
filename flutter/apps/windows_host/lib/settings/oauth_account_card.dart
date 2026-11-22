import 'package:flutter/material.dart';

import '../auth/windows_oauth_session.dart';

/// Settings account card: Sign in / Sign out + membership status (DART-023).
class OAuthAccountCard extends StatefulWidget {
  const OAuthAccountCard({
    super.key,
    required this.session,
  });

  final WindowsOAuthSession session;

  @override
  State<OAuthAccountCard> createState() => _OAuthAccountCardState();
}

class _OAuthAccountCardState extends State<OAuthAccountCard> {
  /// Operator / developer redirect docs stay collapsed (BUG-20260726-012).
  bool _advancedOpen = false;
  final TextEditingController _credentialController = TextEditingController();
  bool _savingCredential = false;

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final status = session.status;
        final membership = session.membershipId;
        final error = session.errorMessage;
        final busy = status == OAuthSessionStatus.signingIn;
        final signedIn = session.isSignedIn;
        final configured = session.isConfigured;
        final confidential = session.isConfidentialMode;

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
                Text(
                  confidential
                      ? 'Confidential mode: on'
                      : 'Confidential mode: off',
                  key: const Key('oauth_confidential_mode'),
                  style: Theme.of(context).textTheme.bodySmall,
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
                ] else if (!signedIn && !busy) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sign in with Bungie to sync inventory and loadouts.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
                          'https://127.0.0.1:8765/callback',
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
                // Operator redirect / Public-app notes — not primary player UI.
                ListTile(
                  key: const Key('oauth_advanced_toggle'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    _advancedOpen
                        ? 'Hide developer details'
                        : 'Developer / redirect details',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  trailing: Icon(
                    _advancedOpen ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() => _advancedOpen = !_advancedOpen);
                  },
                ),
                if (_advancedOpen) ...[
                  SelectableText(
                    'Redirect URI (must match Bungie app exactly):\n'
                    '${session.redirectUri}',
                    key: const Key('oauth_redirect_uri'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Default: Public + PKCE. Optional: paste a Confidential '
                    'desktop app credential below (Windows Credential Manager '
                    'only — never dart-define). Register redirect '
                    'https://127.0.0.1:8765/callback. See '
                    'docs/flutter-confidential-desktop-oauth-note.md.',
                    key: const Key('oauth_public_app_hint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('oauth_client_credential_field'),
                    controller: _credentialController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Confidential app credential (optional)',
                      hintText: 'Paste once — stored in Credential Manager',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        key: const Key('oauth_save_client_credential'),
                        onPressed: _savingCredential
                            ? null
                            : () async {
                                setState(() => _savingCredential = true);
                                final raw = _credentialController.text;
                                _credentialController.clear();
                                try {
                                  await session.saveClientCredential(raw);
                                } finally {
                                  if (mounted) {
                                    setState(() => _savingCredential = false);
                                  }
                                }
                              },
                        child: const Text('Save credential'),
                      ),
                      OutlinedButton(
                        key: const Key('oauth_forget_client_credential'),
                        onPressed: () async {
                          _credentialController.clear();
                          await session.forgetClientCredential();
                        },
                        child: const Text('Forget client secret'),
                      ),
                    ],
                  ),
                  if (session.promptForgetCredential) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bungie returned invalid_client — use Forget client secret, '
                      'then paste a rotated credential.',
                      key: const Key('oauth_forget_credential_prompt'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
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
