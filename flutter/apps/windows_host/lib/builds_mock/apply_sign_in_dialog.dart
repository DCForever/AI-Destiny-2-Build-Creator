import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/browser_launcher.dart';
import '../auth/windows_oauth_session.dart';

/// Fixed Apply-gate sign-in copy (never echo raw exception text).
const String kApplySignInTitle = 'Sign in to Bungie';

const String kApplySignInBody =
    'Apply needs your permission to equip items. '
    "Bungie's sign-in opens in your browser.";

const String kApplySignInOpenButton = 'Open Bungie sign-in';

const String kApplySignInWaitingBody = 'Finish signing in in your browser...';

const String kApplySignInCopyLink = "Didn't open? Copy link";

const String kApplySignInPermissionsHeading = 'PERMISSIONS';

/// Matches the Public+PKCE scopes actually requested (scopes unchanged).
const List<String> kApplySignInPermissions = <String>[
  'Read profile',
  'Read inventory and vault',
  'Move and equip items',
];

const String kApplySignInCancelledMessage = 'Sign-in was cancelled.';

const String kApplySignInTimeoutMessage =
    'Sign-in took too long - try again.';

const String kApplySignInStateMismatchMessage =
    'Security check failed - please try again.';

const String kApplySignInNetworkMessage =
    "Couldn't reach Bungie - check your connection.";

const String kApplySignInExchangeMessage =
    'Could not complete sign-in with Bungie. Please try again.';

const String kApplySignInUnknownMessage =
    'Sign-in failed - please try again.';

const String kApplySignInMissingCodeMessage =
    "Bungie didn't send a sign-in code - try again.";

const String kApplySignInUnsafeUrlMessage = kUnsafeAuthorizeUrlMessage;

const Duration kApplySignInSuccessContinueDelay = Duration(seconds: 1);

/// Maps typed OAuth failures to the Apply dialog's fixed messages.
String applySignInDialogErrorMessage(OAuthSignInFailureKind? kind) {
  return switch (kind) {
    OAuthSignInFailureKind.cancelled => kApplySignInCancelledMessage,
    OAuthSignInFailureKind.callbackTimeout => kApplySignInTimeoutMessage,
    OAuthSignInFailureKind.stateMismatch => kApplySignInStateMismatchMessage,
    OAuthSignInFailureKind.missingAuthorizationCode =>
      kApplySignInMissingCodeMessage,
    OAuthSignInFailureKind.networkUnreachable => kApplySignInNetworkMessage,
    OAuthSignInFailureKind.tokenExchangeFailed => kApplySignInExchangeMessage,
    OAuthSignInFailureKind.unsafeAuthorizeUrl => kApplySignInUnsafeUrlMessage,
    null => kApplySignInUnknownMessage,
  };
}

/// Clipboard writer injectable for tests (never write tokens).
typedef ApplySignInClipboardWriter = Future<void> Function(String text);

Future<void> defaultApplySignInClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Result of the Apply sign-in dialog.
enum ApplySignInDialogResult {
  /// User signed in successfully; caller should continue Apply.
  signedIn,

  /// User cancelled from prompt or waiting, or dismissed the barrier.
  cancelled,
}

/// Shows the Apply-gate Bungie sign-in dialog (system browser / PKCE).
///
/// Returns [ApplySignInDialogResult.signedIn] only after success + delay.
Future<ApplySignInDialogResult> showApplySignInDialog({
  required BuildContext context,
  required WindowsOAuthSession session,
  ApplySignInClipboardWriter? clipboardWriter,
  Duration successContinueDelay = kApplySignInSuccessContinueDelay,
  String? bungieDisplayName,
}) async {
  final result = await showDialog<ApplySignInDialogResult>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return ApplySignInDialog(
        session: session,
        clipboardWriter:
            clipboardWriter ?? defaultApplySignInClipboardWriter,
        successContinueDelay: successContinueDelay,
        bungieDisplayName: bungieDisplayName,
      );
    },
  );
  return result ?? ApplySignInDialogResult.cancelled;
}

/// Modal dialog: prompt → waiting → success / fixed errors.
class ApplySignInDialog extends StatefulWidget {
  const ApplySignInDialog({
    super.key,
    required this.session,
    this.clipboardWriter = defaultApplySignInClipboardWriter,
    this.successContinueDelay = kApplySignInSuccessContinueDelay,
    this.bungieDisplayName,
  });

  final WindowsOAuthSession session;
  final ApplySignInClipboardWriter clipboardWriter;
  final Duration successContinueDelay;

  /// Optional display name for success ("Signed in as …").
  /// Falls back to membership id when null/empty.
  final String? bungieDisplayName;

  @override
  State<ApplySignInDialog> createState() => _ApplySignInDialogState();
}

enum _ApplySignInPhase { prompt, waiting, success, error }

