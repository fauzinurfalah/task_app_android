import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';
import 'join_task_helper.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const _pink = Color(0xFFE91E8C);

  List _apiTasks = [];
  bool _loading = true;
  String _role = 'mahasiswa';
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _userService.loadUser();
    _loadTasks();
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role') ?? 'mahasiswa';
      final tasks = await TaskService().getTasks();
      if (mounted) setState(() { _role = role; _apiTasks = tasks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _showJoinTaskDialog() {
    JoinTaskHelper.show(context, onSuccess: _loadTasks);
  }

  // ── Data ────────────────────────────────────────────────────────────────────


  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _pink),
                    )
                  : _buildBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _role == 'dosen' ? FloatingActionButton(
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
      ) : FloatingActionButton.extended(
        onPressed: _showJoinTaskDialog,
        backgroundColor: _pink,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('Join Task', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 26), // balance right side
          const Expanded(
            child: Center(
              child: Text(
                'Tetugas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _pink,
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
                    color: _pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Builder(builder: (ctx) {
              final photoUrl = _userService.photoUrl;
              return CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF5C5C5C),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Scrollable Body ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    final now = DateTime.now();

    List<Map<String, dynamic>> activeTasks = [];
    List<Map<String, dynamic>> doneTasks = [];

    for (var t in _apiTasks) {
      final deadlineStr = t['deadline']?.toString() ?? '';
      final jamStr = t['jam']?.toString() ?? '23:59:00';
      DateTime deadlineDT = now.add(const Duration(days: 365));
      if (deadlineStr.isNotEmpty) {
        try {
          deadlineDT = DateTime.parse("$deadlineStr $jamStr");
        } catch (_) {}
      }

      final status = t['status']?.toString() ?? 'pending';
      final isPastDeadline = now.isAfter(deadlineDT);

      if (status == 'submitted' || status == 'late' || status == 'graded' || (status == 'pending' && isPastDeadline)) {
        doneTasks.add(Map<String, dynamic>.from(t));
      } else {
        activeTasks.add(Map<String, dynamic>.from(t));
      }
    }

    activeTasks.sort((a, b) {
      final dtA = DateTime.tryParse("${a['deadline']} ${a['jam'] ?? '23:59:00'}") ?? now.add(const Duration(days: 365));
      final dtB = DateTime.tryParse("${b['deadline']} ${b['jam'] ?? '23:59:00'}") ?? now.add(const Duration(days: 365));
      return dtA.compareTo(dtB);
    });

    doneTasks.sort((a, b) {
      final dtA = DateTime.tryParse("${a['deadline']} ${a['jam'] ?? '23:59:00'}") ?? now;
      final dtB = DateTime.tryParse("${b['deadline']} ${b['jam'] ?? '23:59:00'}") ?? now;
      return dtB.compareTo(dtA);
    });

    final showActiveLihatSemua = activeTasks.length > 5;
    final activeData = activeTasks.take(5).toList();

    final showDoneLihatSemua = doneTasks.length > 10;
    final doneData = doneTasks.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tugas Aktif', showLihatSemua: showActiveLihatSemua),
          const SizedBox(height: 12),
          if (activeData.isEmpty)
             const Text('Tidak ada tugas aktif.', style: TextStyle(color: Colors.grey)),
          ...activeData.map((t) => _buildPendingCard(t)),
          const SizedBox(height: 20),
          _buildSectionHeader('Tugas Selesai / Ditutup', showLihatSemua: showDoneLihatSemua),
          const SizedBox(height: 12),
          if (doneData.isEmpty)
             const Text('Belum ada tugas selesai.', style: TextStyle(color: Colors.grey)),
          if (doneData.isNotEmpty) _buildDoneSection(doneData),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {bool showLihatSemua = false}) {
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
        if (showLihatSemua)
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 13,
                color: _pink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ── Pending Task Card ────────────────────────────────────────────────────────

  Widget _buildPendingCard(Map task) {
    final double progress = 0.0;
    final String subject = task['nama_matkul']?.toString() ?? task['subject']?.toString() ?? '';
    final String type = task['tipe']?.toString() ?? task['type']?.toString() ?? 'Individu';
    final bool isGroup = type.toLowerCase().contains('kelompok');

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: Map<String, dynamic>.from(task))),
        );
        if (result == true) _loadTasks();
      },
      child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: _pink.withValues(alpha: 0.7), width: 3.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: checkbox + deadline badge + 3-dot
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pink.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${task['deadline']?.toString() ?? ''} ${task['jam'] != null ? task['jam'].toString().substring(0, 5) : ''}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: _pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz,
                      color: Color(0xFF999999), size: 20),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                task['nama_tugas']?.toString() ?? task['title']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              // Description
              if ((task['deskripsi'] ?? task['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  (task['deskripsi'] ?? task['description']).toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
              const SizedBox(height: 10),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (subject.isNotEmpty) _buildSubjectTag(subject),
                  _buildTypeTag(type, isGroup: isGroup),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              if (_role == 'mahasiswa')
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_pink),
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildSubjectTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF555555),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeTag(String label, {bool isGroup = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGroup ? Icons.people_outline : Icons.person_outline,
            size: 12,
            color: const Color(0xFF555555),
          ),
          const SizedBox(width: 4),
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

  // ── Done Section ─────────────────────────────────────────────────────────────

  Widget _buildDoneSection(List doneList) {
    return Column(
      children: doneList.map((task) => _buildDoneItem(task)).toList(),
    );
  }

  Widget _buildDoneItem(Map task) {
    bool isDone = task['status'] == 'submitted' || task['status'] == 'graded' || task['status'] == 'done';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: Map<String, dynamic>.from(task))),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _pink.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone ? _pink.withValues(alpha: 0.8) : Colors.black87,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : Icons.close, 
                color: Colors.white, 
                size: 18
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['nama_tugas']?.toString() ?? task['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAAAAAA),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${task['deadline']?.toString() ?? ''} ${task['jam'] != null ? task['jam'].toString().substring(0, 5) : ''}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
                    ),
                    Text(
                      'Nilai',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────────

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
          // Tasks tab (index 1) is always selected on this screen
          final selected = i == 1;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              } else if (i == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              } else if (i == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SocialScreen()),
                );
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
                    color: selected ? _pink : const Color(0xFFBBBBBB),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _navLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? _pink : const Color(0xFFBBBBBB),
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
