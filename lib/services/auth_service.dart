import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService(); // singleton

  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'isLoggedIn';

  Future<bool> login(String nrp) async {
    final result = await _apiService.login(nrp);
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(result['user']));
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    await _apiService.logout();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) return jsonDecode(userJson);
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
