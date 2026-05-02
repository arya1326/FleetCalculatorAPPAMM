import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_model.dart';

class DatabaseService {
  static const String _calculationsPrefix = 'calculations_';

  Future<void> saveCalculation(CalculationModel calculation, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_calculationsPrefix$userEmail';
    final calculationsJson = prefs.getStringList(key) ?? [];
    
    calculationsJson.add(jsonEncode(calculation.toMap()));
    
    // Keep only last 30 days and latest 100 records
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final filtered = calculationsJson.where((jsonStr) {
      try {
        final map = jsonDecode(jsonStr);
        final timestamp = DateTime.parse(map['timestamp']);
        return timestamp.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList();
    
    // Keep only last 100 records
    while (filtered.length > 100) {
      filtered.removeAt(0);
    }
    
    await prefs.setStringList(key, filtered);
  }

  Future<List<CalculationModel>> getCalculations(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_calculationsPrefix$userEmail';
    final calculationsJson = prefs.getStringList(key) ?? [];
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final calculations = <CalculationModel>[];
    for (String jsonStr in calculationsJson) {
      try {
        final map = jsonDecode(jsonStr);
        final timestamp = DateTime.parse(map['timestamp']);
        if (timestamp.isAfter(thirtyDaysAgo)) {
          calculations.add(CalculationModel.fromMap(map['id'], map));
        }
      } catch (e) {
        continue;
      }
    }
    
    // Sort by timestamp descending
    calculations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return calculations;
  }

  Future<CalculationModel?> getLastCalculation(String userEmail) async {
    final calculations = await getCalculations(userEmail);
    if (calculations.isNotEmpty) {
      return calculations.first;
    }
    return null;
  }

  Future<void> clearHistory(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_calculationsPrefix$userEmail';
    await prefs.remove(key);
  }

  Future<void> deleteCalculation(String userEmail, String calculationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_calculationsPrefix$userEmail';
    final calculationsJson = prefs.getStringList(key) ?? [];
    
    final updated = calculationsJson.where((jsonStr) {
      try {
        final map = jsonDecode(jsonStr);
        return map['id'] != calculationId;
      } catch (e) {
        return true;
      }
    }).toList();
    
    await prefs.setStringList(key, updated);
  }
}