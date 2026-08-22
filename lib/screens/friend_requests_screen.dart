import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

// ignore: must_be_immutable
class FriendRequestsScreen extends StatefulWidget {
  String uid;
  FriendRequestsScreen({super.key, required this.uid});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  Future<void> acceptFriendRequest(
    String requestId,
    String senderId,
    String receiverId,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update request
    final requestRef = FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId);

    batch.update(requestRef, {'status': 'accepted'});

    // Add sender -> receiver
    final senderFriendRef = FirebaseFirestore.instance
        .collection('friends')
        .doc(senderId)
        .collection('friends')
        .doc(receiverId);

    batch.set(senderFriendRef, {'since': FieldValue.serverTimestamp()});

    // Add receiver -> sender
    final receiverFriendRef = FirebaseFirestore.instance
        .collection('friends')
        .doc(receiverId)
        .collection('friends')
        .doc(senderId);

    batch.set(receiverFriendRef, {'since': FieldValue.serverTimestamp()});

    await batch.commit();

    EasyLoading.showSuccess("Friend request accepted!");
  }

  @override
  Widget build(BuildContext context) {
    var ht = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Friend Requests'), centerTitle: true),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('friend_requests')
              .where('receiverId', isEqualTo: widget.uid)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var snapData = asyncSnapshot.data?.docs;
            return snapData!.isEmpty
                ? Container(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'No friends requests',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(
                            'You have no pending friend requests at the moment.',
                            textAlign: TextAlign.center,
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
                    height: ht,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, asyncSnapshot) {
                              if (asyncSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              var users = asyncSnapshot.data?.docs ?? [];
                              return _friendRequestList(snapData, users);
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

  ListView _friendRequestList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? snapData,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
  ) {
    return ListView.builder(
      itemCount: snapData?.length ?? 0,
      itemBuilder: (context, index) {
        var doc = snapData![index];
        var user = users.firstWhere((u) => u.id == doc['senderId']);
        return Card(
          child: ListTile(
            title: Text(
              user['username'].toString().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text('Sent you a friend request'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => acceptFriendRequest(
                    doc.id,
                    doc['senderId'],
                    doc['receiverId'],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    // Handle decline friend request
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
