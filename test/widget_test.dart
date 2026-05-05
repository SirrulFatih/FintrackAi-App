import 'package:fintrack/core/services/app_formatter.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
