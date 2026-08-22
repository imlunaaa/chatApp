import 'package:chat_app/components/appDrawer.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String id;
  const HomeScreen({super.key, required this.id});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: Text("User profile not found.")),
          );
        }

        final userDataDoc = snapshot.data!;
        final userData = userDataDoc.data()!;

        String fname = (userData['firstname'] ?? '').toString().toUpperCase();
        String lname = (userData['lastname'] ?? '').toString().toUpperCase();
        final bool isOnline = userData['isOnline'] ?? false;

        final currentUser = UserModel.fromMap(userData, widget.id);

        return SafeArea(
          child: Scaffold(
            drawer: appDrawer(
              fname: fname,
              lname: lname,
              userEmail: userEmail,
              uid: widget.id,
            ),
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Messages'),
                  Container(
                    margin: const EdgeInsets.all(4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications),
                ),
              ],
            ),
            body: StreamBuilder(
              stream: ChatService.instance.getChats(widget.id),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!asyncSnapshot.hasData ||
                    asyncSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No conversations yet."));
                }

                final chatDocs = asyncSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatData =
                        chatDocs[index].data() as Map<String, dynamic>;
                    final chat = ChatModel.fromMap(chatData);
                    return ChatTile(currentUser: currentUser, chat: chat);
                  },
                );
              },
            ),
            floatingActionButton: ElevatedButton.icon(
              icon: const Icon(Icons.message),
              onPressed: () {},
              label: const Text("New Chat"),
            ),
          ),
        );
      },
    );
  }
}
