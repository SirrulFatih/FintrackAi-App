import 'package:get/get.dart';

import '../../../data/repositories/transaction_repository.dart';
import '../../../data/services/chatbot_service.dart';
import '../../transaction/controllers/transaction_controller.dart';
import '../controllers/chatbot_controller.dart';

class ChatbotBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TransactionController>() &&
        !Get.isPrepared<TransactionController>()) {
      Get.lazyPut<TransactionController>(
        () => TransactionController(Get.find<TransactionRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ChatbotController>() &&
        !Get.isPrepared<ChatbotController>()) {
      Get.lazyPut<ChatbotController>(
        () => ChatbotController(
          Get.find<ChatbotService>(),
          Get.find<TransactionController>(),
        ),
        fenix: true,
      );
    }
  }
}
