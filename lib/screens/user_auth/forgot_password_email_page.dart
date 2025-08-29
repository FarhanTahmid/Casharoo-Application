import 'dart:convert';

import 'package:casharoo/backend_config.dart';
import 'package:casharoo/screens/user_auth/verification_code_screen.dart';
import 'package:casharoo/toast_builder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});
  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  static const double _maxContentWidth = 440;
  final String operationPurpose = "RESET_PASS";
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<(bool, String)> _sendResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final Uri uri = BackendConfig.endpoint(
      'app_users/forgot-password/send-verification-code/',
    );

    debugPrint("Sending email to :$email with URI $uri");

    final body = jsonEncode({'email': email});

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        String message = data['message'];
        return (true, message);
      } else {
        String message = data['error'];
        return (false, message);
      }
    } catch (e) {
      debugPrint("Error during sending email: $e");
      return (false, "Something went wrong! Please try again later");
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    final result = await _sendResetEmail(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.$1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerificationCodePage(email: email,operationPurpose: operationPurpose,)),
      );
      AppToast.show(context, message: result.$2, type: AppToastType.success);
    } else {
      AppToast.show(context, message: result.$2, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: cs.surface,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        title: const SizedBox.shrink(),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (_, __) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forgot password',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your email to reset the password',
                      style: tt.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Your Email',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.primary, width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        final re = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
                        if (s.isEmpty) return 'Email is required';
                        if (!re.hasMatch(s)) return 'Enter a valid email';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            _isLoading ||
                                !(_formKey.currentState?.validate() ?? false)
                            ? null
                            : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Reset Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
