import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Card friendRequestCard(
  String initials,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredUsers,
  int index,
  String uid,
  Function addFriend,
  bool requestSent,
  Function cancelRequest,
  bool requestReceived,
) {
  return Card(
    elevation: 3,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      title: Text(
        filteredUsers[index]['username'],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        filteredUsers[index]['email'],
        style: const TextStyle(fontSize: 10),
      ),
      trailing: requestReceived
          ? ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,

                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 3.0,
                ),
              ),
              icon: Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Accept',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            )
          : requestSent
          ? OutlinedButton.icon(
              onPressed: () {
                cancelRequest(uid, filteredUsers[index].id);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 3.0,
                ),
              ),
              icon: Icon(
                Icons.cancel,
                size: 16,
                color: AppTheme.secondaryButtonColor,
              ),
              label: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.secondaryButtonColor,
                  fontSize: 10,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () {
                addFriend(uid, filteredUsers[index].id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 3.0,
                ),
              ),
              icon: Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Add Friend',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
    ),
  );
}
