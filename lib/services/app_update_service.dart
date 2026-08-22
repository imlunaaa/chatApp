import 'dart:convert';
import 'package:chat_app/components/show_update_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class AppUpdateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Where the update config document lives.
  static const String _configCollection = 'config';
  static const String _configDocId = 'app_update';

  // Cached values after fetch, so we don't have to pass them around.
  static String _latestVersion = '1.0.0';
  static String _minRequiredVersion = '1.0.0';
  static List<String> _changelog = ['General updates and fixes'];
  static String _storeUrl = '';

  /// 1. Fetch the update config document from Firestore.
  static Future<void> initRemoteConfig() async {
    try {
      final doc = await _firestore
          .collection(_configCollection)
          .doc(_configDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _latestVersion =
            data['latest_app_version'] as String? ?? _latestVersion;
        _minRequiredVersion =
            data['min_required_version'] as String? ?? _minRequiredVersion;
        _storeUrl = data['apkUrl'] as String? ?? _storeUrl;

        final rawChangelog = data['update_changelog'];
        if (rawChangelog is List) {
          _changelog = List<String>.from(rawChangelog);
        } else if (rawChangelog is String) {
          // In case you store it as a JSON-encoded string instead of an array.
          try {
            _changelog = List<String>.from(jsonDecode(rawChangelog));
          } catch (_) {
            _changelog = ['Bug fixes and performance improvements'];
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch update config from Firestore: $e');
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
    // Make sure config has been fetched at least once.
    await initRemoteConfig();

    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;
    debugPrint('Current app version: $currentVersion');

    // Save app version to user's Firestore record
    await updateUserAppVersionInFirestore(currentVersion);

    final bool isForceUpdate = _isVersionLower(
      currentVersion,
      _minRequiredVersion,
    );
    final bool isSoftUpdate = _isVersionLower(currentVersion, _latestVersion);

    if ((isForceUpdate || isSoftUpdate) && context.mounted) {
      showUpdateDialog(
        context: context,
        currentVersion: currentVersion,
        newVersion: _latestVersion,
        changelog: _changelog,
        isForceUpdate: isForceUpdate,
        storeUrl: _storeUrl,
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
