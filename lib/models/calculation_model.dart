class CalculationModel {
  final String id;
  final String material;
  final double distance;
  final int actualHauler;
  final double loaderProd;
  final String loaderName;
  final double haulerCap;
  final String haulerName;
  final double speed;
  final double loadingTime;
  final double spottingTime;
  final double dumpingTime;
  final double cycleTime;
  final int recommendedHauler;
  final double matchFactor;
  final String status;
  final DateTime timestamp;

  CalculationModel({
    required this.id,
    required this.material,
    required this.distance,
    required this.actualHauler,
    required this.loaderProd,
    required this.loaderName,
    required this.haulerCap,
    required this.haulerName,
    required this.speed,
    required this.loadingTime,
    required this.spottingTime,
    required this.dumpingTime,
    required this.cycleTime,
    required this.recommendedHauler,
    required this.matchFactor,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material': material,
      'distance': distance,
      'actualHauler': actualHauler,
      'loaderProd': loaderProd,
      'loaderName': loaderName,
      'haulerCap': haulerCap,
      'haulerName': haulerName,
      'speed': speed,
      'loadingTime': loadingTime,
      'spottingTime': spottingTime,
      'dumpingTime': dumpingTime,
      'cycleTime': cycleTime,
      'recommendedHauler': recommendedHauler,
      'matchFactor': matchFactor,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculationModel.fromMap(String id, Map<String, dynamic> map) {
    return CalculationModel(
      id: id,
      material: map['material']?.toString() ?? '',
      distance: double.tryParse(map['distance'].toString()) ?? 0.0,
      actualHauler: int.tryParse(map['actualHauler'].toString()) ?? 0,
      loaderProd: double.tryParse(map['loaderProd'].toString()) ?? 0.0,
      loaderName: map['loaderName']?.toString() ?? '',
      haulerCap: double.tryParse(map['haulerCap'].toString()) ?? 0.0,
      haulerName: map['haulerName']?.toString() ?? '',
      speed: double.tryParse(map['speed'].toString()) ?? 0.0,
      loadingTime: double.tryParse(map['loadingTime'].toString()) ?? 0.0,
      spottingTime: double.tryParse(map['spottingTime'].toString()) ?? 0.0,
      dumpingTime: double.tryParse(map['dumpingTime'].toString()) ?? 0.0,
      cycleTime: double.tryParse(map['cycleTime'].toString()) ?? 0.0,
      recommendedHauler: int.tryParse(map['recommendedHauler'].toString()) ?? 0,
      matchFactor: double.tryParse(map['matchFactor'].toString()) ?? 0.0,
      status: map['status']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
    );
  }
}