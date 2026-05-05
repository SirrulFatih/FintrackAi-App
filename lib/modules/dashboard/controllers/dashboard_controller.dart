import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/services/transaction_local_service.dart';

class DashboardController extends GetxController {
  DashboardController(this._transactionService);

  final TransactionLocalService _transactionService;

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;

  double get totalIncome {
    return transactions
        .where((TransactionModel item) => item.type == TransactionType.income)
        .fold<double>(
          0,
          (double sum, TransactionModel item) => sum + item.amount,
        );
  }

  double get totalExpense {
    return transactions
        .where((TransactionModel item) => item.type == TransactionType.expense)
        .fold<double>(
          0,
          (double sum, TransactionModel item) => sum + item.amount,
        );
  }

  double get balance => totalIncome - totalExpense;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      isLoading.value = true;
      final List<TransactionModel> items = _transactionService
          .getTransactions();
      transactions.assignAll(items);
    } catch (error) {
      Get.snackbar(
        'Error',
        'Gagal memuat transaksi: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionService.deleteTransaction(id);
      await loadTransactions();
      Get.snackbar(
        'Berhasil',
        'Transaksi berhasil dihapus.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Error',
        'Gagal menghapus transaksi: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
