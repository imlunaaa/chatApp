import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> deletedBy;
  final Map<String, DateTime> deletedAt;
  final Map<String, DateTime> lastSeenBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.deletedBy = const {},
    this.deletedAt = const {},
    this.lastSeenBy = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt.map(
        (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
      ),
      'lastSeenBy': lastSeenBy.map(
        (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
      ),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map) {
    Map<String, DateTime> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(
            map['lastSeenBy'],
          ),
          lastSeenMap = rawLastSeen.map(
            (key, value) => MapEntry(
              key,
              value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
            ),
          );
    } // MapEntry

    Map<String, DateTime> deleteAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(
            map['deletedAt'],
          ),
          deleteAtMap = rawDeletedAt.map(
            (key, value) => MapEntry(
              key,
              value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
            ),
          );
    }

    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] is Timestamp
                ? (map['lastMessageTime'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime']))
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      deletedBy: Map<String, bool>.from(map['deletedBy'] ?? {}),
      deletedAt: deleteAtMap,
      lastSeenBy: lastSeenMap,
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(map['createdAt']),

      updatedAt: map['updatedAt'] is Timestamp
          ? map['updatedAt'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? deletedBy,
    Map<String, DateTime>? deletedAt,
    Map<String, DateTime>? lastSeenBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSeenBy: lastSeenBy ?? this.lastSeenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isLastMessageMine(String currentUserId) {
    return lastMessageSenderId == currentUserId;
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  bool isMessageSeen(String currentUserId, String otherUserId) {
    if (lastMessageSenderId == currentUserId) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);

      if (otherUserLastSeen != null && lastMessageTime != null) {
        return otherUserLastSeen.isAfter(lastMessageTime!) ||
            otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
      }
    }
    return false;
  }

  bool containsUser(String uid) {
    return participants.contains(uid);
  }

  bool get hasUnreadMessages => unreadCount.values.any((count) => count > 0);

  bool hasUnreadFor(String uid) {
    return (unreadCount[uid] ?? 0) > 0;
  }
}
