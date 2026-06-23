import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'account_settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;
  Map<String, dynamic>? _stats;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _userService.loadUser();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await TaskService().getDashboardStats();
      if (mounted) setState(() { _stats = stats; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 30),
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildTotalTasksCard(),
              const SizedBox(height: 16),
              _buildProgressCard(),
              const SizedBox(height: 30),
              _buildSettingsSection(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 74),
        const Expanded(
          child: Center(
            child: Text(
              'Tetugas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E8C),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const Icon(Icons.notifications_outlined, color: Color(0xFF333333), size: 26),
        const SizedBox(width: 12),
        _buildAvatarWidget(radius: 18),
      ],
    );
  }

  // ── AVATAR (reusable) ─────────────────────────────────────────────────────

  Widget _buildAvatarWidget({double radius = 18}) {
    final photoUrl = _userService.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF5C5C5C),
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
          ? NetworkImage(photoUrl)
          : null,
      child: (photoUrl == null || photoUrl.isEmpty)
          ? Icon(Icons.person, color: Colors.white, size: radius)
          : null,
    );
  }

  // ── PROFILE HEADER ────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final photoUrl = _userService.photoUrl;
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFCE4EC), width: 4),
          ),
          child: _buildAvatarWidget(radius: 46),
        ),
        const SizedBox(height: 16),
        Text(
          _userService.name.isNotEmpty ? _userService.name : 'Loading...',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'COMPUTER SCIENCE STUDENT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF888888),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final done = _stats?['tugas_selesai']?.toString() ?? '0';
    final pending = _stats?['tugas_aktif']?.toString() ?? '0';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            iconBgColor: const Color(0xFFFFEBF2),
            iconColor: const Color(0xFFE91E8C),
            value: done,
            valueColor: const Color(0xFFE91E8C),
            label: 'Tugas Selesai',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_late_outlined,
            iconBgColor: const Color(0xFFFFF0F0),
            iconColor: const Color(0xFFEF5350),
            value: pending,
            valueColor: const Color(0xFF1A1A1A),
            label: 'Tugas Tertunda',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTasksCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFEFEFEF), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long, color: Color(0xFF666666), size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Total Tugas Semester Ini',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ),
          Text(
            _stats?['total_tugas']?.toString() ?? '0',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progNum = (_stats?['progress'] as num?)?.toDouble() ?? 0.0;
    final progStr = '${progNum.toInt()}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Semester',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              Text(
                progStr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE91E8C)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progNum / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E8C)),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Mendekati Ujian Akhir',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF777777)),
            ),
          ),
        ],
      ),
    );
  }

  // ── SETTINGS ──────────────────────────────────────────────────────────────

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PENGATURAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF999999),
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildSettingItem(
          icon: Icons.person_outline,
          title: 'Akun',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItem(icon: Icons.notifications_none, title: 'Notifikasi', onTap: () {}),
        const SizedBox(height: 12),
        _buildSettingItem(icon: Icons.palette_outlined, title: 'Tema', onTap: () {}),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF5350),
              side: const BorderSide(color: Color(0xFFEF5350)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'KELUAR',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF2F2F2), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: const Color(0xFF444444)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 22),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  static const _navLabels = ['Dashboard', 'Tasks', 'Calendar', 'Profile'];
  static const _navIcons = [
    Icons.dashboard_rounded,
    Icons.check_box_outlined,
    Icons.calendar_month_outlined,
    Icons.person_outline,
  ];

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navLabels.length, (i) {
          final selected = _selectedIndex == i;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
              } else if (i == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TaskScreen()));
              } else if (i == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CalendarScreen()));
              } else if (i == 3) {
                // already here
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_navIcons[i], size: 22,
                      color: selected ? const Color(0xFFE91E8C) : const Color(0xFFBBBBBB)),
                  const SizedBox(height: 3),
                  Text(
                    _navLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? const Color(0xFFE91E8C) : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
