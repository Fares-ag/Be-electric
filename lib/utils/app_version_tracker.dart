// App Version Tracker
// Prevents old APK data from syncing to the database

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionTracker {
  static const String _buildNumberKey = 'app_build_number';
  static const String _lastSyncVersionKey = 'last_sync_app_version';

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  /// Get current build number
  static Future<int> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return int.tryParse(packageInfo.buildNumber) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  /// Check if this is a newer version than last sync
  static Future<bool> isNewerVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncVersion = prefs.getString(_lastSyncVersionKey);
      final currentVersion = await getCurrentVersion();
      final currentBuild = await getCurrentBuildNumber();

      if (lastSyncVersion == null) {
        // First time, save current version
        await prefs.setString(_lastSyncVersionKey, currentVersion);
        await prefs.setInt(_buildNumberKey, currentBuild);
        return true;
      }

      // Compare versions
      if (currentVersion != lastSyncVersion) {
        // Version changed, update stored version
        await prefs.setString(_lastSyncVersionKey, currentVersion);
        await prefs.setInt(_buildNumberKey, currentBuild);
        return _compareVersions(currentVersion, lastSyncVersion) > 0;
      }

      // Same version, check build number
      final lastBuild = prefs.getInt(_buildNumberKey) ?? 1;
      if (currentBuild > lastBuild) {
        await prefs.setInt(_buildNumberKey, currentBuild);
        return true;
      }

      return false;
    } catch (e) {
      // On error, assume it's safe to sync
      return true;
    }
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.2.4")
  /// Returns: >0 if v1 > v2, 0 if equal, <0 if v1 < v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }

  /// Mark that sync has completed for current version
  static Future<void> markSyncCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await getCurrentVersion();
      final currentBuild = await getCurrentBuildNumber();
      await prefs.setString(_lastSyncVersionKey, currentVersion);
      await prefs.setInt(_buildNumberKey, currentBuild);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get last sync version info
  static Future<Map<String, dynamic>> getVersionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await getCurrentVersion();
      final currentBuild = await getCurrentBuildNumber();
      final lastSyncVersion = prefs.getString(_lastSyncVersionKey) ?? 'unknown';
      final lastBuild = prefs.getInt(_buildNumberKey) ?? 0;

      return {
        'currentVersion': currentVersion,
        'currentBuild': currentBuild,
        'lastSyncVersion': lastSyncVersion,
        'lastBuild': lastBuild,
        'isNewer': await isNewerVersion(),
      };
    } catch (e) {
      return {
        'currentVersion': 'unknown',
        'currentBuild': 0,
        'lastSyncVersion': 'unknown',
        'lastBuild': 0,
        'isNewer': true,
      };
    }
  }

  /// Reset version tracking (use with caution)
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncVersionKey);
      await prefs.remove(_buildNumberKey);
    } catch (e) {
      // Ignore errors
    }
  }
}

