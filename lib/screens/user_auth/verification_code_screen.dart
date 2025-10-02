import 'dart:async';
import 'dart:convert';
import 'package:casharoo/services/auth.dart';
import 'package:casharoo/backend_config.dart';
import 'package:casharoo/screens/user_auth/reset_password_page.dart';
import 'package:casharoo/toast_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class VerificationCodePage extends StatefulWidget {
  final String email;
  final String operationPurpose;
  const VerificationCodePage({
    super.key,
    required this.email,
    required this.operationPurpose,
  });
  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  static const double _maxContentWidth = 440;

  // --- PIN state ---
  final _nodes = List<FocusNode>.generate(
    6,
    (_) => FocusNode(),
    growable: false,
  );
  final _controllers = List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
    growable: false,
  );

  // --- Verify/resend state ---
  bool _isLoading = false;
  bool _resendLoading = false;

  // --- Cooldown timer state ---
  static const int _resendCooldownSeconds =
      90; // change if you want a different window
  int _secondsLeft = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown(); // start as soon as the page opens
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // --- Backend placeholders ---
  Future<(bool, String, String)> _verifyCode(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // findout which URI to hit
    if (widget.operationPurpose == "RESET_PASS") {
      // Logic for forgot password verification
      final Uri uri = BackendConfig.endpoint(
        'app_users/forgot-password/verify-code/',
      );
      debugPrint("Requesting with URI: $uri");
      final body = jsonEncode({'verification_code': code, 'email': email});
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

        debugPrint("Response body: $data");

        if (response.statusCode == 200) {
          String message = data['message'];
          return (true, message, widget.operationPurpose);
        } else {
          String message = data['error'];
          return (false, message, widget.operationPurpose);
        }
      } catch (e) {
        debugPrint("Error during verifying code: $e");
        return (
          false,
          "Something went wrong! Please try again later",
          widget.operationPurpose,
        );
      }
    } else if (widget.operationPurpose == "VERIFICATION") {
      final Uri uri = BackendConfig.endpoint('app_users/verify-account/');
      final body = jsonEncode({'verification_code': code});
      try {
        final http.Response response = await AuthService.authenticatedRequest(
          'post',
          uri,
          body: jsonDecode(body),
        );

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        debugPrint("Response data $data");

        if (response.statusCode == 200) {
          String message = data['message'];
          return (true, message, widget.operationPurpose);
        } else {
          String message = data['error'];
          return (false, message, widget.operationPurpose);
        }
      } catch (e) {
        debugPrint("Error during sending email: $e");
        return (
          false,
          "Something went wrong! Please try again later",
          widget.operationPurpose,
        );
      }
    }
    return (false, 'Unexpected error', widget.operationPurpose);
  }

  // --- Timer helpers ---
  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldownSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  bool get _canResend => !_resendLoading && _secondsLeft == 0;

  String _formatSeconds(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return; // guard
    setState(() => _resendLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (widget.operationPurpose == "RESET_PASS") {
      final Uri uri = BackendConfig.endpoint(
        'app_users/forgot-password/send-verification-code/',
      );

      final body = jsonEncode({'email': widget.email});

      String message = "";

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
          message = data['message'];
          AppToast.show(context, message: message, type: AppToastType.success);
        } else {
          message = data['error'];
          AppToast.show(context, message: message, type: AppToastType.error);
        }
      } catch (e) {
        debugPrint("Error during sending email: $e");
        AppToast.show(
          context,
          message: "Something went wrong!",
          type: AppToastType.error,
        );
      }
    } else if (widget.operationPurpose == "VERIFICATION") {
      String message = "";
      final Uri sendVerificationCodeUri = BackendConfig.endpoint(
        'app_users/send-verification-code/',
      );
      try {
        final http.Response response = await AuthService.authenticatedRequest(
          'get',
          sendVerificationCodeUri,
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200) {
          message = data['message'];
          AppToast.show(context, message: message, type: AppToastType.success);
        } else {
          message = data['error'];
          AppToast.show(context, message: message, type: AppToastType.error);
        }
      } catch (e) {
        debugPrint("Error during sending email: $e");
        AppToast.show(
          context,
          message: "Something went wrong!",
          type: AppToastType.error,
        );
      }
    }

    if (!mounted) return;
    setState(() => _resendLoading = false);

    _startResendCooldown(); // restart cooldown after resend
  }

  String get _code => _controllers.map((c) => c.text).join();

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final maskedName = name.length <= 2
        ? name[0] + '*'
        : name.substring(0, 2) + '***';
    final dp = domain.split('.');
    final maskedDomain = dp.first.length > 3
        ? dp.first.substring(0, 3) + '...'
        : dp.first;
    return '$maskedName@$maskedDomain.${dp.length > 1 ? dp.last : ''}';
  }

  Future<void> _handleVerify() async {
    setState(() => _isLoading = true);
    final result = await _verifyCode(widget.email, _code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.$1 && result.$3 == "RESET_PASS") {
      AppToast.show(context, message: result.$2, type: AppToastType.success);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: widget.email, code: _code),
        ),
      );
    } else if (result.$1 && result.$3 == "VERIFICATION") {
      // TODO: Show verification message and redirect to Homepage
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

    InputDecoration _pinDecoration() => InputDecoration(
      filled: true,
      fillColor: cs.surface,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    );

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check your email',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification code to ${_maskEmail(widget.email)}\n'
                    'Enter the 6 digit code mentioned in the email.\nThe code expires in 5 minutes.',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // 6 PIN boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _nodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: tt.titleLarge,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _pinDecoration(),
                          onChanged: (v) {
                            if (v.length == 1 && i < 5)
                              _nodes[i + 1].requestFocus();
                            if (v.isEmpty && i > 0)
                              _nodes[i - 1].requestFocus();
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading || _code.length != 6
                          ? null
                          : _handleVerify,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text('Verify Code'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resend row with cooldown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Haven't got the email yet? ", style: tt.bodyMedium),
                      if (_secondsLeft > 0)
                        Text(
                          'Resend in ${_formatSeconds(_secondsLeft)}',
                          style: tt.bodyMedium?.copyWith(
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _canResend ? _resendEmail : null,
                          child: _resendLoading
                              ? const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Resend email',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
