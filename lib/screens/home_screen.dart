import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/calculation_model.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  CalculationModel? _lastCalculation;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null) {
      _lastCalculation =
          await _databaseService.getLastCalculation(_currentUser!['email']);
    }
    setState(() => _isLoading = false);
    _animController.forward(from: 0);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

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
      body: RefreshIndicator(
        color: const Color(0xFFB71C1C),
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom SliverAppBar with hero header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, size: 20),
                  ),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 60,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Image.asset(
                                  'assets/images/logo.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Halo, ${_currentUser?['name'] ?? 'User'} 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Fleet Calculator · AMM KPC-BGE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
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
            ),

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Action Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.calculate_rounded,
                              title: 'Kalkulasi',
                              subtitle: 'Hitung Match Factor',
                              gradientColors: [
                                const Color(0xFFB71C1C),
                                const Color(0xFFE53935),
                              ],
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CalculatorScreen()),
                                );
                                if (result == true) _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.history_rounded,
                              title: 'History',
                              subtitle: 'Lihat riwayat',
                              gradientColors: [
                                const Color(0xFF37474F),
                                const Color(0xFF546E7A),
                              ],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HistoryScreen()),
                                );
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Last Calculation Section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Hasil Kalkulasi Terakhir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: Color(0xFFB71C1C)),
                          ),
                        )
                      else if (_lastCalculation != null)
                        _buildLastCalculationCard(_lastCalculation!)
                      else
                        _buildEmptyState(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -15,
              right: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastCalculationCard(CalculationModel calc) {
    final statusColor = _getStatusColor(calc.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        calc.material == 'OB' ? 'Overburden' : 'Coal',
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDateTime(calc.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        'Cycle Time',
                        calc.cycleTime.toStringAsFixed(1),
                        'menit',
                        Icons.timer_rounded,
                        const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        'Rek. Hauler',
                        '${calc.recommendedHauler}',
                        'unit',
                        Icons.local_shipping_rounded,
                        const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        'Match Factor',
                        calc.matchFactor.toStringAsFixed(2),
                        '',
                        Icons.analytics_rounded,
                        const Color(0xFF00695C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: statusColor.withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getStatusIcon(calc.status),
                          color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        calc.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                          Icons.route_rounded,
                          '${calc.distance} KM',
                          'Jarak'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                          Icons.construction_rounded,
                          calc.loaderName.split(' ').take(2).join(' '),
                          'Loader'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                          Icons.local_shipping_outlined,
                          '${calc.actualHauler} Unit',
                          'Aktual'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                    text: ' $unit',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calculate_outlined,
                size: 42, color: Color(0xFFB71C1C)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Kalkulasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol Kalkulasi untuk\nmulai menghitung Match Factor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}