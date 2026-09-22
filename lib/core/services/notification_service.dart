// lib/core/services/notification_service.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../platform/platform_capabilities.dart';

/// Structured payload for CRM notifications (both push and in-app foreground banner).
class CRMNotificationPayload {
  final String id;
  final String title;
  final String body;
  final String type; // 'followup', 'project', 'quotation', 'lead', 'general'
  final String? entityId;
  final String? targetRoute;
  final DateTime receivedAt;

  const CRMNotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.entityId,
    this.targetRoute,
    required this.receivedAt,
  });

  /// Derive the GoRouter target path for this notification
  String get effectiveRoute {
    if (targetRoute != null && targetRoute!.isNotEmpty) {
      return targetRoute!;
    }
    if (entityId != null && entityId!.isNotEmpty) {
      switch (type.toLowerCase()) {
        case 'followup':
        case 'follow_up':
          return '${AppRoutes.followups}/$entityId';
        case 'project':
          return '${AppRoutes.projects}/$entityId';
        case 'quotation':
          return '${AppRoutes.quotations}/$entityId';
        case 'lead':
          return '${AppRoutes.leads}/$entityId';
        case 'client':
          return '${AppRoutes.clients}/$entityId';
      }
    }
    return AppRoutes.notifications;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background FCM handler on Android - Native platform handles notification tray
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android Notification Channels
  static const String channelFollowups = 'followups_channel';
  static const String channelProjects = 'projects_channel';
  static const String channelUpdates = 'crm_updates_channel';
  static const String channelGeneral = 'general_channel';

  static const String _deviceIdPrefKey = 'hytide_device_id';

  // Navigation callbacks
  void Function(String followUpId)? onFollowUpNotificationTapped;
  void Function(String route)? onNotificationRouteTapped;

  // Stream for foreground in-app banners
  final StreamController<CRMNotificationPayload> _foregroundNotificationController =
      StreamController<CRMNotificationPayload>.broadcast();
  Stream<CRMNotificationPayload> get foregroundNotifications =>
      _foregroundNotificationController.stream;

  String? _currentUserId;
  bool _isInitialized = false;

  /// Initializes platform-specific notification subsystems.
  /// NOTE: Web explicitly DOES NOT initialize push or browser permissions.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (PlatformCapabilities.isWeb) {
      // Per Rule 6 & 22: Web must NOT request browser notification permission,
      // and must NOT call Notification.requestPermission() or register Web FCM.
      // In-app notifications in CRM notification center work via Firestore.
      return;
    }

    // Mobile (Android / iOS) Initialization
    await _initializeLocalNotifications();
    await _initializeAndroidChannels();
    await _initializeFCM();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _listenForegroundMessages();
  }

  /// Sets up FlutterLocalNotifications with Android configuration & action routing
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _routePayloadString(payload);
        }
      },
    );
  }

  /// Creates distinct Android notification channels per CRM domain
  Future<void> _initializeAndroidChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // 1. Follow-up Reminders (High Importance with Sound & Vibration)
    const followupsChannel = AndroidNotificationChannel(
      channelFollowups,
      'Follow-up Reminders',
      description: 'Reminders for scheduled client follow-ups and calls',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // 2. Project Updates (Default Importance)
    const projectsChannel = AndroidNotificationChannel(
      channelProjects,
      'Project Milestones & Updates',
      description: 'Updates on project status, deliverables and deadlines',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    // 3. CRM Updates (Default Importance)
    const crmUpdatesChannel = AndroidNotificationChannel(
      channelUpdates,
      'CRM Updates & Assignments',
      description: 'New leads, reassigned clients and team notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    // 4. General Notifications (Low Importance)
    const generalChannel = AndroidNotificationChannel(
      channelGeneral,
      'General CRM Alerts',
      description: 'General system announcements and status summaries',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await androidPlugin.createNotificationChannel(followupsChannel);
    await androidPlugin.createNotificationChannel(projectsChannel);
    await androidPlugin.createNotificationChannel(crmUpdatesChannel);
    await androidPlugin.createNotificationChannel(generalChannel);
  }

  /// Configures FCM handlers and checks initial terminated launch message
  Future<void> _initializeFCM() async {
    // Check if app was launched from terminated state via notification tap
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    // Handle notification click when app was backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
  }

  /// Listens for messages arriving while app is active in foreground
  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final payload = _parseRemoteMessage(message);

      // 1. Broadcast to in-app foreground banner stream
      _foregroundNotificationController.add(payload);

      // 2. Show native system notification bar alert
      _showAndroidLocalNotification(payload);
    });
  }

  CRMNotificationPayload _parseRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Hytide CRM';
    final body = notification?.body ?? data['body'] ?? '';
    final type = data['type'] as String? ?? 'general';
    final entityId = (data['entityId'] ?? data['followUpId'] ?? data['projectId'] ?? data['leadId'] ?? data['quotationId']) as String?;
    final targetRoute = data['route'] as String?;

    return CRMNotificationPayload(
      id: message.messageId ?? const Uuid().v4(),
      title: title,
      body: body,
      type: type,
      entityId: entityId,
      targetRoute: targetRoute,
      receivedAt: DateTime.now(),
    );
  }

  /// Displays local notification using the corresponding channel
  Future<void> _showAndroidLocalNotification(CRMNotificationPayload payload) async {
    if (PlatformCapabilities.isWeb) return;

    String channelId = channelGeneral;
    String channelName = 'General Alerts';
    Importance importance = Importance.defaultImportance;
    Priority priority = Priority.defaultPriority;

    switch (payload.type.toLowerCase()) {
      case 'followup':
      case 'follow_up':
        channelId = channelFollowups;
        channelName = 'Follow-up Reminders';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case 'project':
        channelId = channelProjects;
        channelName = 'Project Milestones';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      case 'lead':
      case 'client':
      case 'crm':
        channelId = channelUpdates;
        channelName = 'CRM Updates';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF0066FF),
      enableVibration: importance == Importance.high,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payloadString = payload.effectiveRoute;
    await _localNotifications.show(
      payload.hashCode,
      payload.title,
      payload.body,
      details,
      payload: payloadString,
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final payload = _parseRemoteMessage(message);
    _routePayload(payload);
  }

  void _routePayloadString(String route) {
    if (route.startsWith(AppRoutes.followups) && onFollowUpNotificationTapped != null) {
      final parts = route.split('/');
      if (parts.length > 2) {
        onFollowUpNotificationTapped?.call(parts.last);
      }
    }
    onNotificationRouteTapped?.call(route);
  }

  void _routePayload(CRMNotificationPayload payload) {
    if (payload.type == 'followup' && payload.entityId != null && payload.entityId!.isNotEmpty) {
      onFollowUpNotificationTapped?.call(payload.entityId!);
    }
    onNotificationRouteTapped?.call(payload.effectiveRoute);
  }

  // ─── Android Permission Handling ──────────────────────────────────────────

  /// Requests notification permission on Android (Android 13+ POST_NOTIFICATIONS).
  /// Should be called after user authentication or with an in-app explanatory prompt.
  Future<bool> requestAndroidNotificationPermission() async {
    if (!PlatformCapabilities.isMobileApp) return false;

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  // ─── FCM Device Token Management (users/{uid}/devices/{deviceId}) ──────────

  /// Registers or updates device token for authenticated user on Android/mobile.
  /// Strict check ensures Web NEVER registers FCM device tokens.
  Future<void> registerDeviceToken(String uid) async {
    if (!PlatformCapabilities.supportsPushNotifications) {
      return; // Never register device tokens on Web
    }

    _currentUserId = uid;
    try {
      final deviceId = await _getOrCreateDeviceId();
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      final platformName = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'mobile';

      final deviceRef = FirebaseFirestore.instance
          .collection(AppCollections.users)
          .doc(uid)
          .collection(AppCollections.devices)
          .doc(deviceId);

      await deviceRef.set({
        'deviceId': deviceId,
        'fcmToken': token,
        'platform': platformName,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Listen for token refreshes while user remains logged in
      _fcm.onTokenRefresh.listen((newToken) async {
        if (_currentUserId != null && _currentUserId == uid) {
          await deviceRef.set({
            'fcmToken': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (_) {}
  }

  /// Deactivates device token upon user sign-out to prevent notifications
  /// to logged-out devices.
  Future<void> deactivateDevice(String uid) async {
    if (!PlatformCapabilities.supportsPushNotifications) return;

    try {
      final deviceId = await _getOrCreateDeviceId();
      await FirebaseFirestore.instance
          .collection(AppCollections.users)
          .doc(uid)
          .collection(AppCollections.devices)
          .doc(deviceId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUserId = null;
    } catch (_) {}
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdPrefKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdPrefKey, deviceId);
    }
    return deviceId;
  }

  void dispose() {
    _foregroundNotificationController.close();
  }
}
