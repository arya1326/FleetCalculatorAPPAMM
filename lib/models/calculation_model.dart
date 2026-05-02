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
      material: map['material'],
      distance: map['distance'],
      actualHauler: map['actualHauler'],
      loaderProd: map['loaderProd'],
      loaderName: map['loaderName'],
      haulerCap: map['haulerCap'],
      haulerName: map['haulerName'],
      speed: map['speed'],
      loadingTime: map['loadingTime'],
      dumpingTime: map['dumpingTime'],
      cycleTime: map['cycleTime'],
      recommendedHauler: map['recommendedHauler'],
      matchFactor: map['matchFactor'],
      status: map['status'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}