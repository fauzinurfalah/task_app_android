import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const _pink = Color(0xFFE91E8C);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedSubject;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;

  // Daftar mata kuliah Teknik Informatika
  static const _subjects = [
    'Pemrograman Web',
    'Pemrograman Mobile',
    'Basis Data',
    'Jaringan Komputer',
    'Kecerdasan Buatan',
    'Algoritma & Struktur Data',
    'Rekayasa Perangkat Lunak',
    'Sistem Operasi',
    'Keamanan Informasi',
    'Pemrograman Berorientasi Objek',
    'Interaksi Manusia Komputer',
    'Metodologi Penelitian',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _deadlineString {
    if (_selectedDate == null) return '';
    final datePart = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timePart = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
        : '00:00:00';
    return '$datePart $timePart';
  }

  String get _displayDate => _selectedDate == null
      ? 'mm/dd/yyyy'
      : DateFormat('dd/MM/yyyy').format(_selectedDate!);

  String get _displayTime => _selectedTime == null
      ? '--:-- --'
      : _selectedTime!.format(context);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _pink),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _pink),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      _showSnack('Pilih mata kuliah terlebih dahulu');
      return;
    }
    if (_selectedDate == null) {
      _showSnack('Pilih tanggal deadline');
      return;
    }

    setState(() => _saving = true);
    try {
      await TaskService().createTask(
        title: _titleCtrl.text.trim(),
        subject: _selectedSubject!,
        deadline: _deadlineString,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true); // return true → refresh list
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan tugas. Periksa koneksi.');
    } finally {
      if (mounted) setState(() => _saving = false);
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

  // ── Build ────────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // ── Heading ─────────────────────────────────────────
                      const Text(
                        'Tugas Baru',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tambahkan detail tugas untuk tetap terorganisir.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Nama Tugas ───────────────────────────────────────
                      _label('Nama Tugas'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _titleCtrl,
                        hint: 'Contoh: Esai Sejarah',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama tugas tidak boleh kosong'
                                : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Mata Kuliah ──────────────────────────────────────
                      _label('Mata Kuliah'),
                      const SizedBox(height: 8),
                      _subjectDropdown(),
                      const SizedBox(height: 20),

                      // ── Tanggal & Waktu ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Tanggal'),
                                const SizedBox(height: 8),
                                _dateTimeButton(
                                  text: _displayDate,
                                  icon: Icons.calendar_month_outlined,
                                  onTap: _pickDate,
                                  hasValue: _selectedDate != null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Waktu'),
                                const SizedBox(height: 8),
                                _dateTimeButton(
                                  text: _displayTime,
                                  icon: Icons.access_time_rounded,
                                  onTap: _pickTime,
                                  hasValue: _selectedTime != null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Deskripsi ────────────────────────────────────────
                      _label('Deskripsi / Catatan'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _descCtrl,
                        hint: 'Tambahkan instruksi atau detail tambahan...',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 36),

                      // ── Simpan Button ────────────────────────────────────
                      _buildSaveButton(),
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

  // ── Top Bar ──────────────────────────────────────────────────────────────────

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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _pink, size: 16),
            ),
          ),
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

  // ── Form Widgets ─────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444444),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _pink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _subjectDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubject,
          hint: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Pilih Mata Kuliah',
              style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF888888), size: 22),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          items: _subjects.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  s,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF222222)),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubject = val),
        ),
      ),
    );
  }

  Widget _dateTimeButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? _pink.withValues(alpha: 0.4) : const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue
                      ? const Color(0xFF222222)
                      : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            Icon(icon,
                size: 18,
                color: hasValue ? _pink : const Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pink,
          disabledBackgroundColor: _pink.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Simpan Tugas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
