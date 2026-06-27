import 'app_config.dart';

/// Production-only configuration. Legal and support values come from [AppConfig]
/// (--dart-define at build time). Do not hardcode placeholder URLs here.
class ProductionConfig {
  // App Configuration
  static const String appName = 'Be Electric Requestor';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Database Configuration
  static const String databaseName = 'cmms_production.db';
  static const int databaseVersion = 1;

  // Push notifications are not used in v1 (no APNs / FCM).
  static const bool enablePushNotifications = false;
  static const String fcmServerKey = '';

  // Security
  static const bool enableBiometricAuth = false;
  static const bool enableAutoLogout = true;
  static const int autoLogoutMinutes = 30;

  // Crash/analytics SDKs are not wired in v1.
  static const bool enableCrashReporting = false;
  static const bool enableAnalytics = false;
  static const String analyticsKey = '';

  // Feature Flags
  static const bool enableQRScanner = true;
  static const bool enableCameraCapture = true;
  static const bool enableOfflineMode = true;
  static const bool enableSignatureCapture = true;

  // UI Configuration
  static const bool enableDarkMode = false;
  static const bool enableAnimations = true;
  static const double animationDuration = 300;

  // Performance
  static const int maxImageSizeMB = 5;
  static const int maxCacheSizeMB = 100;
  static const bool enableImageCompression = true;

  // Support & legal — from AppConfig / dart-define
  static String get supportEmail => AppConfig.supportEmail;
  static const String supportPhone = '';
  static String get supportWebsite => AppConfig.supportUrl;
  static String get privacyPolicyUrl => AppConfig.privacyPolicyUrl;
  static String get termsOfServiceUrl => AppConfig.termsOfServiceUrl;

  // Environment
  static const String environment = 'production';
  static const bool isDebugMode = false;

  static bool get isConfigured =>
      appName.isNotEmpty &&
      appVersion.isNotEmpty &&
      AppConfig.hasValidLegalConfig &&
      AppConfig.hasValidSupabaseConfig;

  static Map<String, dynamic> toMap() => {
      'appName': appName,
      'appVersion': appVersion,
      'appBuildNumber': appBuildNumber,
      'databaseName': databaseName,
      'databaseVersion': databaseVersion,
      'enablePushNotifications': enablePushNotifications,
      'enableBiometricAuth': enableBiometricAuth,
      'enableAutoLogout': enableAutoLogout,
      'autoLogoutMinutes': autoLogoutMinutes,
      'enableCrashReporting': enableCrashReporting,
      'enableAnalytics': enableAnalytics,
      'enableQRScanner': enableQRScanner,
      'enableCameraCapture': enableCameraCapture,
      'enableOfflineMode': enableOfflineMode,
      'enableSignatureCapture': enableSignatureCapture,
      'enableDarkMode': enableDarkMode,
      'enableAnimations': enableAnimations,
      'animationDuration': animationDuration,
      'maxImageSizeMB': maxImageSizeMB,
      'maxCacheSizeMB': maxCacheSizeMB,
      'enableImageCompression': enableImageCompression,
      'supportEmail': supportEmail,
      'supportWebsite': supportWebsite,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsOfServiceUrl': termsOfServiceUrl,
      'environment': environment,
      'isDebugMode': isDebugMode,
    };
}
