import 'dart:convert';
import 'package:chat_app/components/show_update_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class AppUpdateService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Initialize Remote Config & Fetch Latest Values
  static Future<void> initRemoteConfig() async {
    // Fallback defaults
    await _remoteConfig.setDefaults(const {
      'latest_app_version': '1.0.0',
      'min_required_version': '1.0.0',
      'update_changelog': '["General updates and fixes"]',
    });

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 0), // 0 during debug
      ),
    );
    await _remoteConfig.fetchAndActivate();

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Failed to fetch Remote Config: $e');
    }
  }

  /// 2. Update user profile in Firestore with their current app version
  static Future<void> updateUserAppVersionInFirestore(
    String currentVersion,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'appVersion': currentVersion,
        'lastActive': FieldValue.serverTimestamp(),
        'platform': getPlatformName(),
      }, SetOptions(merge: true));
    }
  }

  /// 3. Check for available updates
  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;
    print('Current app version: $currentVersion');

    // Save app version to user's Firestore record
    await updateUserAppVersionInFirestore(currentVersion);

    final String latestVersion = _remoteConfig.getString('latest_app_version');
    final String minRequiredVersion = _remoteConfig.getString(
      'min_required_version',
    );
    final String rawChangelog = _remoteConfig.getString('update_changelog');
    final String storeUrl = _remoteConfig.getString('apkUrl');

    List<String> changelog = [];
    try {
      changelog = List<String>.from(jsonDecode(rawChangelog));
    } catch (_) {
      changelog = ['Bug fixes and performance improvements'];
    }

    final bool isForceUpdate = _isVersionLower(
      currentVersion,
      minRequiredVersion,
    );
    final bool isSoftUpdate = _isVersionLower(currentVersion, latestVersion);

    if ((isForceUpdate || isSoftUpdate) && context.mounted) {
      showUpdateDialog(
        context: context,
        currentVersion: currentVersion,
        newVersion: latestVersion,
        changelog: changelog,
        isForceUpdate: isForceUpdate,
        storeUrl: storeUrl,
      );
    }
  }

  /// Compare semantic version strings (e.g., "1.2.0" < "2.0.0")
  static bool _isVersionLower(String current, String target) {
    List<int> cParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> tParts = target
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < cParts.length; i++) {
      if (i >= tParts.length) return false;
      if (cParts[i] < tParts[i]) return true;
      if (cParts[i] > tParts[i]) return false;
    }
    return false;
  }
}

String getPlatformName() {
  return defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';
}