class _ApplySignInDialogState extends State<ApplySignInDialog> {
  _ApplySignInPhase _phase = _ApplySignInPhase.prompt;
  OAuthSignInFailureKind? _errorKind;
  String? _copiedHint;
  bool _continuing = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    // Escape / barrier / route dispose while waiting — abort in-flight sign-in.
    if (!_closed && _phase == _ApplySignInPhase.waiting) {
      unawaited(widget.session.cancelSignIn());
    }
    super.dispose();
  }

  void _onDismissedWithoutResult() {
    if (_closed) return;
    _closed = true;
    if (_phase == _ApplySignInPhase.waiting) {
      unawaited(widget.session.cancelSignIn());
    }
  }

  void _pop(ApplySignInDialogResult result) {
    if (_closed || !mounted) return;
    _closed = true;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    nav.pop(result);
  }

  void _onSession() {
    if (!mounted || _closed) return;
    final session = widget.session;
    if (_phase == _ApplySignInPhase.waiting) {
      if (session.isSignedIn) {
        setState(() => _phase = _ApplySignInPhase.success);
        _scheduleContinue();
        return;
      }
      if (session.status == OAuthSessionStatus.error) {
        setState(() {
          _phase = _ApplySignInPhase.error;
          _errorKind = session.lastSignInFailureKind;
        });
        return;
      }
      // Cancel from waiting — [_onCancelWaiting] owns the pop.
    }
    // Rebuild for pendingAuthorizeUrl while waiting.
    if (_phase == _ApplySignInPhase.waiting) {
      setState(() {});
    }
  }

  void _scheduleContinue() {
    if (_continuing || _closed) return;
    _continuing = true;
    Future<void>.delayed(widget.successContinueDelay, () {
      _pop(ApplySignInDialogResult.signedIn);
    });
  }

  Future<void> _onOpenSignIn() async {
    setState(() {
      _phase = _ApplySignInPhase.waiting;
      _errorKind = null;
      _copiedHint = null;
    });
    await widget.session.signIn();
    if (!mounted || _closed) return;
    // Listener may have already moved us; cover races where notify was missed.
    final session = widget.session;
    if (session.isSignedIn && _phase == _ApplySignInPhase.waiting) {
      setState(() => _phase = _ApplySignInPhase.success);
      _scheduleContinue();
    } else if (session.status == OAuthSessionStatus.error &&
        _phase == _ApplySignInPhase.waiting) {
      setState(() {
        _phase = _ApplySignInPhase.error;
        _errorKind = session.lastSignInFailureKind;
      });
    }
    // User cancel while waiting: [_onCancelWaiting] already popped.
  }

  Future<void> _onCancelWaiting() async {
    if (_closed) return;
    await widget.session.cancelSignIn();
    _pop(ApplySignInDialogResult.cancelled);
  }

  void _onCancelPrompt() {
    _pop(ApplySignInDialogResult.cancelled);
  }

  void _onTryAgain() {
    setState(() {
      _phase = _ApplySignInPhase.prompt;
      _errorKind = null;
      _copiedHint = null;
    });
  }

  Future<void> _onCopyLink() async {
    final url = widget.session.pendingAuthorizeUrl;
    if (url == null || url.isEmpty) return;
    if (!isAllowedBungieAuthorizeUrl(url)) {
      if (!mounted) return;
      setState(() => _copiedHint = kApplySignInUnsafeUrlMessage);
      return;
    }
    await widget.clipboardWriter(url);
    if (!mounted) return;
    setState(() => _copiedHint = 'Link copied');
  }

  String get _successName {
    final injected = widget.bungieDisplayName?.trim();
    if (injected != null && injected.isNotEmpty) return injected;
    final id = widget.session.membershipId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return 'Guardian';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        // Barrier / Escape / system back — cancel in-flight sign-in.
        _onDismissedWithoutResult();
      },
      child: Dialog(
        key: const Key('apply_sign_in_dialog'),
        backgroundColor: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: switch (_phase) {
              _ApplySignInPhase.prompt => _buildPrompt(theme),
              _ApplySignInPhase.waiting => _buildWaiting(theme),
              _ApplySignInPhase.success => _buildSuccess(theme),
              _ApplySignInPhase.error => _buildError(theme),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt(ThemeData theme) {
    return Column(
      key: const Key('apply_sign_in_prompt'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kApplySignInTitle,
          key: const Key('apply_sign_in_title'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          kApplySignInBody,
          key: const Key('apply_sign_in_body'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          kApplySignInPermissionsHeading,
          key: const Key('apply_sign_in_permissions_heading'),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        for (final permission in kApplySignInPermissions)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '· $permission',
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('apply_sign_in_cancel'),
              onPressed: _onCancelPrompt,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('apply_sign_in_open'),
              onPressed: _onOpenSignIn,
              child: const Text(kApplySignInOpenButton),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaiting(ThemeData theme) {
    return Column(
      key: const Key('apply_sign_in_waiting'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kApplySignInTitle,
          key: const Key('apply_sign_in_title'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                kApplySignInWaitingBody,
                key: const Key('apply_sign_in_waiting_body'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('apply_sign_in_copy_link'),
            onPressed: widget.session.pendingAuthorizeUrl == null
                ? null
                : _onCopyLink,
            child: const Text(kApplySignInCopyLink),
          ),
        ),
        if (_copiedHint != null)
          Text(
            _copiedHint!,
            key: const Key('apply_sign_in_copy_hint'),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            key: const Key('apply_sign_in_cancel'),
            onPressed: _onCancelWaiting,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Column(
      key: const Key('apply_sign_in_success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kApplySignInTitle,
          key: const Key('apply_sign_in_title'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.check_circle,
              key: const Key('apply_sign_in_success_icon'),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Signed in as $_successName',
                key: const Key('apply_sign_in_success_body'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    final message = applySignInDialogErrorMessage(_errorKind);
    return Column(
      key: const Key('apply_sign_in_error'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kApplySignInTitle,
          key: const Key('apply_sign_in_title'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          key: const Key('apply_sign_in_error_body'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const Key('apply_sign_in_try_again'),
            onPressed: _onTryAgain,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
