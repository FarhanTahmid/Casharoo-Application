import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';

/// Frame shared by the signed-out screens: the logo on the navy field, and the
/// form on a white sheet below it. The header shrinks when the keyboard opens,
/// so the fields and the button stay in view.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.children, this.title, this.subtitle});

  /// Without a title the logo and the app's name head the screen.
  final String? title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final heading = text.headlineSmall?.copyWith(color: colors.onHeader);

    // The logo with its name where the screen has no title of its own; the mark alone beside a title
    final Widget header = typing
        ? Row(
            key: const ValueKey('compact'),
            children: [
              if (title == null)
                const BrandLogo(layout: BrandLayout.horizontal, onDark: true, height: 48)
              else ...[
                const BrandLogo(height: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(title!, style: text.titleLarge?.copyWith(color: colors.onHeader))),
              ],
            ],
          )
        : Column(
            key: const ValueKey('full'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (title == null)
                const BrandLogo(layout: BrandLayout.horizontal, onDark: true, height: 84)
              else ...[
                const BrandLogo(height: 60),
                const SizedBox(height: 18),
                Text(title!, style: heading),
              ],
              if (subtitle != null) ...[
                SizedBox(height: title == null ? 14 : 6),
                Text(subtitle!, style: text.bodyLarge?.copyWith(color: colors.onHeaderMuted)),
              ],
              const SizedBox(height: 10),
            ],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.header,
        body: SafeArea(
          bottom: false,
          child: PassbookBody(
            header: AnimatedSize(
              duration: context.motion(AppMotion.emphasised),
              curve: AppMotion.ease,
              alignment: Alignment.topLeft,
              child: SizedBox(width: double.infinity, child: header),
            ),
            child: ColoredBox(
              color: colors.sheet,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + MediaQuery.paddingOf(context).bottom),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs an auth request with a busy state and shows what the server said if it failed.
mixin _Submitting<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  int _refused = 0;

  Future<bool> submit(Future<String?> Function() action) async {
    if (!(formKey.currentState?.validate() ?? true)) {
      setState(() => _refused++);
      return false;
    }
    setState(() => busy = true);
    final error = await action();
    if (!mounted) return false;
    setState(() {
      busy = false;
      if (error != null) _refused++;
    });
    if (error != null) context.showMessage(authErrorText(context, error));
    return error == null;
  }

  /// Shakes when the form or the server says no.
  Widget submitButton(String label, VoidCallback onPressed) =>
      Shake(trigger: _refused, child: BusyButton(label: label, busy: busy, onPressed: onPressed));
}

String? _validateEmail(BuildContext context, String? value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value?.trim() ?? '') ? null : context.l10n.enterEmail;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.signUp = false});

  /// The same form creates an account or logs in.
  final bool signUp;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with _Submitting {
  /// The email at sign-up; the email or the username at login.
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    final auth = ref.read(authControllerProvider.notifier);
    final identifier = _identifier.text.trim();
    return submit(
      () => widget.signUp ? auth.signUp(identifier, _password.text) : auth.logIn(identifier, _password.text),
    );
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
              if (widget.signUp)
                TextFormField(
                  controller: _identifier,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline_rounded)),
                  validator: (value) => _validateEmail(context, value),
                )
              else
                TextFormField(
                  controller: _identifier,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.emailOrUsername,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.enterEmailOrUsername : null,
                ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                label: l10n.password,
                newPassword: widget.signUp,
                textInputAction: widget.signUp ? TextInputAction.next : TextInputAction.done,
                validator: (value) => widget.signUp ? validateNewPassword(context, value) : null,
                onSubmitted: widget.signUp ? null : (_) => _submit(),
              ),
              if (widget.signUp) ...[
                const SizedBox(height: 12),
                PasswordField(
                  controller: _confirm,
                  label: l10n.confirmPassword,
                  newPassword: true,
                  validator: (value) => validatePasswordMatch(context, value, _password),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
        if (!widget.signUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => context.go('/forgot'), child: Text(l10n.forgotPassword)),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 4),
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
        const SizedBox(height: 12),
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
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
            decoration: InputDecoration(labelText: l10n.code),
            validator: (value) => (value ?? '').trim().isEmpty ? l10n.code : null,
          ),
        ),
        const SizedBox(height: 16),
        submitButton(l10n.verify, () => submit(() => auth.verifyEmail(_code.text))),
        const SizedBox(height: 4),
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
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline_rounded)),
            validator: (value) => _validateEmail(context, value),
          ),
        ),
        const SizedBox(height: 16),
        submitButton(
          l10n.sendCode,
          () => submit(() => ref.read(authControllerProvider.notifier).requestPasswordReset(_email.text.trim())),
        ),
        const SizedBox(height: 4),
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
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
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
                decoration: InputDecoration(labelText: l10n.code, prefixIcon: const Icon(Icons.pin_outlined)),
                validator: (value) => (value ?? '').trim().isEmpty ? l10n.code : null,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                label: l10n.newPassword,
                newPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) => validateNewPassword(context, value),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                label: l10n.confirmNewPassword,
                newPassword: true,
                validator: (value) => validatePasswordMatch(context, value, _password),
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
        const SizedBox(height: 4),
        TextButton(onPressed: busy ? null : auth.logOut, child: Text(l10n.cancel)),
      ],
    );
  }
}
