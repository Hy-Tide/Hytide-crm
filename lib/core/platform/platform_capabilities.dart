// lib/core/platform/platform_capabilities.dart
import 'package:flutter/foundation.dart';

/// Centralized platform detection and capability resolver for Hytide CRM.
/// Prevents scattering `if (kIsWeb)` or `defaultTargetPlatform` across widgets.
class PlatformCapabilities {
  PlatformCapabilities._();

  /// True if running in a web browser (desktop or mobile browser)
  static bool get isWeb => kIsWeb;

  /// True if running on Android OS natively
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True if running on iOS natively
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// True if running as a native mobile application (Android or iOS)
  static bool get isMobileApp => isAndroid || isIOS;

  /// Push notifications via FCM are only supported on native mobile (Android/iOS).
  /// Web must NEVER request browser notification permissions.
  static bool get supportsPushNotifications => isMobileApp;

  /// Browser push notifications are explicitly disabled.
  static bool get supportsBrowserNotifications => false;

  /// Native mobile navigation (e.g. bottom bar) vs Web navigation (sidebar / top bar).
  static bool get useMobileNavigation => isMobileApp;
}
