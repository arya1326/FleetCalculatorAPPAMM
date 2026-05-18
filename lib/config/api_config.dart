class ApiConfig {
  // Ganti dengan IP server/localhost Anda
  // Untuk emulator Android: 10.0.2.2
  // Untuk device fisik: IP komputer/server
  static const String baseUrl = 'https://paleturquoise-louse-896113.hostingersite.com';
  
  // Endpoints
  static const String login = '$baseUrl/api/login.php';
  static const String getUser = '$baseUrl/api/user.php';
  
  // Calculation endpoints
  static const String saveCalculation = '$baseUrl/api/save_calculation.php';
  static const String getCalculations = '$baseUrl/api/get_calculations.php';
  static const String deleteCalculation = '$baseUrl/api/delete_calculation.php';
  static const String clearHistory = '$baseUrl/api/clear_history.php';
}