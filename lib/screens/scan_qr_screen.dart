import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Layar scan QR Code.
/// Mengembalikan [String] kode tugas ketika scan berhasil,
/// atau [null] jika pengguna menekan tombol back.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  static const _pink = Color(0xFFE91E8C);

  final MobileScannerController _ctrl = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _detected = true;
    _ctrl.stop();

    // Kode tugas bisa berupa:
    //  - string langsung: "ABCD12"
    //  - URL yang mengandung kode: "https://…?kode=ABCD12" atau "/join/ABCD12"
    final kode = _extractKode(raw);

    Navigator.pop(context, kode);
  }

  /// Ekstrak kode tugas dari hasil scan.
  /// Jika raw adalah URL, ambil path segment terakhir atau query param "kode".
  String _extractKode(String raw) {
    try {
      final uri = Uri.parse(raw);
      // Cek query parameter: ?kode=... atau ?kode_tugas=...
      if (uri.queryParameters.containsKey('kode')) {
        return uri.queryParameters['kode']!;
      }
      if (uri.queryParameters.containsKey('kode_tugas')) {
        return uri.queryParameters['kode_tugas']!;
      }
      // Ambil segment terakhir path jika ada
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) return segments.last;
    } catch (_) {}
    return raw; // kembalikan mentah jika bukan URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Kamera ────────────────────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Overlay gelap + viewfinder ────────────────────────────────────
          _buildOverlay(),

          // ── Header ────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Scan QR Code Tugas',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Tombol flash
                      GestureDetector(
                        onTap: () => _ctrl.toggleTorch(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // ── Label bawah ──────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Text(
                    'Arahkan kamera ke QR Code tugas',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Overlay dengan lubang persegi di tengah (viewfinder)
  Widget _buildOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const boxSize = 260.0;
      final left = (w - boxSize) / 2;
      final top = (h - boxSize) / 2 - 40;

      return Stack(
        children: [
          // Gelap atas
          Positioned(
              top: 0, left: 0, right: 0, height: top,
              child: _darkBox()),
          // Gelap bawah
          Positioned(
              top: top + boxSize, left: 0, right: 0,
              bottom: 0,
              child: _darkBox()),
          // Gelap kiri
          Positioned(
              top: top, left: 0, width: left, height: boxSize,
              child: _darkBox()),
          // Gelap kanan
          Positioned(
              top: top, left: left + boxSize, right: 0, height: boxSize,
              child: _darkBox()),

          // Bingkai viewfinder
          Positioned(
            top: top,
            left: left,
            width: boxSize,
            height: boxSize,
            child: _buildViewfinder(boxSize),
          ),
        ],
      );
    });
  }

  Widget _darkBox() => Container(color: Colors.black.withValues(alpha: 0.6));

  Widget _buildViewfinder(double size) {
    const r = 16.0;
    const t = 3.0;
    const len = 32.0;

    Widget corner({
      required AlignmentGeometry align,
      required BorderRadius br,
    }) {
      return Align(
        alignment: align,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(
              top: align == Alignment.topLeft || align == Alignment.topRight
                  ? const BorderSide(color: _pink, width: t)
                  : BorderSide.none,
              bottom:
                  align == Alignment.bottomLeft || align == Alignment.bottomRight
                      ? const BorderSide(color: _pink, width: t)
                      : BorderSide.none,
              left: align == Alignment.topLeft || align == Alignment.bottomLeft
                  ? const BorderSide(color: _pink, width: t)
                  : BorderSide.none,
              right:
                  align == Alignment.topRight || align == Alignment.bottomRight
                      ? const BorderSide(color: _pink, width: t)
                      : BorderSide.none,
            ),
            borderRadius: br,
          ),
        ),
      );
    }

    return Stack(
      children: [
        corner(
            align: Alignment.topLeft,
            br: const BorderRadius.only(topLeft: Radius.circular(r))),
        corner(
            align: Alignment.topRight,
            br: const BorderRadius.only(topRight: Radius.circular(r))),
        corner(
            align: Alignment.bottomLeft,
            br: const BorderRadius.only(bottomLeft: Radius.circular(r))),
        corner(
            align: Alignment.bottomRight,
            br: const BorderRadius.only(bottomRight: Radius.circular(r))),
      ],
    );
  }
}
