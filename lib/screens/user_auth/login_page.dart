import 'package:flutter/material.dart';

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
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _errorMessage = "Wrong password";
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Add Google sign-in here
    // e.g., await authService.signInWithGoogle();
    // navigate to home on success
    debugPrint("Google login tapped");
  }

  void _handleForgotPassword() {
    debugPrint("Forgot password tapped");
  }

  void _handleSignUp() {
    _tabController.animateTo(1);
    debugPrint("Sign up tapped");
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
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Log in to continue",
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Segmented TabBar (theme-aware, gradient pill)
                  Container(
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: cs.primary.withOpacity(0.08), // light bluish track
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
                      labelStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      unselectedLabelStyle:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w500),
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
                      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          Text(
            "Your Email",
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: "info@casharoo.com",
              // ignore: deprecated_member_use
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
              // ignore: deprecated_member_use
              prefixIcon: Icon(Icons.email_outlined, color: cs.onSurface.withOpacity(0.7)),
              // Borders default to your InputDecorationTheme; tweak radii to match app
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
              if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password
          Text(
            "Password",
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleEmailLogin(),
            decoration: InputDecoration(
              hintText: "••••••••••",
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.lock_outline, color: cs.onSurface.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage != null ? cs.error : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage != null ? cs.error : cs.primary,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.error),
              ),
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
            Text(_errorMessage!, style: tt.bodySmall?.copyWith(color: cs.error)),
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
              // Uses your ElevatedButtonTheme for colors/radius; keep height only
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                  "or continue with",
                  // ignore: deprecated_member_use
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
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

          // Google
          _buildSocialLoginButton(
            context: context,
            onPressed: _handleGoogleLogin,
            icon: Icons.g_mobiledata_rounded,
            text: "Login with Google",
            backgroundColor: theme.colorScheme.surface,
            textColor: theme.colorScheme.onSurface,
            borderColor: theme.dividerColor,
            leading: Image.asset(
              'assets/application_logos/png-transparent-google-logo-google-text-trademark-logo.png',
              width: 22,
              height: 22,
            ),
          ),

          const SizedBox(height: 24),

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
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 400,
      child: Center(
        child: Text(
          "Sign Up Form\n\n// TODO: Implement sign up form here",
          textAlign: TextAlign.center,
          style: tt.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ),
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
    Widget? leading, required BuildContext context,
  }) {
    final theme = Theme.of(context);

    final sideColor = borderColor ??
        (theme.brightness == Brightness.light ? Colors.grey.shade300 : Colors.white12);

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
              Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
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
