import 'package:fintrack/core/services/app_formatter.dart';
import 'package:fintrack/core/services/hive_service.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:fintrack/data/repositories/transaction_repository.dart';
import 'package:fintrack/modules/transaction/controllers/transaction_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('AppFormatter', () {
    test('parses common Indonesian currency inputs', () {
      expect(AppFormatter.parseCurrencyInput('1500000'), 1500000);
      expect(AppFormatter.parseCurrencyInput('Rp 1.500.000'), 1500000);
      expect(AppFormatter.parseCurrencyInput('0'), isNull);
      expect(AppFormatter.parseCurrencyInput('abc'), isNull);
    });
  });

  group('TransactionModel', () {
    test('exposes signed amount based on transaction type', () {
      final TransactionModel income = TransactionModel(
        id: '1',
        title: 'Gaji',
        amount: 2500000,
        type: TransactionType.income,
        category: 'Gaji',
        date: DateTime(2026),
      );

      final TransactionModel expense = income.copyWith(
        id: '2',
        type: TransactionType.expense,
      );

      expect(income.signedAmount, 2500000);
      expect(expense.signedAmount, -2500000);
      expect(expense.type.label, 'Pengeluaran');
    });
  });

  group('TransactionController summaries', () {
    test('groups transactions by period and totals daily expenses', () {
      final TransactionController controller = TransactionController(
        TransactionRepository(_FakeHiveService()),
      );

      final DateTime today = DateTime.now();
      controller.transactions.assignAll(<TransactionModel>[
        TransactionModel(
          id: 'expense-today',
          title: 'Makan',
          amount: 25000,
          type: TransactionType.expense,
          category: '',
          date: DateTime(today.year, today.month, today.day, 9),
        ),
        TransactionModel(
          id: 'income-today',
          title: 'Bonus',
          amount: 100000,
          type: TransactionType.income,
          category: '',
          date: DateTime(today.year, today.month, today.day, 10),
        ),
        TransactionModel(
          id: 'expense-next-month',
          title: 'Transport',
          amount: 40000,
          type: TransactionType.expense,
          category: '',
          date: DateTime(today.year, today.month + 1, 2),
        ),
      ]);

      expect(controller.todayExpenseTotal, 25000);
      expect(controller.dailyExpenseTotals.length, 2);
      expect(controller.dailyExpenseTotals.first.total, 25000);

      controller.setPeriod(TransactionPeriod.month);

      final List<TransactionGroup> groups = controller.groupedTransactions;
      expect(groups.length, 2);
      expect(groups.last.totalExpense, 25000);
      expect(groups.last.totalIncome, 100000);
    });
  });
}

class _FakeHiveService extends HiveService {
  @override
  List<TransactionModel> getAllTransactions() {
    return <TransactionModel>[];
  }
}
