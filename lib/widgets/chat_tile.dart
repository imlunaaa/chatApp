import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/utils/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  final UserModel currentUser;
  final ChatModel chat;

  const ChatTile({super.key, required this.currentUser, required this.chat});

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.getOtherParticipant(currentUser.uid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(otherUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        final user = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          minVerticalPadding: 2,
          visualDensity: const VisualDensity(vertical: -3),
          dense: false,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              user["username"][0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.secondaryColor,
                fontSize: 20,
              ),
            ),
          ),
          title: Text(
            user["username"],
            style: chat.getUnreadCount(currentUser.uid) > 0
                ? TextStyle(fontWeight: FontWeight.w900)
                : TextStyle(fontWeight: FontWeight.w500),
          ),
          titleTextStyle: TextStyle(
            height: 0,
            color: AppTheme.primaryColor,
            fontSize: 18,
          ),
          subtitle: Text(
            chat.isLastMessageMine(currentUser.uid)
                ? "You: ${chat.lastMessage}"
                : chat.lastMessage ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: chat.getUnreadCount(currentUser.uid) > 0
                ? TextStyle(fontWeight: FontWeight.bold)
                : TextStyle(fontWeight: FontWeight.normal),
          ),
          subtitleTextStyle: TextStyle(color: Colors.grey),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTime(chat.lastMessageTime),
                style: TextStyle(color: Colors.grey),
              ),
              if (chat.getUnreadCount(currentUser.uid) > 0)
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 8,
                  child: Text(
                    chat.getUnreadCount(currentUser.uid).toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  currentUser: currentUser,
                  otherUser: UserModel.fromMap(user, otherUserId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
