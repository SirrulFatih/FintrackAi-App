import 'package:get/get.dart';

import '../modules/chatbot/bindings/chatbot_binding.dart';
import '../modules/chatbot/views/chatbot_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/transaction/bindings/transaction_binding.dart';
import '../modules/transaction/views/add_transaction_view.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<DashboardPage>(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: TransactionBinding(),
    ),
    GetPage<AddTransactionPage>(
      name: AppRoutes.addTransaction,
      page: () => const AddTransactionPage(),
      binding: TransactionBinding(),
    ),
    GetPage<AddTransactionPage>(
      name: AppRoutes.editTransaction,
      page: () => const AddTransactionPage(),
      binding: TransactionBinding(),
    ),
    GetPage<ChatbotPage>(
      name: AppRoutes.chatbot,
      page: () => const ChatbotPage(),
      binding: ChatbotBinding(),
    ),
  ];
}
