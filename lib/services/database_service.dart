import '../models/calculation_model.dart';
import 'api_service.dart';

class DatabaseService {
  // Gunakan singleton ApiService agar cookie tidak hilang antar instance
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> saveCalculation(
      CalculationModel calculation, String userEmail) async {
    return _apiService.saveCalculation(calculation);
  }

  Future<List<CalculationModel>> getCalculations(String userEmail) async {
    return await _apiService.getCalculations();
  }

  Future<CalculationModel?> getLastCalculation(String userEmail) async {
    final calculations = await getCalculations(userEmail);
    if (calculations.isNotEmpty) return calculations.first;
    return null;
  }

  Future<void> clearHistory(String userEmail) async {
    await _apiService.clearHistory();
  }

  Future<void> deleteCalculation(String userEmail, String calculationId) async {
    await _apiService.deleteCalculation(calculationId);
  }
}
