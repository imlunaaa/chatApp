import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  final FirebaseFirestore _firestoreDatabase = FirebaseFirestore.instance;

  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  StreamSubscription<DatabaseEvent>? _presenceSubscription;

  Future<void> initializePresence(String uid) async {
    // Cancel existing listeners if re-initialized
    await dispose();

    final DatabaseReference userPresenceRef = _firebaseDatabase.ref(
      "presence/$uid",
    );
    final DocumentReference userFirestoreRef = _firestoreDatabase
        .collection('users')
        .doc(uid);
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Passed uid: $uid, Auth uid: ${currentUser?.uid}');
    // 1. Listen to RTDB connectivity state
    _connectionSubscription = _firebaseDatabase
        .ref('.info/connected')
        .onValue
        .listen((event) async {
          final bool isConnected = event.snapshot.value as bool? ?? false;
          print(isConnected);

          if (!isConnected) return;

          // Ensure clean state before registering a new disconnect trigger
          await userPresenceRef.onDisconnect().cancel();

          // Configure onDisconnect trigger
          await userPresenceRef.onDisconnect().set({
            'state': 'offline',
            'last_changed': ServerValue.timestamp,
          });

          // Mark user as online in RTDB
          await userPresenceRef.set({
            'state': 'online',
            'last_changed': ServerValue.timestamp,
          });
        });

    // 2. Mirror RTDB presence state into Firestore
    _presenceSubscription = userPresenceRef.onValue.listen((event) {
      print("RTDB event received");
      if (!event.snapshot.exists) return;

      // Safe cast for Realtime Database maps
      final rawData = event.snapshot.value;
      print("RTDB value: ${event.snapshot.value}");
      if (rawData is! Map) return;

      final Map<dynamic, dynamic> data = rawData;
      final String state = data['state']?.toString() ?? 'offline';
      final bool isOnline = state == 'online';

      userFirestoreRef
          .update({
            'isOnline': isOnline,
            if (!isOnline) 'lastActive': FieldValue.serverTimestamp(),
          })
          .catchError((e) {
            print("Firestore presence sync error: $e");
          });
    });
  }

  /// Explicitly sets the user offline (e.g., during manual logout)
  Future<void> setOffline(String uid) async {
    final DatabaseReference userPresenceRef = _firebaseDatabase.ref(
      "presence/$uid",
    );
    final DocumentReference userFirestoreRef = _firestoreDatabase
        .collection('users')
        .doc(uid);

    // Cancel server-side onDisconnect trigger to avoid duplicate triggers
    await userPresenceRef.onDisconnect().cancel();

    // Cancel active local streams
    await _connectionSubscription?.cancel();

    // Explicitly write offline state
    await userPresenceRef.set({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
    });

    await userFirestoreRef.update({
      'isOnline': false,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Clean up streams to prevent memory leaks
  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    await _presenceSubscription?.cancel();
    _connectionSubscription = null;
    _presenceSubscription = null;
  }
}
