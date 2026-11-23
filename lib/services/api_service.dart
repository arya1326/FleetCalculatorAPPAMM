import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/calculation_model.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Token ──────────────────────────────────────────────────────────────────
  String? _token;
  static const String _tokenKey = 'auth_token';

  Future<void> loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool withJson = false}) async {
    await loadToken();
    final h = <String, String>{};
    if (withJson) h['Content-Type'] = 'application/json';
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String nrp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nrp': nrp}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await _saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async => await _clearToken();

  // ── Calculations ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveCalculation(
      CalculationModel calculation) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.saveCalculation),
        headers: await _headers(withJson: true),
        body: jsonEncode(calculation.toMap()),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message']
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<CalculationModel>> getCalculations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getCalculations),
        headers: await _headers(),
      );

      // Debug: print response untuk sementara
      print('GET calculations status: ${response.statusCode}');
      print('GET calculations body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['calculations'] != null) {
          final List<dynamic> list = data['calculations'];
          return list
              .map((json) =>
                  CalculationModel.fromMap(json['id'].toString(), json))
              .toList();
        }
      } else if (response.statusCode == 401) {
        // Token expired atau tidak valid
        print('Token tidak valid, perlu login ulang');
      }
      return [];
    } catch (e, stackTrace) {
      print('Error getCalculations: $e');
      print('StackTrace: $stackTrace');
      return [];
    }
  }

  Future<bool> deleteCalculation(String calculationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.deleteCalculation}/$calculationId'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.clearHistory),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUser),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['user'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
