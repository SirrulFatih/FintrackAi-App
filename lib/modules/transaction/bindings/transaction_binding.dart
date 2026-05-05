import 'package:get/get.dart';

import '../../../data/repositories/transaction_repository.dart';
import '../controllers/transaction_controller.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TransactionController>() &&
        !Get.isPrepared<TransactionController>()) {
      Get.lazyPut<TransactionController>(
        () => TransactionController(Get.find<TransactionRepository>()),
        fenix: true,
      );
    }
  }
}
