import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends State<ResetPasswordPage> {
  static const double _maxContentWidth = 440;
  final _formKey = GlobalKey<FormState>();
  final _pwController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _pwController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<bool> _updatePassword(String email, String code, String password) async {
    // TODO: update password using backend
    await Future.delayed(const Duration(milliseconds: 900));
    return true; // return false on failure
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await _updatePassword(
      widget.email,
      widget.code,
      _pwController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (_) => const ForgotPasswordSuccessPage()),
      //   (route) => route.isFirst,
      // );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not update password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final isValid = () => (_formKey.currentState?.validate() ?? false);

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
                    Text('Set a new password',
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new password. Ensure it differs from previous ones for security',
                      style: tt.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    Text('Password',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pwController,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        hintText: 'Enter your new password',
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
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                          icon: Icon(_obscure1
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.isEmpty) return 'Password is required';
                        if (s.length < 8) return 'Use at least 8 characters';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),
                    Text('Confirm Password',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        hintText: 'Re-enter password',
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
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                          icon: Icon(_obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.isEmpty) return 'Please confirm the password';
                        if (s != _pwController.text) return 'Passwords do not match';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading || !isValid() ? null : _handleUpdate,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4))
                            : const Text('Update Password'),
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