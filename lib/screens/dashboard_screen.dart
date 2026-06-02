import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/task_service.dart';
import 'login_screen.dart';
import 'task_screen.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _username = 'Fauzi';
  List _tasks = [];
  bool _loadingTasks = true;

  static const _pink = Color(0xFFE91E8C);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTasks();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('name') ?? 'Fauzi';
    });
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskService().getTasks();
      if (mounted) setState(() { _tasks = tasks; _loadingTasks = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingTasks = false; });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDashboardBody()
            : _buildPlaceholder(_navLabels[_selectedIndex]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (result == true) _loadTasks();
        },
        backgroundColor: _pink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildGreeting(),
          const SizedBox(height: 20),
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Tugas Terdekat', 'Lihat Semua'),
          const SizedBox(height: 12),
          _buildTaskList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        
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
        Stack(
          children: [
            const Icon(Icons.notifications_outlined,
                color: Color(0xFF333333), size: 26),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE91E8C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _logout,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF5C5C5C),
            child: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/36?img=12',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── GREETING ──────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final nearDeadline = _tasks.isEmpty ? 3 : _tasks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            children: [
              const TextSpan(text: 'Halo, '),
              TextSpan(
                text: '$_username!',
                style: const TextStyle(color: Color(0xFFE91E8C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _loadingTasks
              ? 'Memuat tugas...'
              : 'Kamu punya $nearDeadline tugas penting minggu ini.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
      ],
    );
  }

  // ── PROGRESS SECTION ──────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Mingguan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 14),
        _buildProgressCard(),
      ],
    );
  }

  Widget _buildProgressCard() {
    final total = _tasks.isEmpty ? 15 : _tasks.length;
    final done = _tasks.isEmpty ? 12 : (_tasks.length * 0.8).round();
    final pct = total == 0 ? 0.0 : done / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: label + count + trend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENYELESAIAN TUGAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$done',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E8C),
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ $total',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Lebih baik dari minggu lalu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side: circle progress — give it generous padding so arc is never clipped
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildCircularProgress(pct),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double pct) {
    const double size = 90;
    return SizedBox(
      width: size,
      height: size,
      // OverflowBox ensures the CustomPaint is never clipped by its parent
      child: OverflowBox(
        maxWidth: size,
        maxHeight: size,
        child: CustomPaint(
          size: const Size(size, size),
          painter: _CircleProgressPainter(progress: pct),
          child: Center(
            child: Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFE91E8C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── TASK LIST ─────────────────────────────────────────────────────────────

  Widget _buildTaskList() {
    if (_loadingTasks) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
      );
    }

    final displayTasks = _tasks.isNotEmpty
        ? _tasks.take(3).toList()
        : _dummyTasks;

    return Column(
      children: List.generate(displayTasks.length, (i) {
        final task = displayTasks[i];
        final isFirst = i == 0;
        final isDone = task['status'] == 'done' ||
            (task['status'] == null && i == 2);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: isFirst
              ? _buildHighlightTaskCard(task)
              : _buildNormalTaskCard(task, isDone: isDone),
        );
      }),
    );
  }

  // Card menonjol (pertama) — pink border
  Widget _buildHighlightTaskCard(Map task) {
    final tags = _parseTags(task['tags']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox circle (empty)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDDDDDD),
                    width: 2,
                  ),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task['deadline'] ?? 'Besok, 08:00',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE91E8C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Color(0xFF999999), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task['title'] ?? 'Tugas',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (task['description'] != null && task['description'] != '') ...[
            const SizedBox(height: 4),
            Text(
              task['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags
                .map((tag) => _buildTag(
                      tag['label'],
                      icon: tag['icon'],
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Progress bar at bottom of card
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 5,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE91E8C)),
            ),
          ),
        ],
      ),
    );
  }

  // Card normal (kedua dan ketiga)
  Widget _buildNormalTaskCard(Map task, {bool isDone = false}) {
    // Parse subject/category from deadline string for display
    final String deadlineRaw = task['deadline'] ?? '';
    // Try to detect if there's a subject in extra field
    final String? subject = task['subject'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? const Color(0xFFE91E8C)
                    : const Color(0xFFDDDDDD),
                width: 2,
              ),
              color: isDone ? const Color(0xFFE91E8C) : Colors.transparent,
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? 'Tugas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF1A1A1A),
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      deadlineRaw,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDone
                            ? const Color(0xFFBBBBBB)
                            : const Color(0xFF999999),
                      ),
                    ),
                    if (subject != null && subject.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCCCCCC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: const Color(0xFF555555)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  static const _navLabels = ['Dashboard', 'Tasks', 'Calendar', 'Social'];
  static const _navIcons = [
    Icons.dashboard_rounded,
    Icons.check_box_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
  ];

  Widget _buildBottomNav() {
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
              if (i == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskScreen()),
                );
              } else if (i == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              } else {
                setState(() => _selectedIndex = i);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _navIcons[i],
                    size: 22,
                    color: selected
                        ? const Color(0xFFE91E8C)
                        : const Color(0xFFBBBBBB),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _navLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected
                          ? const Color(0xFFE91E8C)
                          : const Color(0xFFBBBBBB),
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

  // ── DRAWER SHEET ──────────────────────────────────────────────────────────

  Widget _buildDrawerSheet() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.check_box_outlined, 'Tugas Saya', () => Navigator.pop(context)),
          _drawerItem(Icons.calendar_month_outlined, 'Kalender', () => Navigator.pop(context)),
          _drawerItem(Icons.settings_outlined, 'Pengaturan', () => Navigator.pop(context)),
          const Divider(),
          _drawerItem(Icons.logout, 'Keluar', () {
            Navigator.pop(context);
            _logout();
          }, color: const Color(0xFFE91E8C)),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? const Color(0xFF444444);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 15, color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ── PLACEHOLDER ───────────────────────────────────────────────────────────

  Widget _buildPlaceholder(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('$label\n(coming soon)',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseTags(dynamic raw) {
    if (raw == null) {
      return [
        {'label': 'Teknik Informatika', 'icon': null},
        {'label': 'Kelompok', 'icon': Icons.people_outline},
      ];
    }
    if (raw is List) {
      return raw
          .map<Map<String, dynamic>>((t) => {'label': t.toString(), 'icon': null})
          .toList();
    }
    return [{'label': raw.toString(), 'icon': null}];
  }

  // Dummy tasks saat API belum tersedia
  static final _dummyTasks = [
    {
      'title': 'Komputasi Awan',
      'deadline': 'Besok, 08:00',
      'status': 'pending',
    },
    {
      'title': 'Mobile Programming Lanjut',
      'deadline': 'Jum, 23:59',
      'status': 'pending',
    },
    {
      'title': 'Review Jurnal',
      'deadline': 'Selesai hari ini, 10:00',
      'subject': 'Metodologi Penelitian',
      'status': 'done',
    },
  ];
}

// ── CUSTOM PAINTER ────────────────────────────────────────────────────────────

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    // Shrink radius so the full stroke width fits inside the canvas bounds
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);
    final center = Offset(size.width / 2, size.height / 2);

    // ── Track (grey full circle) ──────────────────────────────────────────
    final trackPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // ── Progress arc (pink, dashed segments like the reference) ──────────
    // We draw two visible arcs with a small gap to simulate the dashed look
    // seen in the reference image.
    const startAngle = -pi / 2; // start from top
    final sweepAngle = 2 * pi * progress;

    // Gap size in radians (fixed, ~8°)
    const gapRad = 0.14;

    // Split the progress arc into two segments with a small visual gap
    final halfSweep = sweepAngle / 2;

    final arcPaint = Paint()
      ..color = const Color(0xFFE91E8C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    if (sweepAngle <= gapRad * 2) {
      // Too small for gaps — just draw as one arc
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    } else {
      // First segment
      canvas.drawArc(rect, startAngle, halfSweep - gapRad / 2, false, arcPaint);
      // Second segment
      canvas.drawArc(
        rect,
        startAngle + halfSweep + gapRad / 2,
        halfSweep - gapRad / 2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}
