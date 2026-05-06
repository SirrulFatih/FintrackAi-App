import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

enum TransactionPeriod { day, month, year }

extension TransactionPeriodX on TransactionPeriod {
  String get label {
    return switch (this) {
      TransactionPeriod.day => 'Hari',
      TransactionPeriod.month => 'Bulan',
      TransactionPeriod.year => 'Tahun',
    };
  }
}

class DailyExpenseTotal {
  const DailyExpenseTotal({required this.date, required this.total});

  final DateTime date;
  final double total;
}

class TransactionGroup {
  const TransactionGroup({
    required this.period,
    required this.startDate,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  final TransactionPeriod period;
  final DateTime startDate;
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;

  double get balance => totalIncome - totalExpense;
  int get transactionCount => transactions.length;
}

class TransactionController extends GetxController {
  TransactionController(this._repository);

  final TransactionRepository _repository;
  final Uuid _uuid = const Uuid();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<TransactionType> activeType = Rxn<TransactionType>();
  final Rx<TransactionPeriod> selectedPeriod = TransactionPeriod.day.obs;
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

  double get todayExpenseTotal {
    final DateTime today = _dateOnly(DateTime.now());

    return transactions
        .where(
          (TransactionModel item) =>
              item.type == TransactionType.expense &&
              _dateOnly(item.date) == today,
        )
        .fold<double>(
          0,
          (double sum, TransactionModel item) => sum + item.amount,
        );
  }

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

  List<TransactionGroup> get groupedTransactions {
    final TransactionPeriod period = selectedPeriod.value;
    final Map<DateTime, List<TransactionModel>> groupedItems =
        <DateTime, List<TransactionModel>>{};

    for (final TransactionModel item in filteredTransactions) {
      final DateTime key = _periodStart(item.date, period);
      groupedItems.putIfAbsent(key, () => <TransactionModel>[]).add(item);
    }

    final List<DateTime> sortedKeys = groupedItems.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));

    return sortedKeys
        .map((DateTime key) {
          final List<TransactionModel> items = groupedItems[key]!
            ..sort(
              (TransactionModel a, TransactionModel b) =>
                  b.date.compareTo(a.date),
            );

          final double income = items
              .where(
                (TransactionModel item) => item.type == TransactionType.income,
              )
              .fold<double>(
                0,
                (double sum, TransactionModel item) => sum + item.amount,
              );
          final double expense = items
              .where(
                (TransactionModel item) => item.type == TransactionType.expense,
              )
              .fold<double>(
                0,
                (double sum, TransactionModel item) => sum + item.amount,
              );

          return TransactionGroup(
            period: period,
            startDate: key,
            transactions: items,
            totalIncome: income,
            totalExpense: expense,
          );
        })
        .toList(growable: false);
  }

  List<DailyExpenseTotal> get dailyExpenseTotals {
    final Map<DateTime, double> totals = <DateTime, double>{};

    for (final TransactionModel item in transactions) {
      if (item.type != TransactionType.expense) {
        continue;
      }

      final DateTime key = _dateOnly(item.date);
      totals.update(
        key,
        (double value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }

    final List<DateTime> sortedKeys = totals.keys.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    return sortedKeys
        .map(
          (DateTime date) =>
              DailyExpenseTotal(date: date, total: totals[date] ?? 0),
        )
        .toList(growable: false);
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

  void setPeriod(TransactionPeriod period) {
    selectedPeriod.value = period;
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

  DateTime _periodStart(DateTime value, TransactionPeriod period) {
    return switch (period) {
      TransactionPeriod.day => _dateOnly(value),
      TransactionPeriod.month => DateTime(value.year, value.month),
      TransactionPeriod.year => DateTime(value.year),
    };
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
