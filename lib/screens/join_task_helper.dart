import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'scan_qr_screen.dart';

/// Helper untuk menampilkan bottom sheet join tugas dari screen manapun.
/// Panggil: JoinTaskHelper.show(context, onSuccess: () => reload());
class JoinTaskHelper {
  static const _pink = Color(0xFFE91E8C);

  static void show(BuildContext context, {VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(
        onScanQr: () async {
          Navigator.pop(context);
          final kode = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const ScanQrScreen()),
          );
          if (!context.mounted) return;
          if (kode != null && kode.isNotEmpty) {
            await _doJoin(context, kode, onSuccess: onSuccess);
          }
        },
        onEnterCode: () {
          Navigator.pop(context);
          _showCodeDialog(context, onSuccess: onSuccess);
        },
      ),
    );
  }

  static void _showCodeDialog(BuildContext context, {VoidCallback? onSuccess}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Masukkan Kode Tugas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Contoh: ABCD12',
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: _pink),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _pink, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _pink, foregroundColor: Colors.white),
            onPressed: () async {
              final kode = ctrl.text.trim();
              if (kode.isEmpty) return;
              Navigator.pop(ctx);
              await _doJoin(context, kode, onSuccess: onSuccess);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  static Future<void> _doJoin(BuildContext context, String kode,
      {VoidCallback? onSuccess}) async {
    try {
      final res = await TaskService().joinTask(kode);
      if (!context.mounted) return;
      final msg = res['message']?.toString() ?? '';
      final ok = !msg.toLowerCase().contains('tidak') &&
          !msg.toLowerCase().contains('gagal') &&
          !msg.toLowerCase().contains('error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Berhasil join tugas!' : msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) onSuccess?.call();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal join tugas'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

// ── Bottom Sheet Widget ──────────────────────────────────────────────────────

class _JoinSheet extends StatelessWidget {
  final VoidCallback onScanQr;
  final VoidCallback onEnterCode;
  const _JoinSheet({required this.onScanQr, required this.onEnterCode});

  static const _pink = Color(0xFFE91E8C);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Tambah Tugas',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('Pilih cara untuk bergabung ke tugas',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 24),
          _Opt(
            icon: Icons.qr_code_scanner_rounded,
            color: _pink,
            title: 'Scan QR Code',
            subtitle: 'Arahkan kamera ke QR Code dari dosen',
            onTap: onScanQr,
          ),
          const SizedBox(height: 12),
          _Opt(
            icon: Icons.keyboard_alt_outlined,
            color: const Color(0xFF7C5CBF),
            title: 'Masukkan Kode',
            subtitle: 'Ketik kode tugas yang diberikan dosen',
            onTap: onEnterCode,
          ),
        ],
      ),
    );
  }
}

class _Opt extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Opt(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
