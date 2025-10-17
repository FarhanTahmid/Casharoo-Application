// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  // Prefer Uri to avoid string concat bugs
  static final Uri base = _resolveBase();

  static Uri _resolveBase() {
    // flutter_dotenv has .get with a fallback
    final raw = dotenv.maybeGet('API_URL') ??
        dotenv.get('API_URL', fallback: _platformDefaultBase());

    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError(
        'Invalid API_URL "$raw". Include scheme, e.g., https://api.example.com',
      );
    }
    return uri;
  }

  static String _platformDefaultBase() {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.123:8000/api'; // Android emulator
    return 'http://localhost:8000/api'; // iOS simulator/macOS/Windows/Linux
  }

  // Helper to build endpoints safely
  static Uri endpoint(String path, {Map<String, dynamic>? query}) {
    // Ensures no double slashes and keeps base host/scheme
    return base.replace(
      path: _joinPath(base.path, path),
      queryParameters: query,
    );
  }

  static String _joinPath(String a, String b) {
    final left = a.endsWith('/') ? a.substring(0, a.length - 1) : a;
    final right = b.startsWith('/') ? b.substring(1) : b;
    return '$left/$right';
  }
}