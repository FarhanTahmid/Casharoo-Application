import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class HelperFunctions {
  static String? getPlatform() {
    if (Platform.isAndroid) {
      return "ANDROID";
    } else if (Platform.isIOS) {
      return "IOS";
    } else if (Platform.isLinux) {
      return "DESKTOP";
    } else if (Platform.isMacOS) {
      return "DESKTOP";
    } else if (Platform.isWindows) {
      return "DESKTOP";
    } else if (kIsWeb) {
      return "WEBAPP";
    } else {
      return null;
    }
  }

  static String? extractDjangoError(String rawBody) {
    // Helper function to extract error messages from Django JSON responses
    // This function assumes the error message is in a standard format
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        if (decoded['detail'] is String) return decoded['detail'] as String;
        for (final entry in decoded.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String && v.isNotEmpty) return v;
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
    } catch (_) {}
    return null;
  }
}
