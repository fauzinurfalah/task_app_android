import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/personal_task_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const _pink = Color(0xFFE91E8C);
  static const _purple = Color(0xFF7C3AED);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  String _priority = 'medium';
  DateTime? _due;
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  bool _saving = false;

  final _service = PersonalTaskService();

  static const _priCfg = {
    'urgent': {'bg': Color(0xFFFEF2F2), 'color': Color(0xFFDC2626), 'dot': Color(0xFFDC2626), 'label': '🔴 Urgent', 'desc': 'Sangat mendesak'},
    'high':   {'bg': Color(0xFFFFF7ED), 'color': Color(0xFFEA580C), 'dot': Color(0xFFEA580C), 'label': '🟠 High',   'desc': 'Penting'},
    'medium': {'bg': Color(0xFFFEFCE8), 'color': Color(0xFFCA8A04), 'dot': Color(0xFFCA8A04), 'label': '🟡 Medium', 'desc': 'Sedang'},
    'low':    {'bg': Color(0xFFF0FDF4), 'color': Color(0xFF059669), 'dot': Color(0xFF10B981), 'label': '🟢 Low',    'desc': 'Santai'},
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
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
    if (!_formKey.currentState!.validate()) return;
    if (_due == null) {
      _showSnack('Pilih tenggat waktu (tanggal) terlebih dahulu');
      return;
    }

    setState(() => _saving = true);
    final dueStr = DateFormat('yyyy-MM-dd').format(_due!);
    final timeStr = '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}:00';

    final result = await _service.createPersonalTask(
      title: _titleCtrl.text.trim(),
      due: dueStr,
      dueTime: timeStr,
      course: _courseCtrl.text.trim(),
      description: _noteCtrl.text.trim(),
      priority: _priority,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    
    if (result != null) {
      Navigator.pop(context, true);
    } else {
      _showSnack('Gagal membuat tugas mandiri. Periksa koneksi Anda.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Color(0xFFFFF0F8), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _pink, size: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Tetugas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _pink, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 36), // To balance the back button
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1, bool isRequired = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Bagian ini wajib diisi' : null : null,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _purple, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.track_changes, color: _purple, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Buat Tugas Mandiri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                Text('Kelola dan jadwalkan tugas pribadimu.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          _label('Nama Tugas'),
                          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _textField(_titleCtrl, 'Contoh: Belajar React Hooks', isRequired: true),
                      const SizedBox(height: 20),

                      _label('Kategori / Mata Kuliah'),
                      const SizedBox(height: 8),
                      _textField(_courseCtrl, 'Contoh: Proyek Pribadi'),
                      const SizedBox(height: 20),

                      _label('Catatan Tambahan'),
                      const SizedBox(height: 8),
                      _textField(_noteCtrl, 'Tuliskan rincian apa saja yang perlu diselesaikan...', maxLines: 3),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _label('Tenggat Waktu'),
                                    const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _due == null ? 'mm/dd/yyyy' : '${_due!.day.toString().padLeft(2, '0')}/${_due!.month.toString().padLeft(2, '0')}/${_due!.year}',
                                          style: TextStyle(fontSize: 14, color: _due == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), fontWeight: FontWeight.w500),
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
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_outlined, size: 16, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
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
                      const SizedBox(height: 20),

                      _label('Tingkat Prioritas'),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.8,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: _priCfg.entries.map((e) {
                          final p = e.value;
                          final isSel = _priority == e.key;
                          return GestureDetector(
                            onTap: () => setState(() => _priority = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSel ? p['bg'] as Color : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSel ? p['dot'] as Color : const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Text((p['label'] as String).split(' ')[0], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (p['label'] as String).split(' ')[1],
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSel ? p['color'] as Color : const Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        p['desc'] as String,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple, // Using purple gradient style
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Buat Tugas Mandiri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
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
}
