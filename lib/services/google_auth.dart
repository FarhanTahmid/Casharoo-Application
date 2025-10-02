import 'dart:convert';
import 'dart:io';
import 'package:casharoo/backend_config.dart';
import 'package:casharoo/helpers.dart';
import 'package:casharoo/services/auth.dart';
import 'package:casharoo/toast_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;

  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '811961094981-n26i4qbavgb48kte1koqedi0b7u7k69o.apps.googleusercontent.com',
      );
    }
    isInitialize = true;
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      initSignIn();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorizationClient = googleUser.authorizationClient;
      GoogleSignInClientAuthorization? authorization = await authorizationClient
          .authorizationForScopes(['email', 'profile']);
      final accessToken = authorization?.accessToken;
      if (accessToken == null) {
        final authorization2 = await authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        );
        if (authorization2?.accessToken == null) {
          throw FirebaseAuthException(code: "error", message: "error");
        }
        authorization = authorization2;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        // Send to backend for user creation and validation
        final Uri uri = BackendConfig.endpoint('/app_users/google-auth/');
        final response = await http.post(
          uri,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'id_token': idToken,
            'device_type': HelperFunctions.getPlatform(),
          }),
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          // Store the token securely
          await AuthService.storeTokens(
            responseData['tokens']['access'],
            responseData['tokens']['refresh'],
          );
          return userCredential;
        } else {
          final responseData = jsonDecode(response.body);
          debugPrint("Response Data: $responseData");
          String errorMessage=HelperFunctions.extractDjangoError(response.body) ??
              'Failed to authenticate with backend.';
          throw FirebaseAuthException(code: "error", message: errorMessage);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }
}
