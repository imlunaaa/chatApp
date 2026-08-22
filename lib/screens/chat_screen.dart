import 'dart:io';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/utils/date_utils.dart';
import 'package:chat_app/widgets/message_bubble.dart';
import 'package:chat_app/widgets/message_input.dart' show MessageInput;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel otherUser;
  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final String chatId;
  File? image;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;
  bool _isSending = false;

  Future<void> pickImage(ImageSource source) async {
    // Prevent multiple overlapping calls
    if (_isPicking) return;

    _isPicking = true;

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          image = File(pickedFile.path);
          print("Image selected: ${image!.path}");
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void removeSelectedImage() {
    setState(() {
      image = null;
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    // Nothing to send
    if (text.isEmpty && image == null) return;

    // Prevent double sends while one is in flight
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      if (image != null) {
        final fileToSend = image!;

        // Clear input immediately so UI feels responsive
        messageController.clear();
        setState(() {
          image = null;
        });

        await _chatService.sendImageMessage(
          currentUserId: widget.currentUser.uid,
          receiverId: widget.otherUser.uid,
          imageFile: fileToSend,
          caption: text,
        );
      } else {
        messageController.clear();

        await _chatService.sendMessage(
          currentUserId: widget.currentUser.uid,
          receiverId: widget.otherUser.uid,
          text: text,
        );
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String formatLastSeen(DateTime? lastActive) {
    if (lastActive == null) return "Last seen: Unknown";

    final now = DateTime.now();
    final difference = now.difference(lastActive.toLocal());

    if (difference.inSeconds < 60) {
      return "Last seen: Just now";
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return "Last seen: ${mins}m ago";
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return "Last seen: ${hours}h ago";
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return "Last seen: ${days}d ago";
    } else {
      // Show regular date if older than a week
      return "Last seen: ${lastActive.day}/${lastActive.month}/${lastActive.year}";
    }
  }

  @override
  void initState() {
    super.initState();

    chatId = _chatService.generateChatId(
      widget.currentUser.uid,
      widget.otherUser.uid,
    );

    _chatService.markAsRead(
      chatId: chatId,
      currentUserId: widget.currentUser.uid,
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(radius: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  Text(
                    widget.otherUser.isOnline
                        ? "Online"
                        : widget.otherUser.lastActive != null
                        ? formatLastSeen(widget.otherUser.lastActive!.toDate())
                        : "Offline",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: widget.otherUser.isOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Container(
          child: Column(
            children: [
              Expanded(child: _messageList()),
              MessageInput(
                controller: messageController,
                onSend: sendMessage,
                onCamera: () => pickImage(ImageSource.camera),
                onGallery: () => pickImage(ImageSource.gallery),
                onRemoveImage: removeSelectedImage,
                isSending: _isSending,
                selectedImage: image,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.pixels(1000.0),
          reverse: true,
          controller: scrollController,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final message = MessageModel.fromMap(
              docs[index].data() as Map<String, dynamic>,
            );

            bool showSeparator = false;

            if (index == docs.length - 1) {
              // Oldest message
              showSeparator = true;
            } else {
              final previousMessage = MessageModel.fromMap(
                docs[index + 1].data() as Map<String, dynamic>,
              );

              final current = message.createdAt;
              final previous = previousMessage.createdAt;

              final differentDay =
                  current.year != previous.year ||
                  current.month != previous.month ||
                  current.day != previous.day;

              final fifteenMinutes =
                  current.difference(previous).inMinutes.abs() >= 15;

              showSeparator = differentDay || fifteenMinutes;
            }

            return Column(
              children: [
                if (showSeparator)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          formatChatSeparator(message.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                MessageBubble(
                  message: message,
                  isMe: message.senderId == widget.currentUser.uid,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
