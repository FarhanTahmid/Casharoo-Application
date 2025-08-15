import 'dart:convert';

class HelperFunctions {

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