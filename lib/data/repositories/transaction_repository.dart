import '../../core/services/hive_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._hiveService);

  final HiveService _hiveService;

  List<TransactionModel> findAll() {
    return _hiveService.getAllTransactions();
  }

  TransactionModel? findById(String id) {
    return _hiveService.getTransactionById(id);
  }

  Future<void> save(TransactionModel transaction) {
    return _hiveService.upsertTransaction(transaction);
  }

  Future<void> delete(String id) {
    return _hiveService.deleteTransaction(id);
  }
}
