import 'dart:async';

import 'package:casharoo/main.dart';
import 'package:casharoo/services/auth/screens/verification_code_screen.dart';
import 'package:casharoo/services/auth/google_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:casharoo/helpers/toast_builder.dart';

import 'package:casharoo/helpers/backend_config.dart';
import 'package:casharoo/helpers/helpers.dart';
import 'package:casharoo/services/auth/auth.dart';
import 'package:casharoo/services/auth/screens/forgot_password_email_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const double _maxContentWidth = 440;

  bool get _isAndroidOrIOS =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
     defaultTargetPlatform == TargetPlatform.iOS);

  // --- Sign Up state & controllers ---
  final _signUpFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _isSignUpLoading = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  String? _signUpErrorMessage;

  final _secure = const FlutterSecureStorage();
  static const _kAccessTokenKey = 'auth_access_token';
  static const _kRefreshTokenKey = 'auth_refresh_token';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    // --- dispose sign up controllers ---
    _firstNameController.dispose();
    _lastNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();

    super.dispose();
  }

  void _navigateToPage(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _saveTokens({String? access, String? refresh}) async {
    // If your backend didn’t return tokens, don’t overwrite existing ones
    if (access != null && access.isNotEmpty) {
      await _secure.write(key: _kAccessTokenKey, value: access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await _secure.write(key: _kRefreshTokenKey, value: refresh);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      final Uri uri = BackendConfig.endpoint('/app_users/login/');
      final body = jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
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

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          await AuthService.storeTokens(
            data['tokens']['access'],
            data['tokens']['refresh'],
          );
          await AuthService.storeUserId(data['user']['id'].toString());

          AppToast.show(
            context,
            message: data['message'] ?? 'Login successful',
            type: AppToastType.success,
          );

          // TODO: Navigate to home screen or onboarding page depending on user state
          _navigateToPage(const PlaceholderPage(title: "Home Page"));
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));

          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid email or password';
          });
          _errorMessage =
              HelperFunctions.extractDjangoError(response.body) ??
              'Invalid email or password';
          if (!mounted) return;
          await AppToast.show(
            context,
            message: _errorMessage!,
            type: AppToastType.error,
          );
        }
      } catch (e) {
        debugPrint("Error during login: $e");
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred! Please try again.';
        });
        await AppToast.show(
          context,
          message: _errorMessage!,
          type: AppToastType.error,
        );
        return;
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Add Google sign-in here
    // e.g., await authService.signInWithGoogle();
    // navigate to home on success
    debugPrint("Google login tapped");
    GoogleAuthService.signInWithGoogle().then((userCredential) {
      if (userCredential != null) {
        // Successfully signed in
        debugPrint("User signed in with Google: $userCredential");
        _navigateToPage(const PlaceholderPage(title: "Home Page"));
      }
    }).catchError((error) async {
      debugPrint("Google sign-in error: $error");
      if (!mounted) return;
      await AppToast.show(
        context,
        message: 'Google sign-in failed. Please try again.',
        type: AppToastType.error,
      );
    });
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordEmailPage()),
    );
  }

  String? _validateStrongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) return 'Add at least one digit';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/~`+=]').hasMatch(v)) {
      return 'Add at least one special character';
    }
    if (RegExp(r'\s').hasMatch(v)) return 'Password cannot contain spaces';
    return null;
  }

  Future<void> _handleCreateAccount() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() {
      _isSignUpLoading = true;
      _signUpErrorMessage = null;
    });

    final Uri uri = BackendConfig.endpoint('/app_users/register/');

    final body = jsonEncode({
      'email': _signUpEmailController.text.trim(),
      'password': _signUpPasswordController.text,
      'password_confirm': _signUpConfirmPasswordController.text,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
    });

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

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tokens = (data['tokens'] as Map?)?.cast<String, dynamic>();

        // Store tokens securely
        await _saveTokens(
          access: tokens?['access'] as String?,
          refresh: tokens?['refresh'] as String?,
        );
        // Navigate to Account verification
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
            String message = data['message'];
            AppToast.show(
              context,
              message: message,
              type: AppToastType.success,
            );
            if (!mounted) return;
            setState(() {
              _isSignUpLoading = false;
            });
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerificationCodePage(
                  email: _signUpEmailController.text.trim(),
                  operationPurpose: "VERIFICATION",
                ),
              ),
            );
          } else {
            String message = data['message'];
            AppToast.show(context, message: message, type: AppToastType.error);
          }
        } catch (e) {
          debugPrint("Error during sending email: $e");
          AppToast.show(
            context,
            message:
                "Account was created but error verifying user! Please try again later.",
            type: AppToastType.error,
          );
        }
        return;
      }

      if (response.statusCode == 400) {
        final msg =
            HelperFunctions.extractDjangoError(response.body) ?? 'Invalid data';
        if (!mounted) return;
        setState(() {
          _isSignUpLoading = false;
          _signUpErrorMessage = msg;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _isSignUpLoading = false;
        _signUpErrorMessage =
            'Server error (${response.statusCode}). Please try again.';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSignUpLoading = false;
        _signUpErrorMessage =
            'Request timed out. Check your internet connection.';
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isSignUpLoading = false;
        _signUpErrorMessage = 'No internet connection.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSignUpLoading = false;
        _signUpErrorMessage = 'An unexpected error occurred! Please try again.';
      });
    }
  }

  void _handleSignUp() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final double tabViewHeight =
        (MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                20 -
                20)
            .clamp(420.0, double.infinity);

    return Scaffold(
      // Let Scaffold use theme.scaffoldBackgroundColor
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Heading
                    Text(
                      "Welcome to Casharoo",
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Log in or Sign up to continue",
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Segmented TabBar (theme-aware, gradient pill)
                    Container(
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: cs.primary.withOpacity(
                          0.08,
                        ), // light bluish track
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: "Log in"),
                          Tab(text: "Sign up"),
                        ],
                        labelColor: cs.onPrimary,
                        // ignore: deprecated_member_use
                        unselectedLabelColor: cs.onSurface.withOpacity(0.8),
                        labelStyle: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [cs.secondary, cs.primary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 8,
                              offset: Offset(0, 2),
                              color: Color(0x1A000000),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(2),
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: tabViewHeight,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoginForm(context),
                          _buildSignUpForm(context),
                        ],
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

  Widget _buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // Make the form scrollable within the TabBarView's fixed height
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    Text(
                      "Your Email",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "info@casharoo.com",
                        // ignore: deprecated_member_use
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        // ignore: deprecated_member_use
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    Text(
                      "Password",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleEmailLogin(),
                      decoration: InputDecoration(
                        hintText: "••••••••••",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? cs.error
                                : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? cs.error
                                : cs.primary,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.error),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          "Forgot password?",
                          style: tt.titleMedium?.copyWith(color: cs.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Continue
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                _handleEmailLogin();
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Continue",
                                style: tt.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "or",
                            // ignore: deprecated_member_use
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if(_isAndroidOrIOS)...[
                      // Google for Login
                      _buildSocialLoginButton(
                        context: context,
                        onPressed: _handleGoogleLogin,
                        icon: Icons.g_mobiledata_rounded,
                        text: "Sign in with Google",
                        backgroundColor: theme.colorScheme.surface,
                        textColor: theme.colorScheme.onSurface,
                        borderColor: theme.dividerColor,
                        leading: Image.asset(
                          'assets/application_logos/png-transparent-google-logo-google-text-trademark-logo.png',
                          width: 30,
                          height: 30,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ]else
                    // Sign Up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: tt.bodyMedium),
                        TextButton(
                          onPressed: _handleSignUp,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Sign up",
                            style: tt.titleMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // Make the sign-up form scrollable within the TabBarView's fixed height
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _signUpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First Name
                    Text(
                      "First Name",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "John",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your first name'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Last Name
                    Text(
                      "Last Name",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "Doe",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your last name'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Email
                    Text(
                      "Email",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _signUpEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "info@casharoo.com",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    Text(
                      "Password",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _signUpPasswordController,
                      obscureText: !_signUpPasswordVisible,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "At least 8 characters",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _signUpPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(
                              () => _signUpPasswordVisible =
                                  !_signUpPasswordVisible,
                            );
                          },
                        ),
                      ),
                      validator: _validateStrongPassword,
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    Text(
                      "Confirm Password",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _signUpConfirmPasswordController,
                      obscureText: !_signUpConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleCreateAccount(),
                      decoration: InputDecoration(
                        hintText: "Re-enter password",
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _signUpConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(
                              () => _signUpConfirmPasswordVisible =
                                  !_signUpConfirmPasswordVisible,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        final msg = _validateStrongPassword(value);
                        if (msg != null) return msg;
                        if (value != _signUpPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    if (_signUpErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _signUpErrorMessage!,
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Create Account button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSignUpLoading
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                _handleCreateAccount();
                              },
                        child: _isSignUpLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Create Account",
                                style: tt.titleLarge?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "or",
                            // ignore: deprecated_member_use
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if(_isAndroidOrIOS)...[
                      // Google for Login
                      _buildSocialLoginButton(
                        context: context,
                        onPressed: _handleGoogleLogin,
                        icon: Icons.g_mobiledata_rounded,
                        text: "Sign in with Google",
                        backgroundColor: theme.colorScheme.surface,
                        textColor: theme.colorScheme.onSurface,
                        borderColor: theme.dividerColor,
                        leading: Image.asset(
                          'assets/application_logos/png-transparent-google-logo-google-text-trademark-logo.png',
                          width: 30,
                          height: 30,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ]else

                    // Back to Log in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: tt.bodyMedium),
                        TextButton(
                          onPressed: () => _tabController.animateTo(0),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Log in",
                            style: tt.titleMedium?.copyWith(
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
        );
      },
    );
  }

  /// Same signature; themed and flexible. Keeps your `leading` override.
  Widget _buildSocialLoginButton({
    // required BuildContext context
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    Widget? leading,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    final sideColor =
        borderColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey.shade300
            : Colors.white12);

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: sideColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null)
              leading
            else
              Icon(icon, color: textColor, size: 25),
            const SizedBox(width: 5),
            Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
