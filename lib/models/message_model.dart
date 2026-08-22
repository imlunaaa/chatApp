import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final String? imageUrl;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "senderId": senderId,
      "text": text,
      "type": type,
      "imageUrl": imageUrl,
      "createdAt": createdAt.millisecondsSinceEpoch,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map["createdAt"];

    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else {
      createdAt = DateTime.now();
    }
    return MessageModel(
      id: map["id"],
      senderId: map["senderId"],
      text: map["text"],
      type: map["type"],
      imageUrl: map["imageUrl"],
      createdAt: createdAt,
    );
  }
}
