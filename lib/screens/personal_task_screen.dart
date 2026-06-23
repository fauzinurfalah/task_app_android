import 'package:flutter/material.dart';
import '../services/personal_task_service.dart';

const _purple = Color(0xFF8B5CF6);
const _pink = Color(0xFFE91E8C);
const _bg = Color(0xFFF7F7F7);

// ─── Priority config ────────────────────────────────────────────────────────
const Map<String, Map<String, dynamic>> _priCfg = {
  'urgent': {'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2), 'label': '🔴 Urgent', 'desc': 'Sangat mendesak'},
  'high':   {'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED), 'label': '🟠 High', 'desc': 'Penting'},
  'medium': {'color': Color(0xFFCA8A04), 'bg': Color(0xFFFEFCE8), 'label': '🟡 Medium', 'desc': 'Sedang'},
  'low':    {'color': Color(0xFF10B981), 'bg': Color(0xFFF0FDF4), 'label': '🟢 Low', 'desc': 'Santai'},
};

class PersonalTaskScreen extends StatefulWidget {
  const PersonalTaskScreen({super.key});

  @override
  State<PersonalTaskScreen> createState() => _PersonalTaskScreenState();
}

class _PersonalTaskScreenState extends State<PersonalTaskScreen> {
  final _service = PersonalTaskService();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final tasks = await _service.getPersonalTasks();
    if (mounted) setState(() { _tasks = tasks; _loading = false; });
  }

  void _openCreateForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePersonalTaskSheet(service: _service),
    );
    if (result == true) _loadTasks();
  }

  Future<void> _toggleDone(Map<String, dynamic> task) async {
    final id = task['id'] as int;
    final newStatus = task['status'] == 'completed' ? 'pending' : 'completed';
    await _service.updatePersonalTask(id, {...task, 'status': newStatus, 'progress': newStatus == 'completed' ? 100 : 0});
    _loadTasks();
  }

  Future<void> _delete(int id) async {
    final ok = await _service.deletePersonalTask(id);
    if (ok) _loadTasks();
  }

  int _daysLeft(String due, String dueTime) {
    try {
      final d = DateTime.parse('${due}T$dueTime');
      final now = DateTime.now();
      if (d.isBefore(now)) return -1;
      return d.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_pin_outlined, color: _purple, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tugas Mandiri', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 17)),
                Text('Kelola tugas pribadimu', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openCreateForm,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : _tasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: _tasks.length,
                  itemBuilder: (_, i) => _buildTaskCard(_tasks[i]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin_outlined, color: _purple, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Belum ada tugas mandiri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Buat tugas pribadimu di sini', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _openCreateForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Buat Tugas Mandiri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isDone = task['status'] == 'completed';
    final pri = _priCfg[task['priority'] ?? 'medium'] ?? _priCfg['medium']!;
    final due = task['due']?.toString() ?? '';
    final dueTime = task['dueTime']?.toString().substring(0, 5) ?? '23:59';
    final title = task['title']?.toString() ?? '';
    final course = task['course']?.toString() ?? 'Umum';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDone ? const Color(0xFFE2E8F0) : Colors.transparent, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.track_changes, color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 16),
              // Title and Dates
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(due, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(dueTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFF1F5F9) : pri['bg'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFCBD5E1) : (pri['color'] as Color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (pri['label'] as String).split(' ').length > 1 ? (pri['label'] as String).split(' ')[1] : pri['label'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF94A3B8) : pri['color']),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Course Tag
          if (course.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_outline, size: 12, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  Text(course, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ],
              ),
            ),
          if (course.isNotEmpty) const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              // Toggle Done Button
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleDone(task),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFFF8FAFC) : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDone ? const Color(0xFFE2E8F0) : const Color(0xFFEDE9FE), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isDone ? Icons.refresh : Icons.check_circle_outline, size: 16, color: isDone ? const Color(0xFF64748B) : const Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? 'Batal Selesai' : 'Tandai Selesai',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF64748B) : const Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Delete Button
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Hapus Tugas?', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      content: const Text('Tugas mandiri ini akan dihapus permanen dan tidak dapat dipulihkan.', style: TextStyle(color: Color(0xFF64748B))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) _delete(task['id'] as int);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Create Personal Task Bottom Sheet ─────────────────────────────────────
class _CreatePersonalTaskSheet extends StatefulWidget {
  final PersonalTaskService service;
  const _CreatePersonalTaskSheet({required this.service});

  @override
  State<_CreatePersonalTaskSheet> createState() => _CreatePersonalTaskSheetState();
}

class _CreatePersonalTaskSheetState extends State<_CreatePersonalTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime? _due;
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _due == null) return;
    setState(() => _saving = true);

    final dueStr = '${_due!.year.toString().padLeft(4, '0')}-${_due!.month.toString().padLeft(2, '0')}-${_due!.day.toString().padLeft(2, '0')}';
    final timeStr = '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}:00';

    final result = await widget.service.createPersonalTask(
      title: _titleCtrl.text.trim(),
      due: dueStr,
      dueTime: timeStr,
      course: _courseCtrl.text.trim(),
      description: _noteCtrl.text.trim(),
      priority: _priority,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (result != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat tugas mandiri')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.track_changes, color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buat Tugas Mandiri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Kelola dan jadwalkan tugas pribadimu.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            _label('Nama Tugas *'),
            _textField(_titleCtrl, 'Judul tugas mandirimu...'),
            const SizedBox(height: 18),

            _label('Kategori / Mata Kuliah'),
            _textField(_courseCtrl, 'Contoh: Matematika, Proyek Pribadi...'),
            const SizedBox(height: 18),

            _label('Catatan Tambahan'),
            _textField(_noteCtrl, 'Deskripsi atau catatan penting...', maxLines: 3),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tenggat Waktu *'),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF888888)),
                              const SizedBox(width: 8),
                              Text(
                                _due == null ? 'Pilih tanggal' : '${_due!.day.toString().padLeft(2, '0')}/${_due!.month.toString().padLeft(2, '0')}/${_due!.year}',
                                style: TextStyle(fontSize: 13, color: _due == null ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Jam Target'),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 16, color: Color(0xFF888888)),
                              const SizedBox(width: 8),
                              Text(
                                '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _label('Tingkat Prioritas'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: _priCfg.entries.map((e) {
                final isSelected = _priority == e.key;
                final data = e.value;
                final labelText = data['label'] as String;
                final emoji = labelText.split(' ')[0];
                final text = labelText.split(' ')[1];

                return GestureDetector(
                  onTap: () => setState(() => _priority = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? data['bg'] : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (data['color'] as Color) : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? data['color'] : const Color(0xFF0F172A))),
                              Text(data['desc'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Tugas Mandiri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
      );

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1}) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _purple, width: 1.5)),
        ),
      );
}
