import 'package:intl/intl.dart';

String formatTime(DateTime? date) {
  if (date == null) return '';

  final now = DateTime.now();

  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return DateFormat.jm().format(date);
  }

  if (now.difference(date).inDays == 1) {
    return "Yesterday";
  }

  if (now.difference(date).inDays < 7) {
    return DateFormat.E().format(date);
  }

  return DateFormat("MMM d").format(date);
}

String formatChatSeparator(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDay = DateTime(date.year, date.month, date.day);

  if (messageDay == today) {
    return DateFormat('h:mm a').format(date); // 9:30 PM
  }

  if (messageDay == yesterday) {
    return "Yesterday ${DateFormat('h:mm a').format(date)}";
  }

  return DateFormat('MMM d AT h:mm a').format(date).toUpperCase();
}
