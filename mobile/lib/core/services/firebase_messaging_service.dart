import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 Background: ${message.notification?.title}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio = ApiClient.instance.client;

  // ← NUEVO: plugin de notificaciones locales
  static final _localPlugin = FlutterLocalNotificationsPlugin();

  // ─── Inicializar ─────────────────────────────────────────────
  Future<void> init() async {
    try {
      // ← NUEVO: inicializar notificaciones locales
      await _initLocalNotifications();

      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
        announcement: false, carPlay: false,
        criticalAlert: false, provisional: false,
      );

      debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      _messaging.onTokenRefresh.listen((nuevoToken) async {
        await _guardarTokenEnBackend(nuevoToken);
      });

    } catch (e) {
      debugPrint('[FCM] ❌ Error init: $e');
    }
  }

  // ← NUEVO: configurar canal Android
  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localPlugin.initialize(
      const InitializationSettings(android: android),
    );

    const canal = AndroidNotificationChannel(
      'emergencias_channel',
      'Emergencias Vehiculares',
      description: 'Notificaciones de emergencias en tiempo real',
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(canal);
    }
  }

  // ─── Handlers ────────────────────────────────────────────────

  // ← MODIFICADO: ahora muestra la notificación visualmente
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] 📩 Foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergencias_channel',
          'Emergencias Vehiculares',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] 📲 App abierta desde notificación');
    final incidenteId = message.data['incidente_id'];
    if (incidenteId != null) {
      debugPrint('[FCM] → Navegar a incidente #$incidenteId');
    }
  }

  // ─── El resto igual que tenías ────────────────────────────────
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) debugPrint('[FCM] ✅ Token: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('[FCM] ❌ Error obteniendo token: $e');
      return null;
    }
  }

  Future<void> registrarTokenDespuesDeLogin() async {
    try {
      final token = await getToken();
      if (token != null) await _guardarTokenEnBackend(token);
    } catch (e) {
      debugPrint('[FCM] ❌ Error registrando token: $e');
    }
  }

  Future<void> limpiarToken() async {
    try {
      await _dio.patch('/usuarios/fcm-token', data: {'token_fcm': null});
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] ❌ Error eliminando token: $e');
    }
  }

  Future<void> _guardarTokenEnBackend(String token) async {
    try {
      await _dio.patch('/usuarios/fcm-token', data: {'token_fcm': token});
      debugPrint('[FCM] ✅ Token guardado en backend');
    } catch (e) {
      debugPrint('[FCM] ❌ Error guardando token: $e');
    }
  }
}