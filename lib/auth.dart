import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:casharoo/backend_config.dart';

class AuthService {
  static const _secure = FlutterSecureStorage();
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  static String? _cachedAccess;
  static String? _cachedRefresh;

  // Store tokens in shared preferences
  static Future<void> storeTokens(
    String accessToken,
    String refreshToken,
  ) async {
    // If your backend didn’t return tokens, don’t overwrite existing ones
    if (accessToken.isNotEmpty) {
      await _secure.write(key: _accessTokenKey, value: accessToken);
    }
    if (refreshToken.isNotEmpty) {
      await _secure.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  // Get stored access token
  static Future<String?> getAccessToken({bool useCache = true}) async {
    if (useCache && _cachedAccess != null) return _cachedAccess;
    _cachedAccess = await _secure.read(key: _accessTokenKey);
    return _cachedAccess;
  }

  // Get stored refresh token
  static Future<String?> getRefreshToken({bool useCache = true}) async {
    if (useCache && _cachedRefresh != null) return _cachedRefresh;
    _cachedRefresh = await _secure.read(key: _refreshTokenKey);
    return _cachedRefresh;
  }

  // Clear all stored tokens
  static Future<void> clearTokens() async {
    await _secure.delete(key: _accessTokenKey);
    await _secure.delete(key: _refreshTokenKey);
    _cachedAccess = null;
    _cachedRefresh = null;
  }

  // check if user is authenticated
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    final Uri uri = BackendConfig.endpoint('/app_users/auth-status/');
    print("Checking authentication status at: $uri");
    final accessToken = await getAccessToken(useCache: true);
    if (accessToken == null) {
      return {'isAuthenticated': false, 'message': 'No access token found'};
    }
    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      debugPrint(
        "Auth status response: ${response.statusCode} ${response.body}",
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token might be expired so refresh it
        return await refreshAccessToken();
      } else {
        return {
          'isAuthenticated': false,
          'message': 'Failed to check authentication status',
        };
      }
    } catch (e) {
      debugPrint("Error checking authentication status: $e");
      return {
        'isAuthenticated': false,
        'message': 'Error checking authentication status',
      };
    }
  } //Check auth status end

  // Refresh access token using refresh token
  static Future<Map<String, dynamic>> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      return {'success': false, 'message': 'No refresh token found'};
    }
    try {
      final Uri uri = BackendConfig.endpoint('/app_users/token-refresh/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      debugPrint(
        "Refresh token response: ${response.statusCode} ${response.body}",
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access'] as String? ?? '';
        final newRefreshToken = data['refresh'] as String? ?? '';

        if (newRefreshToken.isNotEmpty && newAccessToken.isNotEmpty) {
          await storeTokens(newAccessToken, newRefreshToken);
          _cachedAccess = newAccessToken;
          _cachedRefresh = newRefreshToken;
          return {
            'success': true,
            'authenticated': true,
            'access_token': newAccessToken,
            'message': 'Tokens refreshed successfully',
          };
        } else {
          await clearTokens();
          return {'success': false, 'message': 'Refresh token expired'};
        }
      }
      return {'success': false, 'message': 'Failed to refresh access token'};
    } catch (e) {
      debugPrint("Error refreshing access token: $e");
      return {'success': false, 'message': 'Error refreshing access token'};
    }
  } // Refresh access token end

  static Future<http.Response> authenticatedRequest(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    String? accessToken = await getAccessToken();
    if (accessToken == null) {
      throw Exception(
        'No access token found. User might not be authenticated.',
      );
    }
    Map<String, String> requestHeaders = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PaTCH':
        response = await http.patch(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
    // If token is expired, try to refresh and retry
    if (response.statusCode == 401) {
      final refreshResult = await refreshAccessToken();
      if (refreshResult['success'] == true) {
        // Retry the request with new access token
        requestHeaders['Authorization'] =
            'Bearer ${refreshResult['access_token']}';
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: requestHeaders);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PaTCH':
            response = await http.patch(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      }
    }
    return response;
  }
}
