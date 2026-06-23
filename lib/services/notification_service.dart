import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification Channel (Android) ─────────────────────────────────────────
const _androidChannel = AndroidNotificationChannel(
  'deadline_reminders',        // Channel ID — harus sama dengan yang di FCM payload
  'Pengingat Deadline',        // Nama yang ditampilkan di pengaturan HP
  description: 'Notifikasi pengingat deadline tugas',
  importance: Importance.max,  // Heads-up notification
  playSound: true,
);

final _localNotif = FlutterLocalNotificationsPlugin();

/// Handler untuk pesan FCM yang diterima saat aplikasi di background/terminated.
/// Harus berupa top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
  // Background messages dari FCM data-only perlu ditampilkan manual:
  if (message.notification == null && message.data.isNotEmpty) {
    _showLocalNotification(message);
  }
}

void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  final android = message.notification?.android;

  if (notification == null) return;

  _localNotif.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(notification.body ?? ''),
      ),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String _baseUrl = 'http://3.104.52.205/api';
  bool _initialized = false;

  /// Inisialisasi FCM: channel Android, minta izin, setup handler, kirim token.
  /// Aman dipanggil berkali-kali (guard dengan _initialized flag).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Setup flutter_local_notifications (untuk foreground display)
    await _setupLocalNotifications();

    // 2. Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Minta izin notifikasi (Android 13+ dan iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Izin notifikasi ditolak oleh user.');
      return;
    }

    // 4. Ambil FCM token dan kirim ke server
    await _refreshAndSendToken();

    // 5. Pantau pembaruan token (token FCM bisa berubah)
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token diperbarui: $newToken');
      _sendTokenToServer(newToken);
    });

    // 6. Handler saat notifikasi diterima di FOREGROUND — tampilkan via local notif
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
      _showLocalNotification(message);
    });

    // 7. Handler saat user tap notifikasi (app di background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Opened] ${message.notification?.title}');
      // TODO: Navigasi ke halaman tugas jika diperlukan
    });

    // 8. Cek apakah app dibuka dari notifikasi saat terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM Initial] ${initialMessage.notification?.title}');
    }
  }

  Future<void> _setupLocalNotifications() async {
    // Buat channel Android dengan priority tinggi
    final androidPlugin = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(initSettings);

    // Pastikan FCM menampilkan notif saat foreground juga (iOS style)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _refreshAndSendToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: $token');
        await _sendTokenToServer(token);
      } else {
        debugPrint('[FCM] Gagal mendapatkan token (null).');
      }
    } catch (e) {
      debugPrint('[FCM] Gagal mendapatkan token: $e');
    }
  }

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

  /// Panggil ini setelah user berhasil login agar token langsung terdaftar ulang.
  Future<void> syncTokenAfterLogin() async {
    await _refreshAndSendToken();
  }
}
