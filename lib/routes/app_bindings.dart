import 'package:get/get.dart';

import '../core/services/api_client.dart';
import '../data/services/chatbot_service.dart';
import '../data/services/transaction_local_service.dart';
import '../data/repositories/transaction_repository.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    Get.lazyPut<TransactionRepository>(
      () => TransactionRepository(Get.find()),
      fenix: true,
    );
    Get.lazyPut<TransactionLocalService>(
      () => TransactionLocalService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<ChatbotService>(() => ChatbotService(Get.find()), fenix: true);
  }
}
