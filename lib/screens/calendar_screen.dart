import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import 'dashboard_screen.dart';
import 'task_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import 'join_task_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _pink = Color(0xFFE91E8C);

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// events dari API: { 'yyyy-MM-dd': [ {...task}, ... ] }
  Map<String, List<Map<String, dynamic>>> _events = {};
  bool _loading = true;
  String? _error;

  final _userService = UserService();
  final _taskService = TaskService();

  // ── Warna berdasarkan prioritas ──────────────────────────────────────────────
  static const _colorByPrioritas = {
    'tinggi' : Color(0xFFEF4444),
    'sedang'  : Color(0xFFF59E0B),
    'rendah'  : Color(0xFF10B981),
  };

  // ── Warna berdasarkan status submission (mahasiswa) ──────────────────────────
  static const _colorBySubStatus = {
    'submitted' : Color(0xFF10B981),
    'graded'    : Color(0xFF6366F1),
    'late'      : Color(0xFFEF4444),
    'pending'   : Color(0xFFF59E0B),
  };

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _userService.loadUser();
    _loadCalendar();
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  // ── Load kalender dari endpoint baru /calendar ────────────────────────────────
  Future<void> _loadCalendar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _taskService.getCalendarEvents(
        month: _focusedMonth.month,
        year: _focusedMonth.year,
      );

      final rawEvents = data['events'] as Map<String, dynamic>? ?? {};
      final Map<String, List<Map<String, dynamic>>> parsed = {};

      rawEvents.forEach((dateKey, tasks) {
        if (tasks is List) {
          parsed[dateKey] = tasks
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      });

      if (mounted) {
        setState(() {
          _events = parsed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat kalender';
        });
      }
    }
  }

  // ── Navigasi bulan ────────────────────────────────────────────────────────────
  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadCalendar();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadCalendar();
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _selectedEvents =>
      _events[_key(_selectedDay)] ?? [];

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                color: _pink,
                onRefresh: _loadCalendar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildCalendarCard(),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: _pink),
                          ),
                        )
                      else if (_error != null)
                        _buildErrorState()
                      else
                        _buildScheduleSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => JoinTaskHelper.show(context, onSuccess: _loadCalendar),
        backgroundColor: _pink,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
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
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Belum ada notifikasi baru'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Icon(Icons.notifications_outlined,
                      color: Color(0xFF333333), size: 26),
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
          ),
        ],
      ),
    );
  }

  // ── Calendar Card ─────────────────────────────────────────────────────────────
  Widget _buildCalendarCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMonthHeader(),
            const SizedBox(height: 12),
            _buildDayHeaders(),
            const SizedBox(height: 6),
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return Row(
      children: [
        Text(
          '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _prevMonth,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.chevron_left, color: Color(0xFF666666), size: 22),
          ),
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.chevron_right, color: Color(0xFF666666), size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders() {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    int startOffset = firstDay.weekday % 7; // Sun=0
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final daysInPrevMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
    final today = DateTime.now();

    final List<_CalDay> cells = [];

    // Prev month filler
    for (int i = startOffset - 1; i >= 0; i--) {
      cells.add(_CalDay(
        date: DateTime(_focusedMonth.year, _focusedMonth.month - 1,
            daysInPrevMonth - i),
        isCurrentMonth: false,
      ));
    }

    // Current month
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final key = _key(date);
      final eventsOnDay = _events[key] ?? [];

      // Ambil warna dot: prioritas tertinggi menang
      Color? dotColor;
      if (eventsOnDay.isNotEmpty) {
        final hasTinggi = eventsOnDay.any((e) => e['prioritas'] == 'tinggi');
        final hasSedang = eventsOnDay.any((e) => e['prioritas'] == 'sedang');
        dotColor = hasTinggi
            ? _colorByPrioritas['tinggi']
            : hasSedang
                ? _colorByPrioritas['sedang']
                : _colorByPrioritas['rendah'];
      }

      cells.add(_CalDay(
        date: date,
        isCurrentMonth: true,
        isToday: date.year == today.year &&
            date.month == today.month &&
            date.day == today.day,
        isSelected: date.year == _selectedDay.year &&
            date.month == _selectedDay.month &&
            date.day == _selectedDay.day,
        hasEvent: eventsOnDay.isNotEmpty,
        eventCount: eventsOnDay.length,
        dotColor: dotColor,
      ));
    }

    // Next month filler
    int remaining = 7 - (cells.length % 7);
    if (remaining != 7) {
      for (int d = 1; d <= remaining; d++) {
        cells.add(_CalDay(
          date: DateTime(_focusedMonth.year, _focusedMonth.month + 1, d),
          isCurrentMonth: false,
        ));
      }
    }

    final rows = <Widget>[];
    for (int r = 0; r < cells.length / 7; r++) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (c) {
          final cell = cells[r * 7 + c];
          return _buildDayCell(cell);
        }),
      ));
      rows.add(const SizedBox(height: 4));
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(_CalDay cell) {
    Color textColor = const Color(0xFF1A1A1A);
    if (!cell.isCurrentMonth) textColor = const Color(0xFFCCCCCC);
    if (cell.isSelected && !cell.isToday) textColor = _pink;

    return GestureDetector(
      onTap: cell.isCurrentMonth
          ? () => setState(() => _selectedDay = cell.date)
          : null,
      child: SizedBox(
        width: 36,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: cell.isToday
                  ? const BoxDecoration(color: _pink, shape: BoxShape.circle)
                  : (cell.isSelected && cell.isCurrentMonth
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _pink, width: 1.5),
                        )
                      : null),
              child: Center(
                child: Text(
                  '${cell.date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: cell.isToday || cell.isSelected
                        ? FontWeight.bold
                        : FontWeight.w400,
                    color: cell.isToday ? Colors.white : textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Dot(s) event
            if (cell.hasEvent && cell.isCurrentMonth)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cell.isToday
                          ? Colors.white70
                          : (cell.dotColor ?? _pink),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (cell.eventCount > 1) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cell.isToday ? Colors.white54 : _pink.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ]
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadCalendar,
              icon: const Icon(Icons.refresh, color: _pink),
              label: const Text('Coba lagi', style: TextStyle(color: _pink)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Schedule Section ──────────────────────────────────────────────────────────
  Widget _buildScheduleSection() {
    const monthsShort = [
      'JAN','FEB','MAR','APR','MEI','JUN',
      'JUL','AGU','SEP','OKT','NOV','DES'
    ];
    final label =
        '${monthsShort[_selectedDay.month - 1]} ${_selectedDay.day} — JADWAL';
    final count = _selectedEvents.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count Tugas',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_selectedEvents.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(_selectedEvents.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(_selectedEvents[i]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada tugas pada hari ini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> task) {
    final String title = task['nama_tugas']?.toString() ?? 'Tugas';
    final String matkul = task['nama_matkul']?.toString() ?? '';
    final String jam = task['jam']?.toString() ?? '23:59';
    final String prioritas = task['prioritas']?.toString() ?? 'sedang';
    final String taskStatus = task['status']?.toString() ?? 'active';
    // sub_status hanya ada untuk mahasiswa; dosen lihat task status
    final String subStatus = task['sub_status']?.toString() ?? taskStatus;
    final int? grade = task['grade'] as int?;

    // Warna prioritas
    final Color priColor = _colorByPrioritas[prioritas] ?? const Color(0xFF9E9E9E);

    // Label & warna status badge
    String statusLabel;
    Color statusColor;
    if (task.containsKey('sub_status')) {
      // Mahasiswa view
      switch (subStatus) {
        case 'submitted':
          statusLabel = 'Dikumpulkan';
          statusColor = _colorBySubStatus['submitted']!;
          break;
        case 'graded':
          statusLabel = grade != null ? 'Nilai: $grade' : 'Dinilai';
          statusColor = _colorBySubStatus['graded']!;
          break;
        case 'late':
          statusLabel = 'Terlambat';
          statusColor = _colorBySubStatus['late']!;
          break;
        default:
          statusLabel = 'Belum';
          statusColor = _colorBySubStatus['pending']!;
      }
    } else {
      // Dosen view
      final submitted = task['submitted_count'] ?? 0;
      final total = task['total_students'] ?? 0;
      statusLabel = '$submitted/$total';
      statusColor = taskStatus == 'graded'
          ? _colorBySubStatus['graded']!
          : taskStatus == 'closed'
              ? _colorBySubStatus['late']!
              : _colorBySubStatus['pending']!;
    }

    final bool isDone = subStatus == 'submitted' ||
        subStatus == 'graded' ||
        taskStatus == 'graded';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: priColor, width: 4),
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _buildRadio(isDone, priColor),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF1A1A1A),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (matkul.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.book_outlined,
                          size: 12, color: Color(0xFF999999)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          matkul,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF999999)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFF999999)),
                    const SizedBox(width: 4),
                    Text(
                      jam,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Prioritas badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prioritas[0].toUpperCase() + prioritas.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: priColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool done, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? color : const Color(0xFFDDDDDD),
          width: 2,
        ),
        color: done ? color.withValues(alpha: 0.1) : Colors.transparent,
      ),
      child: done
          ? Center(child: Icon(Icons.circle, color: color, size: 10))
          : null,
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────────
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
          final selected = i == 2;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()));
              } else if (i == 1) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const TaskScreen()));
              } else if (i == 3) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const SocialScreen()));
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

// ── Helper data class ──────────────────────────────────────────────────────────
class _CalDay {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final int eventCount;
  final Color? dotColor;

  const _CalDay({
    required this.date,
    required this.isCurrentMonth,
    this.isToday = false,
    this.isSelected = false,
    this.hasEvent = false,
    this.eventCount = 0,
    this.dotColor,
  });
}
