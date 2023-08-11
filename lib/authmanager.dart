import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> getPrefs() async {
  return await SharedPreferences.getInstance();
}

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

  Future<void> setAuthToken(String token) async {
    await _prefs?.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    await _prefs?.remove('auth_token');
  }
}
