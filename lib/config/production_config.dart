class ProductionConfig {
  // App Configuration
  static const String appName = 'CMMS Mobile App';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Database Configuration
  static const String databaseName = 'cmms_production.db';
  static const int databaseVersion = 1;


  // Push Notifications
  static const bool enablePushNotifications = true;
  static const String fcmServerKey = ''; // Set your FCM server key

  // Security
  static const bool enableBiometricAuth = true;
  static const bool enableAutoLogout = true;
  static const int autoLogoutMinutes = 30;


  // Logging
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = true;
  static const String analyticsKey = ''; // Set your analytics key

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

  // Support
  static const String supportEmail = 'support@cmms.com';
  static const String supportPhone = '+1-555-CMMS';
  static const String supportWebsite = 'https://support.cmms.com';

  // Legal
  static const String privacyPolicyUrl = 'https://cmms.com/privacy';
  static const String termsOfServiceUrl = 'https://cmms.com/terms';

  // Environment
  static const String environment = 'production';
  static const bool isDebugMode = false;

  // Validation
  static bool get isConfigured => appName.isNotEmpty &&
        appVersion.isNotEmpty;

  static Map<String, dynamic> toMap() => {
      'appName': appName,
      'appVersion': appVersion,
      'appBuildNumber': appBuildNumber,
      'databaseName': databaseName,
      'databaseVersion': databaseVersion,
      'enablePushNotifications': enablePushNotifications,
      'fcmServerKey': fcmServerKey,
      'enableBiometricAuth': enableBiometricAuth,
      'enableAutoLogout': enableAutoLogout,
      'autoLogoutMinutes': autoLogoutMinutes,
      'enableCrashReporting': enableCrashReporting,
      'enableAnalytics': enableAnalytics,
      'analyticsKey': analyticsKey,
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
      'supportPhone': supportPhone,
      'supportWebsite': supportWebsite,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsOfServiceUrl': termsOfServiceUrl,
      'environment': environment,
      'isDebugMode': isDebugMode,
    };
}
