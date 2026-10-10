import 'package:flutter/material.dart';

import '../ui.dart';

/// A new password needs at least 8 characters; the server checks the rest.
String? validateNewPassword(BuildContext context, String? value) =>
    (value ?? '').length >= 8 ? null : context.l10n.passwordTooShort;

/// The second copy of a new password must match the first.
String? validatePasswordMatch(BuildContext context, String? value, TextEditingController password) =>
    value == password.text ? null : context.l10n.passwordsDontMatch;

/// A password box with the eye that shows or hides what was typed.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.newPassword = false,
    this.autofocus = false,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  /// True where a password is being chosen, so password managers offer to save it.
  final bool newPassword;
  final bool autofocus;

  /// What the server said about it, shown under the field.
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: widget.errorText,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            icon: PopSwitcher(
              child: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                key: ValueKey(_obscure),
              ),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
      );
}
