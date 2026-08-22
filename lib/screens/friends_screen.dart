import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/provider/bottom_navigation_provider.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/friend_requests_screen.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendScreen extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Map<String, dynamic>>? userData;
  const FriendScreen({super.key, required this.id, required this.userData});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('friend_requests')
                  .where('receiverId', isEqualTo: widget.id)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int count = 0;

                if (snapshot.hasData) {
                  count = snapshot.data!.docs.length;
                }

                return Badge(
                  isLabelVisible: count > 0,
                  alignment: Alignment.topRight,
                  offset: const Offset(-5, 6), // A
                  label: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(Icons.person_add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              FriendRequestsScreen(uid: widget.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('friends')
              .doc(widget.id)
              .collection('friends')
              .snapshots(),
          builder: (context, friendsSnapshot) {
            if (!friendsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var friendsData = friendsSnapshot.data!.docs;
            return friendsData.isEmpty
                ? Container(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'No friends yet',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(
                            'Add friends to start chatting with them',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.search),
                            onPressed: () {
                              context.read<BottomBarProvider>().changeIndex(2);
                            },
                            label: Text('Find Friends'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, usersSnapshot) {
                              if (!usersSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final users = usersSnapshot.data!.docs;

                              final userMap = {
                                for (var user in users) user.id: user,
                              };
                              return ListView.builder(
                                itemCount: friendsData.length,
                                itemBuilder: (context, index) {
                                  final friendId = friendsData[index].id;
                                  final friendSnapshot = userMap[friendId];

                                  // Guard against null snapshot or missing data
                                  if (friendSnapshot == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final friendData = friendSnapshot.data();
                                  final otherUser = UserModel.fromMap(
                                    friendData,
                                    friendId,
                                  );

                                  final currentUserData = widget.userData!
                                      .data();
                                  final currentUser = UserModel.fromMap(
                                    currentUserData!,
                                    widget.id,
                                  );

                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor,
                                        child: Text(
                                          friendData['username'][0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        friendData['username'].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: friendData['isOnline']
                                          ? Text(
                                              "Online",
                                              style: TextStyle(
                                                color: AppTheme.successColor,
                                              ),
                                            )
                                          : Text(
                                              "Offline",
                                              style: TextStyle(
                                                color: AppTheme.errorColor,
                                              ),
                                            ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (String value) {
                                          switch (value) {
                                            case 'Unfriend':
                                              // print('unfriend');
                                              break;
                                            case 'Message':
                                              Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) =>
                                                      ChatScreen(
                                                        currentUser:
                                                            currentUser,
                                                        otherUser: otherUser,
                                                      ),
                                                ),
                                              );
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          const PopupMenuItem<String>(
                                            value: 'Unfriend',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.person_remove,
                                              ),
                                              title: Text('Unfriend'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'Message',
                                            child: ListTile(
                                              leading: Icon(Icons.message),
                                              title: Text('Message'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }
}
