import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const _pink = Color(0xFFE91E8C);

  bool _loading = true;
  bool _uploading = false;
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _submission;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final id = _taskId();
      final data = await TaskService().getTaskDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = data['task'] != null
            ? Map<String, dynamic>.from(data['task'])
            : Map<String, dynamic>.from(widget.task);
        _submission = data['submission'] != null
            ? Map<String, dynamic>.from(data['submission'])
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detail = Map<String, dynamic>.from(widget.task);
        _loading = false;
      });
    }
  }

  int _taskId() {
    final id = widget.task['id_task'] ?? widget.task['id'];
    return id is int ? id : int.parse(id.toString());
  }

  Future<void> _pickFile() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _pickedFile = file);
  }

  Future<void> _submitFile() async {
    if (_pickedFile == null) return;
    setState(() => _uploading = true);
    try {
      final res = await TaskService().submitTaskFile(_taskId(), _pickedFile!);
      if (!mounted) return;
      final msg = res['message']?.toString() ?? 'Berhasil';
      final ok = msg.toLowerCase().contains('berhasil');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) {
        setState(() => _pickedFile = null);
        await _loadDetail();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal mengirim file'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final task = _detail ?? widget.task;
    final title = task['nama_tugas']?.toString() ?? 'Detail Tugas';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : Column(
                children: [
                  _buildHeader(title),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(task),
                          const SizedBox(height: 14),
                          _buildSubmissionStatusCard(),
                          const SizedBox(height: 14),
                          _buildUploadCard(task),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E8C), Color(0xFFFF6BB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard(Map task) {
    final matkul = task['nama_matkul']?.toString() ?? '';
    final deadline = task['deadline']?.toString() ?? '';
    final jam = task['jam']?.toString() ?? '';
    final tipe = task['tipe']?.toString() ?? 'individu';
    final prioritas = task['prioritas']?.toString() ?? 'sedang';
    final deskripsi = task['deskripsi']?.toString() ?? '';
    final kode = task['kode_tugas']?.toString() ?? '';
    final tags = task['tags']?.toString() ?? '';
    final points = task['points']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'active';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task['nama_tugas']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          if (matkul.isNotEmpty) _infoRow(Icons.school_outlined, 'Mata Kuliah', matkul),
          if (deadline.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today_outlined, 'Deadline',
                '$deadline${jam.isNotEmpty ? '  •  $jam' : ''}'),
          ],
          const SizedBox(height: 8),
          _infoRow(
              tipe == 'kelompok' ? Icons.people_outline : Icons.person_outline,
              'Tipe',
              tipe == 'kelompok' ? 'Kelompok' : 'Individu'),
          const SizedBox(height: 8),
          _infoRow(Icons.flag_outlined, 'Prioritas', _capitalizeFirst(prioritas)),
          if (points.isNotEmpty && points != 'null') ...[
            const SizedBox(height: 8),
            _infoRow(Icons.star_outline, 'Poin', points),
          ],
          if (kode.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.qr_code, 'Kode Tugas', kode),
          ],
          if (deskripsi.isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFF0F0F0)),
            const Text('Deskripsi',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888))),
            const SizedBox(height: 6),
            Text(deskripsi,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5)),
          ],
          if (tags.isNotEmpty && tags != 'null') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.split(',').map((t) => _tagChip(t.trim())).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _pink),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333))),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'submitted': [Colors.green, 'Dikumpulkan'],
      'late':      [Colors.orange, 'Terlambat'],
      'graded':    [Colors.blue, 'Dinilai'],
      'closed':    [Colors.grey, 'Ditutup'],
      'pending':   [Colors.orange, 'Belum Kumpul'],
    };
    final color = (map[status]?[0] as Color?) ?? _pink;
    final label = (map[status]?[1] as String?) ?? 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pink.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: _pink, fontWeight: FontWeight.w500)),
    );
  }

  // ── Submission Status Card ───────────────────────────────────────────────────

  Widget _buildSubmissionStatusCard() {
    final sub = _submission;

    // Belum ada submission
    if (sub == null) {
      return _card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pending_outlined,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Pengumpulan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                SizedBox(height: 2),
                Text('Belum Dikumpulkan',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ],
            ),
          ],
        ),
      );
    }

    final status      = sub['status']?.toString() ?? 'pending';
    final grade       = sub['grade'];
    final feedback    = sub['feedback']?.toString() ?? '';
    final submittedAt = sub['submitted_at']?.toString() ?? '';
    final file        = sub['file']?.toString() ?? '';

    final statusMap = {
      'submitted': [Colors.green,  Icons.check_circle_outline,   'Sudah Dikumpulkan'],
      'late':      [Colors.orange, Icons.warning_amber_outlined,  'Terlambat'],
      'graded':    [Colors.blue,   Icons.grade_outlined,          'Sudah Dinilai'],
    };
    final color      = (statusMap[status]?[0] as Color?) ?? Colors.grey;
    final icon       = (statusMap[status]?[1] as IconData?) ?? Icons.pending_outlined;
    final statusLabel = (statusMap[status]?[2] as String?) ?? 'Belum Dikumpulkan';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pengumpulan',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888))),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          if (submittedAt.isNotEmpty && submittedAt != 'null') ...[
            const SizedBox(height: 6),
            Text('Dikumpulkan: $submittedAt',
                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
          ],
          if (file.isNotEmpty && file != 'null') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 14, color: _pink),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    file.split('/').last,
                    style: const TextStyle(fontSize: 12, color: _pink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Nilai & feedback
          if (grade != null) ...[
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text('Nilai: $grade / 100',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
              ],
            ),
            if (feedback.isNotEmpty && feedback != 'null') ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(feedback,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF555555))),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Upload Card ──────────────────────────────────────────────────────────────

  Widget _buildUploadCard(Map task) {
    final taskStatus  = task['status']?.toString() ?? 'active';
    final isGraded    = _submission != null && _submission!['grade'] != null;
    final isClosed    = taskStatus == 'closed' || taskStatus == 'graded';
    final hasSubmitted = _submission != null &&
        (_submission!['status'] == 'submitted' ||
            _submission!['status'] == 'late' ||
            _submission!['status'] == 'graded');

    // Sudah dinilai atau tugas ditutup
    if (isGraded || isClosed) {
      return _card(
        child: Row(
          children: [
            Icon(
              isGraded ? Icons.lock_outline : Icons.lock_clock_outlined,
              color: Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              isGraded ? 'Tugas sudah dinilai' : 'Tugas sudah ditutup',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file_rounded, color: _pink, size: 20),
              const SizedBox(width: 8),
              const Text('Upload File Tugas',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              if (hasSubmitted) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Re-submit',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Format: PDF, Word, PPT, ZIP, atau Gambar • Maks. 10 MB',
            style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 14),

          // Drop zone
          GestureDetector(
            onTap: _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _pickedFile != null
                    ? _pink.withValues(alpha: 0.05)
                    : const Color(0xFFFFF0F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _pickedFile != null ? _pink : const Color(0xFFFFBBDD),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _pickedFile != null
                        ? Icons.check_circle_outline
                        : Icons.cloud_upload_outlined,
                    color: _pink,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedFile != null
                        ? _pickedFile!.name
                        : 'Ketuk untuk memilih file',
                    style: TextStyle(
                      fontSize: 13,
                      color: _pickedFile != null
                          ? _pink
                          : const Color(0xFFBBBBBB),
                      fontWeight: _pickedFile != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_pickedFile == null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'atau seret & lepas file ke sini',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tombol submit
          if (_pickedFile != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _uploading
                        ? null
                        : () => setState(() => _pickedFile = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _submitFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                        _uploading ? 'Mengupload...' : 'Kumpulkan Tugas'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Generic Card ─────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
