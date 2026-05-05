import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

class TransactionController extends GetxController {
  TransactionController(this._repository);

  final TransactionRepository _repository;
  final Uuid _uuid = const Uuid();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<TransactionType> activeType = Rxn<TransactionType>();
  final Rx<TransactionType> selectedType = TransactionType.expense.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isSaving = false.obs;

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

  double get savingsRate {
    if (totalIncome <= 0) {
      return 0;
    }
    return (balance / totalIncome).clamp(0, 1);
  }

  List<TransactionModel> get filteredTransactions {
    final String query = searchQuery.value.trim().toLowerCase();
    final TransactionType? type = activeType.value;

    return transactions.where((TransactionModel item) {
      final bool matchesType = type == null || item.type == type;
      final bool matchesQuery =
          query.isEmpty || item.title.toLowerCase().contains(query);
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      isLoading.value = true;
      transactions.assignAll(_repository.findAll());
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

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.save(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.save(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.delete(id);
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

  void initializeForm(TransactionModel? transaction) {
    if (transaction == null) {
      selectedType.value = TransactionType.expense;
      selectedDate.value = DateTime.now();
      return;
    }

    selectedType.value = transaction.type;
    selectedDate.value = transaction.date;
  }

  void setType(TransactionType type) {
    selectedType.value = type;
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  void setActiveType(TransactionType? type) {
    activeType.value = type;
  }

  Future<bool> submit({
    required TransactionModel? existingTransaction,
    required String title,
    required String amountInput,
  }) async {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      Get.snackbar(
        'Validasi',
        'Judul transaksi wajib diisi.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final double? amount = _parseAmount(amountInput);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Validasi',
        'Nominal harus lebih dari 0.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final TransactionModel transaction = TransactionModel(
      id: existingTransaction?.id ?? _uuid.v4(),
      title: cleanTitle,
      amount: amount,
      type: selectedType.value,
      category: existingTransaction?.category ?? '',
      date: selectedDate.value,
    );

    try {
      isSaving.value = true;
      if (existingTransaction == null) {
        await addTransaction(transaction);
      } else {
        await updateTransaction(transaction);
      }

      Get.snackbar(
        'Berhasil',
        existingTransaction == null
            ? 'Transaksi berhasil ditambahkan.'
            : 'Transaksi berhasil diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (error) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan transaksi: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  double? _parseAmount(String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return double.tryParse(digitsOnly);
  }
}
