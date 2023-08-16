import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() => _instance;

  SharedPreferences? _prefs;

  AuthManager._internal() {
    initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get authToken => _prefs?.getString('auth_token');

  int? getUserIdFromToken() {
    final token = authToken;
    if (token != null) {
      final tokenParts = token.split('.');
      if (tokenParts.length == 3) {
        final payloadBase64 = tokenParts[1];
        final payload =
            json.decode(utf8.decode(base64Url.decode(payloadBase64)));
        return payload['user_id'];
      }
    }
    return null;
  }

  Future<void> setAuthToken(String token) async {
    await _prefs?.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    await _prefs?.remove('auth_token');
  }
}
