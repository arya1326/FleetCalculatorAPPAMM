import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'app_users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'isLoggedIn';

  Future<bool> register(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    
    // Check if user already exists
    for (String userJson in usersJson) {
      final user = jsonDecode(userJson);
      if (user['email'] == email) {
        return false;
      }
    }
    
    // Create new user
    final newUser = {
      'email': email,
      'password': password,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    usersJson.add(jsonEncode(newUser));
    await prefs.setStringList(_usersKey, usersJson);
    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    
    for (String userJson in usersJson) {
      final user = jsonDecode(userJson);
      if (user['email'] == email && user['password'] == password) {
        await prefs.setString(_currentUserKey, userJson);
        await prefs.setBool(_isLoggedInKey, true);
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
    // Clear all user data if needed
    // await prefs.clear(); // Hati-hati, ini akan menghapus semua data
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }
  
  // Tambahan: cek status login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}