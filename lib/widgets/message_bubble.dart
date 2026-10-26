import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/screens/image_preview_screen.dart';
import 'package:chat_app/screens/web_view.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/utils/cloudinary_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  bool get _isImage => message.type == "image";
  bool get _hasCaption => message.text.trim().isNotEmpty;

  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri url = Uri.parse(link.url);

    try {
      // Launch in external browser or application
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () =>
            _isImage ? null : _showCustomDialog(context, message.text),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: _isImage
              ? const EdgeInsets.all(4)
              : const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isImage) _buildImage(context),
              if (_isImage && _hasCaption) const SizedBox(height: 6),
              if (!_isImage || _hasCaption)
                Padding(
                  padding: _isImage
                      ? const EdgeInsets.symmetric(horizontal: 8)
                      : EdgeInsets.zero,
                  child: InkWell(
                    child: Text.rich(
                      TextSpan(
                        children: message.text.split(' ').map((word) {
                          final isLink =
                              word.startsWith('http://') ||
                              word.startsWith('https://');
                          return TextSpan(
                            text: '$word ',
                            style: TextStyle(
                              color: isLink
                                  ? (isMe
                                        ? Colors.lightBlueAccent
                                        : Colors.blue)
                                  : (isMe ? Colors.white : Colors.black),
                              decoration: isLink
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    onTap: () {
                      final match = RegExp(
                        r'https?://\S+',
                      ).firstMatch(message.text);
                      if (match == null) return; // not a link, do nothing
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewScreen(url: match.group(0)!),
                        ),
                      );
                    },
                  ),
                  // child: Linkify(
                  //   text: message.text,
                  //   onOpen: _onOpenLink,
                  //   style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  //   linkStyle: const TextStyle(
                  //     color: Colors.blue,
                  //     decoration: TextDecoration.underline,
                  //   ),
                  // ),
                ),
              SizedBox(height: _isImage ? 4 : 5),
              Padding(
                padding: _isImage
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : EdgeInsets.zero,
                child: Text(
                  DateFormat("hh:mm a").format(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              if (_isImage) const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDialog(BuildContext context, String _message) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Text'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _message));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context) {
    final thumbUrl = CloudinaryUtils.thumbnail(message.imageUrl ?? "");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageUrl: CloudinaryUtils.fullSize(
                message.imageUrl ?? "",
                heroTag: message.id,
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: message.id,
          child: CachedNetworkImage(
            imageUrl: thumbUrl,
            fit: BoxFit.cover,
            width: 220,
            height: 220,
            placeholder: (context, url) => Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              color: Colors.grey.shade300,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              color: Colors.grey.shade400,
              child: const Icon(Icons.broken_image, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}
