import 'package:flutter/material.dart';

import '../../../core/services/app_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    final Color bubbleColor = isUser ? AppTheme.primary : AppTheme.panel;
    final Color textColor = isUser ? Colors.white : AppTheme.ink;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppFormatter.time(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.72)
                    : AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
