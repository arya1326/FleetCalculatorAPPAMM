// history_screen.dart - MODIFIKASI
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/calculation_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  List<CalculationModel> _calculations = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      _calculations = await _databaseService.getCalculations(currentUser['email']);
    }

    setState(() => _isLoading = false);
    _animationController.forward(from: 0);
  }

  // HAPUS method _clearHistory dan _deleteSingleCalculation

  Color _getStatusColor(String status) {
    if (status == 'UNDER TRUCK') return const Color(0xFFB71C1C);
    if (status == 'IDEAL MATCH') return const Color(0xFF2E7D32);
    return const Color(0xFFE65100);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'UNDER TRUCK') return Icons.arrow_downward_rounded;
    if (status == 'IDEAL MATCH') return Icons.check_circle_rounded;
    return Icons.arrow_upward_rounded;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (date == today) return 'Hari ini, $time';
    if (date == today.subtract(const Duration(days: 1))) return 'Kemarin, $time';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'History Kalkulasi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // HAPUS actions IconButton untuk clear history
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : _calculations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFB71C1C),
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _calculations.length,
                    itemBuilder: (context, index) {
                      final calc = _calculations[index];
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index / _calculations.length,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: _buildHistoryCard(calc, index),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 56,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lakukan kalkulasi Match Factor untuk\nmelihat riwayat perhitungan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.calculate_rounded, size: 20),
            label: const Text(
              'Mulai Kalkulasi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CalculationModel calc, int index) {
    final statusColor = _getStatusColor(calc.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      // HAPUS Dismissible
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        calc.material == 'OB'
                            ? Icons.terrain_rounded
                            : Icons.local_fire_department_rounded,
                        size: 14,
                        color: const Color(0xFFB71C1C),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        calc.material == 'OB' ? 'Overburden' : 'Coal',
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(calc.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildResultTile(
                        'Cycle Time',
                        calc.cycleTime.toStringAsFixed(1),
                        'menit',
                        Icons.timer_rounded,
                        const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultTile(
                        'Rek. Hauler',
                        '${calc.recommendedHauler}',
                        'unit',
                        Icons.local_shipping_rounded,
                        const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultTile(
                        'Match Factor',
                        calc.matchFactor.toStringAsFixed(1), // 1 digit after comma
                        '',
                        Icons.analytics_rounded,
                        statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getStatusIcon(calc.status),
                          color: statusColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        calc.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Additional info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildInfoItem(
                            'Loader',
                            calc.loaderName,
                            Icons.construction_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoItem(
                            'Hauler',
                            calc.haulerName,
                            Icons.local_shipping_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoItem(
                            'Jarak',
                            '${calc.distance} KM',
                            Icons.route_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoItem(
                            'Speed',
                            '${calc.speed} Km/jam',
                            Icons.speed_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoItem(
                            'Aktual vs Rek',
                            '${calc.actualHauler} / ${calc.recommendedHauler} unit',
                            Icons.compare_arrows_rounded,
                          ),
                        ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: '\n$unit',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFFB71C1C)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}