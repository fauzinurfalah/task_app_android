import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  static const _pink = Color(0xFFE91E8C);

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Masukkan email Anda terlebih dahulu.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Format email tidak valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.sendPasswordResetCode(email);
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(email: email),
          ),
        );
      } else {
        setState(() => _errorMessage = result['message'] ?? 'Email tidak ditemukan.');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF48FB1),
              Color(0xFFF8BBD9),
              Color(0xFFFCE4EC),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: _pink, size: 36),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Judul
                      const Center(
                        child: Text(
                          'Lupa Password',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'Masukkan email Anda. Kami akan mengirimkan kode OTP untuk mereset password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.5),
                          ),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 6, bottom: 24),
                          child: SizedBox(
                            width: 40,
                            child: Divider(thickness: 2, color: Color(0xFFE0E0E0)),
                          ),
                        ),
                      ),

                      // Label E-mail
                      const Text(
                        'E-mail :',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF444444)),
                      ),
                      const SizedBox(height: 8),

                      // Input E-mail
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          hintText: 'contoh@email.com',
                          hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _pink, width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // Pesan error
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFFC62828)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tombol Kirim OTP
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pink,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor: _pink.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'KIRIM KODE OTP',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kembali ke Login
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Kembali ke Login',
                            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
