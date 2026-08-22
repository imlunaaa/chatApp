import 'package:chat_app/components/friendRequestCard.dart';
import 'package:chat_app/components/textformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class FindFriendsScreen extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Map<String, dynamic>>? userData;
  const FindFriendsScreen({
    super.key,
    required this.id,
    required this.userData,
  });

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<String> search = ValueNotifier('');

  void addFriend(String currentUserId, String friendId) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: null,
      title: 'Add Friend?',
      confirmBtnText: 'YES',
      cancelBtnText: 'No',
      onConfirmBtnTap: () {
        FirebaseFirestore.instance.collection('friend_requests').add({
          'senderId': currentUserId,
          'receiverId': friendId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context);
      },
    );
  }

  void cancelRequest(String currentUserId, String friendId) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: null,
      title: 'Cancel Friend Request?',
      confirmBtnText: 'YES',
      cancelBtnText: 'No',
      onConfirmBtnTap: () async {
        // Query the friend_requests collection to find the request document
        final querySnapshot = await FirebaseFirestore.instance
            .collection('friend_requests')
            .where('senderId', isEqualTo: currentUserId)
            .where('receiverId', isEqualTo: friendId)
            .where('status', isEqualTo: 'pending')
            .get();

        // If a matching document is found, delete it
        Navigator.pop(context);
        EasyLoading.show();
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.delete();
        }
        EasyLoading.showSuccess('Friend request canceled');
        EasyLoading.dismiss();
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Find People')),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!asyncSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var users = asyncSnapshot.data!.docs.where((doc) {
              return doc.id != widget.userData!.id;
            }).toList();
            return users.isEmpty
                ? Container(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'No Users Found',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(
                            'Register your friends to start chatting with them',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          // ElevatedButton.icon(
                          //   icon: Icon(Icons.search),
                          //   onPressed: () {
                          //     context.read<BottomBarProvider>().changeIndex(2);
                          //   },
                          //   label: Text('Find Friends'),
                          // ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: searchController,
                          decoration: textInputDecoration(
                            label: 'Search for friends',
                            prefixIcon: Icons.search,
                          ),
                          onChanged: (value) {
                            search.value = value.toLowerCase();
                          },
                        ),
                        const Divider(height: 24.0),
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: search,
                            builder: (context, value, child) {
                              final filteredUsers = users.where((user) {
                                final username = user['username']
                                    .toString()
                                    .toLowerCase();

                                return username.contains(value);
                              }).toList();

                              if (filteredUsers.isEmpty) {
                                return const Center(
                                  child: Text('No users found'),
                                );
                              }
                              return StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('friends')
                                    .doc(widget.id)
                                    .collection('friends')
                                    .snapshots(),
                                builder: (context, friendsSnapshot) {
                                  if (!friendsSnapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  // IDs of users who are already friends
                                  final friendIds = friendsSnapshot.data!.docs
                                      .map((doc) => doc.id)
                                      .toSet();

                                  // Remove friends from the search results
                                  final availableUsers = filteredUsers
                                      .where(
                                        (user) => !friendIds.contains(user.id),
                                      )
                                      .toList();
                                  return StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection('friend_requests')
                                        .where('status', isEqualTo: 'pending')
                                        .snapshots(),

                                    builder: (context, requestSnapshot) {
                                      if (!requestSnapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final requests = requestSnapshot
                                          .data!
                                          .docs
                                          .where((doc) {
                                            return doc['status'] == 'pending' &&
                                                (doc['senderId'] == widget.id ||
                                                    doc['receiverId'] ==
                                                        widget.id);
                                          })
                                          .toList();

                                      return ListView.builder(
                                        itemCount: availableUsers.length,
                                        itemBuilder: (context, index) {
                                          final user = availableUsers[index];

                                          final request = requests.where((doc) {
                                            return (doc['senderId'] ==
                                                        user.id &&
                                                    doc['receiverId'] ==
                                                        widget.id) ||
                                                (doc['receiverId'] == user.id &&
                                                    doc['senderId'] ==
                                                        widget.id);
                                          }).toList();

                                          bool requestSent = false;
                                          bool requestReceived = false;
                                          String? requestId;

                                          if (request.isNotEmpty) {
                                            requestId = request.first.id;

                                            if (request.first['senderId'] ==
                                                widget.id) {
                                              requestSent = true;
                                            } else {
                                              requestReceived = true;
                                            }
                                          }
                                          return friendRequestCard(
                                            user['username'][0].toUpperCase(),
                                            availableUsers,
                                            index,
                                            widget.id,
                                            addFriend,
                                            requestSent,
                                            cancelRequest,
                                            requestReceived,
                                          );
                                        },
                                      );
                                    },
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
