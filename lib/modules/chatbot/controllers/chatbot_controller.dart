import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/chat_message_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/chatbot_service.dart';
import '../../transaction/controllers/transaction_controller.dart';

class ChatbotController extends GetxController {
  ChatbotController(this._chatbotService, this._transactionController);

  final ChatbotService _chatbotService;
  final TransactionController _transactionController;
  final Uuid _uuid = const Uuid();

  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _addMessage(
      text:
          'Halo, saya FinTrack Assistant. Tanyakan tips keuangan atau insight pengeluaranmu.',
      role: ChatRole.bot,
    );
  }

  Future<void> sendMessage(String message) async {
    final String cleanText = message.trim();
    if (cleanText.isEmpty || isLoading.value) {
      return;
    }

    _addMessage(text: cleanText, role: ChatRole.user);

    try {
      isLoading.value = true;

      if (!_transactionController.isLoading.value) {
        await _transactionController.loadTransactions();
      }

      final List<Map<String, dynamic>> transactions = _transactionController
          .transactions
          .map(
            (TransactionModel item) => <String, dynamic>{
              'title': item.title,
              'amount': item.amount,
              'type': item.type.apiValue,
              'date': item.date.toIso8601String(),
            },
          )
          .toList();

      final String botReply = await _chatbotService.sendMessage(
        message: cleanText,
        transactions: transactions,
      );

      _addMessage(text: botReply, role: ChatRole.bot);
    } catch (error) {
      Get.snackbar(
        'Error',
        'Gagal terhubung ke AI: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
      _addMessage(
        text:
            'Maaf, saya belum bisa menjawab sekarang. Coba lagi beberapa saat.',
        role: ChatRole.bot,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _addMessage({required String text, required ChatRole role}) {
    messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        role: role,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }
}
