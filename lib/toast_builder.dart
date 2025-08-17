// helpers/toast.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  /// Show a platform-aware toast/snackbar.
  static Future<void> show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.BOTTOM,
    bool preferSnackBarOnDesktop = true,
    Color? background,
    Color? foreground,
    double fontSize = 14,
  }) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Sensible defaults by type (Material 3-friendly).
    background ??= switch (type) {
      AppToastType.success => cs.primaryContainer,
      AppToastType.error => cs.errorContainer,
      AppToastType.warning => cs.tertiaryContainer,
      AppToastType.info => cs.secondaryContainer,
    };
    foreground ??= switch (type) {
      AppToastType.success => cs.onPrimaryContainer,
      AppToastType.error => cs.onErrorContainer,
      AppToastType.warning => cs.onTertiaryContainer,
      AppToastType.info => cs.onSecondaryContainer,
    };

    // Decide platform route
    final platform = kIsWeb ? TargetPlatform.android : defaultTargetPlatform;
    final isMobile = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final isDesktop = platform == TargetPlatform.macOS || platform == TargetPlatform.windows || platform == TargetPlatform.linux;

    // If mobile: prefer Fluttertoast. If desktop/web: use SnackBar unless overridden.
    if (isMobile) {
      await _showFlutterToast(
        message: message,
        seconds: seconds,
        gravity: gravity,
        background: background,
        foreground: foreground,
        fontSize: fontSize,
      );
      return;
    }

    if (kIsWeb || (isDesktop && preferSnackBarOnDesktop)) {
      _showSnackBar(
        context,
        message: message,
        background: background,
        foreground: foreground,
        fontSize: fontSize,
        type: type,
        seconds: seconds,
      );
      return;
    }

    // Fallback: try Fluttertoast; if it fails, show SnackBar.
    try {
      await _showFlutterToast(
        message: message,
        seconds: seconds,
        gravity: gravity,
        background: background,
        foreground: foreground,
        fontSize: fontSize,
      );
    } catch (_) {
      _showSnackBar(
        context,
        message: message,
        background: background,
        foreground: foreground,
        fontSize: fontSize,
        type: type,
        seconds: seconds,
      );
    }
  }

  static Future<void> _showFlutterToast({
    required String message,
    required int seconds,
    required ToastGravity gravity,
    required Color background,
    required Color foreground,
    required double fontSize,
  }) async {
    // LENGTH_SHORT/LONG are hints; control precise time via timeInSecForIosWeb.
    final toastLength = seconds <= 2 ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG;
    await Fluttertoast.cancel(); // avoid stacking
    await Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: seconds, // used on iOS & web by fluttertoast
      backgroundColor: background,
      textColor: foreground,
      fontSize: fontSize,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    required double fontSize,
    required AppToastType type,
    required int seconds,
  }) {
    final icon = switch (type) {
      AppToastType.success => Icons.check_circle,
      AppToastType.error => Icons.error,
      AppToastType.warning => Icons.warning,
      AppToastType.info => Icons.info,
    };

    final bar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: background,
      duration: Duration(seconds: seconds),
      content: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(bar);
  }
}
