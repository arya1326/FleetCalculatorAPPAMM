import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/calculation_model.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  String _selectedMaterial = 'OB';
  final TextEditingController _distanceController =
      TextEditingController(text: '2');
  final TextEditingController _actualHaulerController =
      TextEditingController(text: '5');
  
  // FIXED VALUES - OVERBURDEN
  static const double obLoadingTime = 3.9;
  static const double obSpeed = 20;
  static const double obSpottingTime = 0.5;  // Spotting time
  static const double obDumpingTime = 1.0;    // Dumping time (1 menit)
  
  // FIXED VALUES - COAL
  static const double coalLoadingTime = 1.5;
  static const double coalSpeed = 20;
  static const double coalSpottingTime = 0.6; // Spotting time
  static const double coalDumpingTime = 1.0;   // Dumping time (1 menit)

  final Map<String, double> _obLoaderOptions = {
    'PC200 (100 BCM/Jam)': 100,
    'PC500 (200 BCM/Jam)': 200,
    'PC1250 (470 BCM/Jam)': 470,
  };
  final Map<String, double> _obHaulerOptions = {
    'HD785-7 (43 BCM)': 43,
    'AROCS 4042K (10 BCM)': 10,
  };
  final Map<String, double> _coalLoaderOptions = {
    'PC200 (193 Ton/Jam)': 193,
    'PC500 (283 Ton/Jam)': 283,
  };
  final Map<String, double> _coalHaulerOptions = {
    'AROCS 4845K (37 TON)': 37,
  };

  String _selectedLoader = '';
  String _selectedHauler = '';
  double _loaderProd = 0;
  double _haulerCap = 0;

  double? _cycleTime;
  int? _recommendedHauler;
  double? _matchFactor;
  String? _status;
  bool _isCalculated = false;
  bool _hasNewCalculation = false; // Flag untuk tracking apakah ada perhitungan baru

  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnim;
  late Animation<double> _resultFadeAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOutBack));
    _resultFadeAnim = CurvedAnimation(
        parent: _resultAnimController, curve: Curves.easeOut);
    _updateOptions();
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    _distanceController.dispose();
    _actualHaulerController.dispose();
    super.dispose();
  }

  void _updateOptions() {
    setState(() {
      if (_selectedMaterial == 'OB') {
        _selectedLoader = _obLoaderOptions.keys.first;
        _selectedHauler = _obHaulerOptions.keys.first;
        _loaderProd = _obLoaderOptions[_selectedLoader]!;
        _haulerCap = _obHaulerOptions[_selectedHauler]!;
      } else {
        _selectedLoader = _coalLoaderOptions.keys.first;
        _selectedHauler = _coalHaulerOptions.keys.first;
        _loaderProd = _coalLoaderOptions[_selectedLoader]!;
        _haulerCap = _coalHaulerOptions[_selectedHauler]!;
      }
    });
  }

  void _onLoaderChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLoader = value;
        _loaderProd = (_selectedMaterial == 'OB'
            ? _obLoaderOptions
            : _coalLoaderOptions)[value]!;
      });
    }
  }

  void _onHaulerChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedHauler = value;
        _haulerCap = (_selectedMaterial == 'OB'
            ? _obHaulerOptions
            : _coalHaulerOptions)[value]!;
      });
    }
  }

  double _getLoadingTime() {
    return _selectedMaterial == 'OB' ? obLoadingTime : coalLoadingTime;
  }

  double _getSpeed() {
    return _selectedMaterial == 'OB' ? obSpeed : coalSpeed;
  }

  double _getSpottingTime() {
    return _selectedMaterial == 'OB' ? obSpottingTime : coalSpottingTime;
  }

  double _getDumpingTime() {
    return _selectedMaterial == 'OB' ? obDumpingTime : coalDumpingTime;
  }

  double _getEffectiveLoaderProd() {
  // LANGSUNG return loaderProd (tanpa * 0.9)
    return _loaderProd;
  }

