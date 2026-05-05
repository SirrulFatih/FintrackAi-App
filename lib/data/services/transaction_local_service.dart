import '../../core/services/hive_service.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

@Deprecated('Use TransactionRepository instead.')
class TransactionLocalService {
  TransactionLocalService(HiveService hiveService)
    : _repository = TransactionRepository(hiveService);

  final TransactionRepository _repository;

  List<TransactionModel> getTransactions() {
    return _repository.findAll();
  }

  Future<void> createTransaction(TransactionModel transaction) async {
    await _repository.save(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.save(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.delete(id);
  }

  TransactionModel? getTransactionById(String id) {
    return _repository.findById(id);
  }
}
