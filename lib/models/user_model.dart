import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final bool isOnline;
  final Timestamp? lastActive;

  UserModel({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    required this.isOnline,
    this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstname': firstname,
      'lastname': lastname,
      'username': username,
      'email': email,
      'isOnline': isOnline,
      'lastActive': lastActive,
    };
  }
}
