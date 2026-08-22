import 'dart:io';

import 'package:chat_app/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService._();

  static final instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get chatCollection => _firestore.collection("chats");

  String generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join("_");
  }

  Future<void> createChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = generateChatId(currentUserId, otherUserId);

    final doc = chatCollection.doc(chatId);

    if ((await doc.get()).exists) return;

    await doc.set({
      "id": chatId,
      "participants": [currentUserId, otherUserId],
      "lastMessage": "",
      "lastMessageTime": null,
      "lastMessageSenderId": "",
      "unreadCount": {currentUserId: 0, otherUserId: 0},
      "deletedBy": {},
      "deletedAt": {},
      "lastSeenBy": {},
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String receiverId,
    required String text,
  }) async {
    await _sendMessageInternal(
      currentUserId: currentUserId,
      receiverId: receiverId,
      text: text,
      type: "text",
    );
  }

  Future<void> sendImageMessage({
    required String currentUserId,
    required String receiverId,
    required File imageFile,
    String caption = "",
  }) async {
    final imageUrl = await CloudinaryService.uploadImage(imageFile);

    if (imageUrl == null) {
      throw Exception("Image upload failed");
    }

    await _sendMessageInternal(
      currentUserId: currentUserId,
      receiverId: receiverId,
      text: caption,
      type: "image",
      imageUrl: imageUrl,
    );
  }

  Future<void> _sendMessageInternal({
    required String currentUserId,
    required String receiverId,
    required String text,
    required String type,
    String? imageUrl,
  }) async {
    final chatId = generateChatId(currentUserId, receiverId);
    final chatDoc = chatCollection.doc(chatId);

    if (!(await chatDoc.get()).exists) {
      await createChat(currentUserId: currentUserId, otherUserId: receiverId);
    }

    final messageRef = chatDoc.collection("messages").doc();
    // final now = DateTime.now();

    await messageRef.set({
      "id": messageRef.id,
      "senderId": currentUserId,
      "text": text,
      "type": type,
      "imageUrl": imageUrl,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final lastMessagePreview = type == "image" ? "📷 Photo" : text;

    await chatDoc.update({
      "lastMessage": lastMessagePreview,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "lastMessageSenderId": currentUserId,
      "updatedAt": FieldValue.serverTimestamp(),
      "unreadCount.$receiverId": FieldValue.increment(1),
    });
  }

  Stream<QuerySnapshot<Object?>> getChats(String uid) {
    return chatCollection
        .where("participants", arrayContains: uid)
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    await chatCollection.doc(chatId).update({
      "unreadCount.$currentUserId": 0,
      "lastSeenBy.$currentUserId": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return chatCollection
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}
