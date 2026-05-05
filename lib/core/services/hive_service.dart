import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/transaction_model.dart';

class HiveService {
  static const String transactionBoxName = 'transactions';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(TransactionModelAdapter.typeIdValue)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }

    if (!Hive.isBoxOpen(transactionBoxName)) {
      await Hive.openBox<TransactionModel>(transactionBoxName);
    }
  }

  Box<TransactionModel> get transactionBox =>
      Hive.box<TransactionModel>(transactionBoxName);

  List<TransactionModel> getAllTransactions() {
    final List<TransactionModel> items = transactionBox.values.toList();
    items.sort(
      (TransactionModel a, TransactionModel b) => b.date.compareTo(a.date),
    );
    return items;
  }

  Future<void> upsertTransaction(TransactionModel transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  Future<void> addTransaction(TransactionModel transaction) {
    return upsertTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  Future<void> updateTransaction(TransactionModel transaction) {
    return upsertTransaction(transaction);
  }

  TransactionModel? getTransactionById(String id) {
    return transactionBox.get(id);
  }
}