Future<void> _calculateAndSave() async {
  final distance = double.tryParse(_distanceController.text) ?? 0;
  final actualHauler = int.tryParse(_actualHaulerController.text) ?? 0;

  if (distance <= 0 || actualHauler <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Harap isi semua nilai dengan benar'),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }

  final loadingTime = _getLoadingTime();
  final loadingSpeed = 19.0;  // Loading speed = 19 km/jam
  final emptySpeed = 20.0;    // Empty speed = 20 km/jam
  final spottingTime = _getSpottingTime();
  final dumpingTime = _getDumpingTime();
  final loaderProd = _getEffectiveLoaderProd();  // LANGSUNG tanpa * 0.9

  // PERHITUNGAN TRAVEL TIME (dalam menit)
  // Travel time loading = distance / loadingSpeed * 60
  // Travel time empty = distance / emptySpeed * 60
  final travelTimeLoading = (distance / loadingSpeed) * 60;
  final travelTimeEmpty = (distance / emptySpeed) * 60;
  
  // CT = Travel Time Loading + Travel Time Empty + (Spotting Time x 2) + Loading Time + Dumping Time
  final cycleTime = travelTimeLoading + travelTimeEmpty + (spottingTime * 2) + loadingTime + dumpingTime;
  
  // Recommended Hauler = loaderProd / (haulerCap / cycleTime * 60)
  // Atau: loaderProd * cycleTime / (haulerCap * 60)
  final recommended = (loaderProd * cycleTime / (_haulerCap * 60)).ceil();
  
  // Match Factor = (actualHauler * haulerCap * 60) / (loaderProd * cycleTime)
  final matchFactorRaw = (actualHauler * _haulerCap * 60) / (loaderProd * cycleTime);
  // Bulatkan ke 1 digit di belakang koma
  final matchFactor = double.parse(matchFactorRaw.toStringAsFixed(1));

  // STATUS berdasarkan perbandingan actual vs recommended
  String status;
  if (actualHauler < recommended) {
    status = 'UNDER TRUCK';
  } else if (actualHauler == recommended) {
    status = 'IDEAL MATCH';
  } else {
    status = 'OVER TRUCK';
  }

  setState(() {
    _cycleTime = cycleTime;
    _recommendedHauler = recommended;
    _matchFactor = matchFactor;
    _status = status;
    _isCalculated = true;
    _hasNewCalculation = true;
  });

  _resultAnimController.forward(from: 0);

  final currentUser = await _authService.getCurrentUser();
  if (currentUser != null) {
    final calculation = CalculationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      material: _selectedMaterial,
      distance: distance,
      actualHauler: actualHauler,
      loaderProd: loaderProd,  // LANGSUNG tanpa * 0.9
      loaderName: _selectedLoader,
      haulerCap: _haulerCap,
      haulerName: _selectedHauler,
      speed: emptySpeed,  // Simpan empty speed sebagai reference
      loadingTime: loadingTime,
      spottingTime: spottingTime,
      dumpingTime: dumpingTime,
      cycleTime: cycleTime,
      recommendedHauler: recommended,
      matchFactor: matchFactor,
      status: status,
      timestamp: DateTime.now(),
    );
    await _databaseService.saveCalculation(calculation, currentUser['email']);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Perhitungan berhasil disimpan'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

  Color _getStatusColor() {
    if (_status == 'UNDER TRUCK') return const Color(0xFFB71C1C);
    if (_status == 'IDEAL MATCH') return const Color(0xFF2E7D32);
    return const Color(0xFFE65100);
  }

  IconData _getStatusIcon() {
    if (_status == 'UNDER TRUCK') return Icons.arrow_downward_rounded;
    if (_status == 'IDEAL MATCH') return Icons.check_circle_rounded;
    return Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kembalikan nilai true ke halaman sebelumnya jika ada perhitungan baru
        Navigator.pop(context, _hasNewCalculation);
        return false; // Mencegah pop default karena kita sudah handle sendiri
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Fleet Calculator',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFB71C1C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              // Kembali ke home dengan signal refresh jika ada perhitungan baru
              Navigator.pop(context, _hasNewCalculation);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Material toggle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: ['OB', 'COAL'].map((material) {
                    final isSelected = _selectedMaterial == material;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMaterial = material;
                            _updateOptions();
                            _isCalculated = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFB71C1C)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                material == 'OB'
                                    ? Icons.terrain_rounded
                                    : Icons.local_fire_department_rounded,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                material == 'OB' ? 'Overburden' : 'Coal',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Operational Parameters
              _buildSection(
                title: 'Parameter Operasional',
                icon: Icons.tune_rounded,
                children: [
                  _buildTextField(
                    controller: _distanceController,
                    label: 'Jarak Hauling',
                    suffix: 'KM',
                    icon: Icons.route_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _actualHaulerController,
                    label: 'Jumlah Hauler Aktual',
                    suffix: 'Unit',
                    icon: Icons.local_shipping_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Loader Parameter
              _buildSection(
                title: 'Parameter Loader',
                icon: Icons.construction_rounded,
                children: [
                  _buildDropdown(
                    label: 'Plan Productivity Loader',
                    value: _selectedLoader,
                    items: (_selectedMaterial == 'OB'
                            ? _obLoaderOptions
                            : _coalLoaderOptions)
                        .keys
                        .toList(),
                    onChanged: _onLoaderChanged,
                    icon: Icons.precision_manufacturing_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hauler Parameter
              _buildSection(
                title: 'Parameter Hauler',
                icon: Icons.local_shipping_rounded,
                children: [
                  _buildDropdown(
                    label: 'Plan Capacity Vessel Hauler',
                    value: _selectedHauler,
                    items: (_selectedMaterial == 'OB'
                            ? _obHaulerOptions
                            : _coalHaulerOptions)
                        .keys
                        .toList(),
                    onChanged: _onHaulerChanged,
                    icon: Icons.inventory_2_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Panel for Fixed Values
            Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: const Color(0xFFB71C1C)),
                                const SizedBox(width: 8),
                                Text(
                                  'Parameter Tetap',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(0xFFB71C1C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_selectedMaterial == 'OB') ...[
                              _buildFixedParam('Loading Time', '3.9 menit'),
                              _buildFixedParam('Loading Speed', '19 Km/jam'),
                              _buildFixedParam('Empty Speed', '20 Km/jam'),
                              _buildFixedParam('Spotting (2x)', '0.5 menit x 2 = 1.0 menit'),
                              _buildFixedParam('Dumping', '1.0 menit'),
                              _buildFixedParam('Total Spotting+Dumping', '2.0 menit'),
                              _buildFixedParam('Efisiensi Loader', '90%'),  // TETAP DITAMPILKAN
                            ] else ...[
                              _buildFixedParam('Loading Time', '1.5 menit'),
                              _buildFixedParam('Loading Speed', '19 Km/jam'),
                              _buildFixedParam('Empty Speed', '20 Km/jam'),
                              _buildFixedParam('Spotting (2x)', '0.6 menit x 2 = 1.2 menit'),
                              _buildFixedParam('Dumping', '1.0 menit'),
                              _buildFixedParam('Total Spotting+Dumping', '2.2 menit'),
                              _buildFixedParam('Efisiensi Loader', '90%'),  // TETAP DITAMPILKAN
                            ],
                          ],
                        ),
                      ),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _calculateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: const Color(0xFFB71C1C).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'HITUNG MATCH FACTOR',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Result
              if (_isCalculated && _cycleTime != null)
                ScaleTransition(
                  scale: _resultScaleAnim,
                  child: FadeTransition(
                    opacity: _resultFadeAnim,
                    child: _buildResultCard(),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedParam(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFFB71C1C)),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 15),
      onChanged: (_) => setState(() => _isCalculated = false),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFB71C1C), size: 18),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFB71C1C), size: 18),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildResultCard() {
    final statusColor = _getStatusColor();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.8)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'HASIL KALKULASI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _status!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildResultTile(
                        'Cycle Time',
                        _cycleTime!.toStringAsFixed(2),
                        'menit',
                        Icons.timer_rounded,
                        const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultTile(
                        'Rek. Hauler',
                        '$_recommendedHauler',
                        'unit',
                        Icons.local_shipping_rounded,
                        const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultTile(
                        'Match Factor',
                        _matchFactor!.toStringAsFixed(1),
                        '',
                        Icons.analytics_rounded,
                        statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: statusColor.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(), color: statusColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _status!,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _status == 'UNDER TRUCK'
                                  ? 'Jumlah hauler kurang dari optimal'
                                  : _status == 'IDEAL MATCH'
                                      ? 'Jumlah hauler sudah optimal'
                                      : 'Jumlah hauler melebihi kebutuhan',
                              style: TextStyle(
                                color: statusColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: '\n$unit',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}