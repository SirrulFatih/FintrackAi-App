import 'package:get/get.dart';

import '../../../data/services/transaction_local_service.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(Get.find<TransactionLocalService>()),
      fenix: true,
    );
  }
}
