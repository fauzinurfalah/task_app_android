import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const _pink = Color(0xFFE91E8C);

  List _apiTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskService().getTasks();
      if (mounted) setState(() { _apiTasks = tasks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  static final _upcoming = [
    {
      'title': 'Implementasi REST API dengan Laravel',
      'deadline': 'Besok, 08:00',
      'description': 'Buat endpoint CRUD untuk manajemen data mahasiswa.',
      'subject': 'Pemrograman Web',
      'type': 'Kelompok',
      'progress': 0.6,
    },
    {
      'title': 'Laporan Praktikum Jaringan Komputer',
      'deadline': 'Jum, 23:59',
      'description': 'Konfigurasi VLAN dan routing statis pada Cisco Packet Tracer.',
      'subject': 'Jaringan Komputer',
      'type': 'Individu',
      'progress': 0.35,
    },
  ];

  static final _others = [
    {
      'title': 'Klasifikasi Gambar dengan CNN',
      'deadline': 'Senin, 19:00',
      'description': 'Implementasi model CNN menggunakan TensorFlow untuk klasifikasi dataset CIFAR-10.',
      'subject': 'Kecerdasan Buatan',
      'type': 'Kelompok',
      'progress': 0.5,
    },
    {
      'title': 'Desain ERD Sistem Informasi Akademik',
      'deadline': 'Rabu, 23:59',
      'description': 'Rancang skema basis data dan normalisasi hingga 3NF.',
      'subject': 'Basis Data',
      'type': 'Individu',
      'progress': 0.25,
    },
    {
      'title': 'Analisis Algoritma Sorting',
      'deadline': 'Kamis, 15:00',
      'description': 'Bandingkan kompleksitas waktu QuickSort, MergeSort, dan HeapSort.',
      'subject': 'Algoritma & Struktur Data',
      'type': 'Individu',
      'progress': 0.15,
    },
  ];

  static final _done = [
    {
      'title': 'Desain UI Aplikasi Mobile SIAKAD',
      'deadline': 'Selesai hari ini, 10:00',
    },
    {
      'title': 'Setup Lingkungan Docker untuk Microservices',
      'deadline': 'Selesai kemarin, 14:00',
    },
    {
      'title': 'Makalah Keamanan Informasi – Enkripsi AES',
      'deadline': 'Selesai minggu lalu',
    },
  ];

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
          CircleAvatar(
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
        ],
      ),
    );
  }

  // ── Scrollable Body ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    // Use API data if available, else use dummy
    final upcomingData = _apiTasks.isNotEmpty
        ? _apiTasks
            .where((t) => t['status'] != 'done')
            .take(2)
            .map((t) => {
                  'title': t['title'] ?? '',
                  'deadline': t['deadline'] ?? '',
                  'description': t['description'] ?? '',
                  'subject': t['subject'] ?? 'Mata Kuliah',
                  'type': 'Individu',
                  'progress': 0.4,
                })
            .toList()
        : _upcoming;

    final doneData = _apiTasks.isNotEmpty
        ? _apiTasks
            .where((t) => t['status'] == 'done')
            .map((t) => {
                  'title': t['title'] ?? '',
                  'deadline': t['deadline'] ?? '',
                })
            .toList()
        : _done;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tugas Terdekat'),
          const SizedBox(height: 12),
          ...upcomingData.map((t) => _buildPendingCard(t)).toList(),
          const SizedBox(height: 20),
          _buildSectionHeader('Tugas Lainnya'),
          const SizedBox(height: 12),
          ..._others.map((t) => _buildPendingCard(t)).toList(),
          const SizedBox(height: 20),
          _buildSectionHeader('Tugas Selesai'),
          const SizedBox(height: 12),
          _buildDoneSection(doneData),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
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
    final double progress = (task['progress'] as num?)?.toDouble() ?? 0.4;
    final String subject = task['subject']?.toString() ?? '';
    final String type = task['type']?.toString() ?? 'Individu';
    final bool isGroup = type.toLowerCase().contains('kelompok');

    return Padding(
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
                      task['deadline']?.toString() ?? '',
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
                task['title']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              // Description
              if ((task['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task['description'].toString(),
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
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: doneList.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          final isLast = i == doneList.length - 1;
          return Column(
            children: [
              _buildDoneItem(task),
              if (!isLast)
                const Divider(height: 1, indent: 20, endIndent: 20,
                    color: Color(0xFFF2F2F2)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDoneItem(Map task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: _pink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFAAAAAA),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task['deadline']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                Navigator.pop(context);
              } else if (i == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
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