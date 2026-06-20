import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';
import 'dashboard_screen.dart';
import 'task_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _pink = Color(0xFFE91E8C);

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Task events: day → list of tasks
  Map<String, List<Map<String, dynamic>>> _events = {};
  bool _loadingTasks = true;

  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _userService.loadUser();
    _loadTasksFromApi();
  }

  Future<void> _loadTasksFromApi() async {
    try {
      final tasks = await TaskService().getTasks();
      final Map<String, List<Map<String, dynamic>>> newEvents = {};

      for (var task in tasks) {
        String? deadlineStr = task['deadline']?.toString();
        if (deadlineStr != null && deadlineStr.length >= 10) {
          // Asumsi format 'yyyy-MM-dd'
          String dateKey = deadlineStr.substring(0, 10);
          
          bool isDone = task['status'] == 'done' || task['status'] == 'closed' || task['status'] == 'graded';
          String title = task['nama_tugas']?.toString() ?? task['title']?.toString() ?? 'Tugas';
          String time = task['jam']?.toString() ?? '23:59';
          
          String tag = 'Tugas';
          Color tagColor = const Color(0xFF8B5CF6); // Default color assignment
          
          if (task['mata_kuliah'] != null && task['mata_kuliah'] is Map) {
             tag = task['mata_kuliah']['nama_matkul']?.toString() ?? tag;
          } else if (task['nama_matkul'] != null) {
             tag = task['nama_matkul'].toString();
          } else if (task['subject'] != null) {
             tag = task['subject'].toString();
          }

          if (newEvents[dateKey] == null) {
            newEvents[dateKey] = [];
          }
          newEvents[dateKey]!.add({
            'title': title,
            'time': time,
            'tag': tag,
            'tagColor': tagColor,
            'done': isDone,
            'due': null,
            'hasProgress': false,
          });
        }
      }

      if (mounted) {
        setState(() {
          _events = newEvents;
          _loadingTasks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTasks = false;
        });
      }
    }
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _selectedEvents =>
      _events[_key(_selectedDay)] ?? [];

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  // ── Navigation ────────────────────────────────────────────────────────────────
  void _prevMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      });

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildCalendarCard(),
                    const SizedBox(height: 20),
                    _loadingTasks 
                        ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _pink)))
                        : _buildScheduleSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        backgroundColor: _pink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Row(
      children: [
        Text(
          '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _prevMonth,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF666666), size: 22),
          ),
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.chevron_right,
                color: Color(0xFF666666), size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 12,
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
    // weekday: 1=Mon ... 7=Sun. We want Sun=0
    int startOffset = firstDay.weekday % 7;
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
      final date =
          DateTime(_focusedMonth.year, _focusedMonth.month, d);
      cells.add(_CalDay(
        date: date,
        isCurrentMonth: true,
        isToday: date.year == today.year &&
            date.month == today.month &&
            date.day == today.day,
        isSelected: date.year == _selectedDay.year &&
            date.month == _selectedDay.month &&
            date.day == _selectedDay.day,
        hasEvent: _events.containsKey(_key(date)),
      ));
    }

    // Next month filler to complete grid
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
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number with circle
            Container(
              width: 34,
              height: 34,
              decoration: cell.isToday
                  ? const BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                    )
                  : (cell.isSelected && cell.isCurrentMonth
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: _pink, width: 1.5),
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
            // Event dot
            const SizedBox(height: 2),
            cell.hasEvent && cell.isCurrentMonth
                ? Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cell.isToday ? Colors.white70 : _pink,
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // ── Schedule Section ──────────────────────────────────────────────────────────
  Widget _buildScheduleSection() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final label =
        '${months[_selectedDay.month - 1]} ${_selectedDay.day} SCHEDULE';
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count Task${count != 1 ? 's' : ''}',
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
              final t = _selectedEvents[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(t),
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
            Icon(Icons.event_available_outlined,
                size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada tugas hari ini',
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
    final bool done = task['done'] == true;
    final bool highlighted = task['due'] != null;
    final String? tag = task['tag'] as String?;
    final Color tagColor =
        (task['tagColor'] as Color?) ?? const Color(0xFF9E9E9E);
    final String? time = task['time'] as String?;
    final String? location = task['location'] as String?;
    final String? due = task['due'] as String?;
    final bool hasProgress = task['hasProgress'] == true;
    final double progress =
        (task['progress'] as num?)?.toDouble() ?? 0.5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlighted
            ? Border(
                left: BorderSide(color: _pink, width: 3.5),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            highlighted ? 14 : 16, 14, 16, hasProgress ? 0 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio-style checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: _buildRadio(done),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: done
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF1A1A1A),
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFFAAAAAA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (time != null)
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: Color(0xFF999999)),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      if (location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF999999)),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      if (due != null)
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 13, color: _pink),
                            const SizedBox(width: 4),
                            Text(
                              due,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _pink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Tag badge
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tagColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasProgress) ...[
              const SizedBox(height: 10),
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
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool done) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? _pink : const Color(0xFFDDDDDD),
          width: 2,
        ),
        color: done ? _pink.withValues(alpha: 0.1) : Colors.transparent,
      ),
      child: done
          ? const Center(
              child: Icon(Icons.circle, color: _pink, size: 10),
            )
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
          // Calendar tab (index 2) is always selected
          final selected = i == 2;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              } else if (i == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskScreen()),
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

// ── Helper data class ──────────────────────────────────────────────────────────
class _CalDay {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;

  const _CalDay({
    required this.date,
    required this.isCurrentMonth,
    this.isToday = false,
    this.isSelected = false,
    this.hasEvent = false,
  });
}
