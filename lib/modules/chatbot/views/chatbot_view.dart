import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat_message_model.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/chat_bubble.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ChatbotController _controller = Get.find<ChatbotController>();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final Worker _messagesWorker;
  late final Worker _loadingWorker;

  static const List<String> _quickPrompts = <String>[
    'Ringkas kondisi keuanganku',
    'Apakah pengeluaranku boros?',
    'Beri saran hemat minggu ini',
  ];

  @override
  void initState() {
    super.initState();
    _messagesWorker = ever<List<ChatMessageModel>>(
      _controller.messages,
      (_) => _scrollToBottom(),
    );
    _loadingWorker = ever<bool>(
      _controller.isLoading,
      (_) => _scrollToBottom(),
    );
  }

  @override
  void dispose() {
    _messagesWorker.dispose();
    _loadingWorker.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage([String? preset]) {
    if (_controller.isLoading.value) {
      return;
    }

    final String text = preset ?? _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }

    _inputController.clear();
    _controller.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asisten Finansial')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _AssistantHeader(
                prompts: _quickPrompts,
                onPromptTap: _sendMessage,
              ),
            ),
            Expanded(
              child: Obx(() {
                final bool isLoading = _controller.isLoading.value;
                final int extraItem = isLoading ? 1 : 0;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _controller.messages.length + extraItem,
                  itemBuilder: (BuildContext context, int index) {
                    if (isLoading && index == _controller.messages.length) {
                      return const _TypingIndicator();
                    }

                    final ChatMessageModel message =
                        _controller.messages[index];
                    return ChatBubble(message: message);
                  },
                );
              }),
            ),
            Obx(
              () => _Composer(
                controller: _inputController,
                isLoading: _controller.isLoading.value,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantHeader extends StatefulWidget {
  const _AssistantHeader({required this.prompts, required this.onPromptTap});

  final List<String> prompts;
  final ValueChanged<String> onPromptTap;

  @override
  State<_AssistantHeader> createState() => _AssistantHeaderState();
}

class _AssistantHeaderState extends State<_AssistantHeader> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tanya insight dari transaksi tersimpan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  tooltip: _isExpanded ? 'Tutup insight' : 'Buka insight',
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.prompts.map((String prompt) {
                    return ActionChip(
                      avatar: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(prompt),
                      onPressed: () => widget.onPromptTap(prompt),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.panel,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              enabled: !isLoading,
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!isLoading) {
                  onSend();
                }
              },
              decoration: const InputDecoration(
                hintText: 'Tulis pertanyaan...',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isLoading ? null : onSend,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            tooltip: 'Kirim',
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Menganalisis...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
