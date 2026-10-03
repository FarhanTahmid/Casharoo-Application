import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';

/// Frame shared by the signed-out screens: centred, narrow, scrollable.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.children, this.title, this.subtitle});

  /// Without a title the full logo (mark and name) heads the screen.
  final String? title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title == null)
                      const BrandLogo(height: 160, full: true)
                    else ...[
                      const BrandLogo(),
                      const SizedBox(height: 16),
                      Text(title!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 32),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Runs an auth request with a busy state and shows what the server said if it failed.
mixin _Submitting<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;

  Future<bool> submit(Future<String?> Function() action) async {
    if (!(formKey.currentState?.validate() ?? true)) return false;
    setState(() => busy = true);
    final error = await action();
    if (!mounted) return false;
    setState(() => busy = false);
    if (error != null) context.showMessage(authErrorText(context, error));
    return error == null;
  }

  Widget submitButton(String label, VoidCallback onPressed) => FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      );
}

String? _validateEmail(BuildContext context, String? value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value?.trim() ?? '') ? null : context.l10n.enterEmail;

String? _validatePassword(BuildContext context, String? value) =>
    (value ?? '').length >= 8 ? null : context.l10n.passwordTooShort;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.signUp = false});

  /// The same form creates an account or logs in.
  final bool signUp;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with _Submitting {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    final auth = ref.read(authControllerProvider.notifier);
    final email = _email.text.trim();
    return submit(() => widget.signUp ? auth.signUp(email, _password.text) : auth.logIn(email, _password.text));
  }

  Future<void> _google() => submit(() async {
        try {
          await GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleServerClientId);
          final account = await GoogleSignIn.instance.authenticate();
          final idToken = account.authentication.idToken;
          if (idToken == null) return 'Google did not return an ID token.';
          return ref
              .read(authControllerProvider.notifier)
              .logInWithGoogle(idToken: idToken, clientId: AppConfig.googleServerClientId);
        } on GoogleSignInException catch (error) {
          return error.code == GoogleSignInExceptionCode.canceled ? null : '${error.description ?? error.code}';
        }
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _AuthScaffold(
      subtitle: l10n.tagline,
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.email),
                validator: (value) => _validateEmail(context, value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) => widget.signUp ? _validatePassword(context, value) : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (!widget.signUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => context.go('/forgot'), child: Text(l10n.forgotPassword)),
          ),
        const SizedBox(height: 16),
        submitButton(widget.signUp ? l10n.signUp : l10n.logIn, _submit),
        if (AppConfig.googleServerClientId.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _google,
            icon: Image.asset(
              'assets/application_logos/png-transparent-google-logo-google-text-trademark-logo.png',
              height: 20,
            ),
            label: Text(l10n.continueWithGoogle),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(widget.signUp ? '/login' : '/signup'),
          child: Text(widget.signUp ? l10n.haveAccount : l10n.noAccount),
        ),
      ],
    );
  }
}

/// Enter the code that was emailed after sign-up.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> with _Submitting {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider.notifier);
    final email = ref.watch(authControllerProvider).email ?? '';
    return _AuthScaffold(
      title: l10n.verifyEmailTitle,
      subtitle: l10n.codeSentTo(email),
      children: [
        Form(
          key: formKey,
          child: TextFormField(
            controller: _code,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 24, letterSpacing: 4),
            decoration: InputDecoration(labelText: l10n.code),
            validator: (value) => (value ?? '').trim().isEmpty ? l10n.code : null,
          ),
        ),
        const SizedBox(height: 16),
        submitButton(l10n.verify, () => submit(() => auth.verifyEmail(_code.text))),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  if (await submit(auth.resendEmailCode) && context.mounted) context.showMessage(l10n.codeResent);
                },
          child: Text(l10n.resendCode),
        ),
        TextButton(onPressed: busy ? null : auth.logOut, child: Text(l10n.useAnotherAccount)),
      ],
    );
  }
}

/// Step one of a password reset: ask for the email a code should go to.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> with _Submitting {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _AuthScaffold(
      title: l10n.resetPasswordTitle,
      subtitle: l10n.resetPasswordHint,
      children: [
        Form(
          key: formKey,
          child: TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
            validator: (value) => _validateEmail(context, value),
          ),
        ),
        const SizedBox(height: 16),
        submitButton(
          l10n.sendCode,
          () => submit(() => ref.read(authControllerProvider.notifier).requestPasswordReset(_email.text.trim())),
        ),
        TextButton(onPressed: () => context.go('/login'), child: Text(l10n.logIn)),
      ],
    );
  }
}

/// Step two: the emailed code plus the new password.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> with _Submitting {
  final _code = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider.notifier);
    return _AuthScaffold(
      title: l10n.setNewPassword,
      subtitle: l10n.codeSentTo(ref.watch(authControllerProvider).email ?? ''),
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.code),
                validator: (value) => (value ?? '').trim().isEmpty ? l10n.code : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.newPassword),
                validator: (value) => _validatePassword(context, value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        submitButton(l10n.save, () async {
          if (await submit(() => auth.resetPassword(_code.text, _password.text)) && context.mounted) {
            context.showMessage(l10n.passwordChanged);
          }
        }),
        TextButton(onPressed: busy ? null : auth.logOut, child: Text(l10n.cancel)),
      ],
    );
  }
}
