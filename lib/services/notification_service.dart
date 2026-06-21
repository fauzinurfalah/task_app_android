import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handler untuk pesan FCM yang diterima saat aplikasi di background.
/// Harus berupa top-level function (tidak bisa jadi method class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tidak perlu inisialisasi Firebase lagi karena sudah dilakukan di main().
  debugPrint('[FCM Background] Message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final String _baseUrl =
      kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

  /// Inisialisasi FCM: minta izin, setup handler, kirim token ke Laravel.
  Future<void> initialize() async {
    // 1. Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Minta izin notifikasi (Android 13+ dan iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Izin notifikasi ditolak.');
      return;
    }

    // 3. Ambil FCM token dan kirim ke server
    await _refreshAndSendToken();

    // 4. Dengarkan pembaruan token (token bisa berubah)
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token diperbarui: $newToken');
      _sendTokenToServer(newToken);
    });

    // 5. Handler saat notifikasi diterima ketika app di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
      // Notifikasi foreground akan ditampilkan melalui in-app banner
      // yang bisa Anda handle via GlobalKey<NavigatorState> jika perlu.
    });

    // 6. Handler saat user tap notifikasi (app di background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Opened] ${message.notification?.title}');
      // Bisa navigasi ke halaman tertentu di sini
    });

    // 7. Cek apakah app dibuka dari notifikasi saat terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM Initial] ${initialMessage.notification?.title}');
    }
  }

  /// Ambil FCM token lalu kirim ke server Laravel.
  Future<void> _refreshAndSendToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: $token');
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('[FCM] Gagal mendapatkan token: $e');
    }
  }

  /// Kirim FCM token ke endpoint POST /api/fcm-token di Laravel.
  Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null || authToken.isEmpty) {
        debugPrint('[FCM] Belum login, token tidak dikirim ke server.');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token berhasil disimpan ke server.');
      } else {
        debugPrint('[FCM] Gagal simpan token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error saat kirim token ke server: $e');
    }
  }

  /// Panggil ini setelah user berhasil login agar token langsung terdaftar.
  Future<void> syncTokenAfterLogin() async {
    await _refreshAndSendToken();
  }
}
