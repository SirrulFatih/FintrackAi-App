import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/app_formatter.dart';
import '../../core/services/api_client.dart';

class ChatbotService {
  ChatbotService(this._apiClient);

  final ApiClient _apiClient;
  static const String _defaultBotMessage =
      'Maaf, AI belum memberikan jawaban. Coba kirim ulang pesanmu.';
  static const String _chatEndpoint = '/text.gen/ai4chat';

  Future<String> sendMessage({
    required String message,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final String trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Pesan tidak boleh kosong.');
    }

    final String financeContext = _buildFinanceContext(transactions);
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'text':
          '''
$financeContext

Pertanyaan pengguna:
$trimmedMessage
''',
      'systemPrompt': _buildSystemPrompt(),
      'sessionId': 'fintrack-${DateTime.now().millisecondsSinceEpoch}',
    };
    debugPrint('Chat API Request: $requestBody');

    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        _chatEndpoint,
        data: requestBody,
      );
      debugPrint('Chat API Response: ${response.data}');

      final String? parsedMessage = _extractMessage(response.data);
      if (parsedMessage == null || parsedMessage.trim().isEmpty) {
        return _defaultBotMessage;
      }

      return parsedMessage.trim();
    } on DioException catch (error) {
      debugPrint('Chat API Error: ${error.message}');
      final int? statusCode = error.response?.statusCode;
      return _buildLocalFallbackReply(
        message: trimmedMessage,
        transactions: transactions,
        statusCode: statusCode,
      );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is String) {
      return data;
    }

    if (data is List && data.isNotEmpty) {
      return _extractMessage(data.first);
    }

    if (data is Map<String, dynamic>) {
      final dynamic responseValue = data['response'];
      if (responseValue is String && responseValue.trim().isNotEmpty) {
        return responseValue;
      }

      final dynamic resultValue = data['result'];
      if (resultValue is String && resultValue.trim().isNotEmpty) {
        return resultValue;
      }

      final dynamic messageValue = data['message'];
      if (messageValue is String && messageValue.trim().isNotEmpty) {
        return messageValue;
      }

      const List<String> directKeys = <String>['reply', 'answer', 'text'];

      for (final String key in directKeys) {
        final dynamic value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }

      const List<String> nestedKeys = <String>['data', 'result', 'payload'];
      for (final String key in nestedKeys) {
        final String? nestedValue = _extractMessage(data[key]);
        if (nestedValue != null && nestedValue.trim().isNotEmpty) {
          return nestedValue;
        }
      }
    }

    return null;
  }

  String _buildSystemPrompt() {
    return '''
Kamu adalah asisten finansial pribadi untuk aplikasi FinTrack AI.
Jawab dalam Bahasa Indonesia yang jelas, ringkas, dan praktis.
Gunakan hanya data FinTrack yang diberikan di pesan pengguna sebagai konteks.
Jika data transaksi belum cukup, jelaskan batasannya dan beri saran umum yang aman.
Jangan mengarang angka di luar data yang tersedia.
''';
  }

  String _buildFinanceContext(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return '''
Konteks FinTrack:
Belum ada transaksi tersimpan di aplikasi.
''';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = <String, double>{};

    for (final Map<String, dynamic> item in transactions) {
      final double amount = _readAmount(item['amount']);
      final String type = '${item['type']}'.toLowerCase();
      final String category = '${item['category'] ?? 'Lainnya'}';

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }
    }

    final double balance = totalIncome - totalExpense;
    final List<MapEntry<String, double>> topExpenses =
        expenseByCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });
    final Iterable<MapEntry<String, double>> visibleTopExpenses = topExpenses
        .take(5);
    final Iterable<Map<String, dynamic>> recentTransactions = transactions.take(
      25,
    );

    return '''
Konteks FinTrack:
- Jumlah transaksi: ${transactions.length}
- Total pemasukan: Rp ${totalIncome.toStringAsFixed(0)}
- Total pengeluaran: Rp ${totalExpense.toStringAsFixed(0)}
- Saldo: Rp ${balance.toStringAsFixed(0)}
- Pengeluaran per kategori utama: ${visibleTopExpenses.map((MapEntry<String, double> entry) => '${entry.key}: Rp ${entry.value.toStringAsFixed(0)}').join(', ')}
- Transaksi terbaru:
${recentTransactions.map(_formatTransactionForPrompt).join('\n')}
''';
  }

  String _formatTransactionForPrompt(Map<String, dynamic> item) {
    return '- ${item['date']}: ${item['title']} | ${item['type']} | '
        '${item['category']} | Rp ${_readAmount(item['amount']).toStringAsFixed(0)}';
  }

  double _readAmount(dynamic rawAmount) {
    if (rawAmount is num) {
      return rawAmount.toDouble();
    }
    return double.tryParse('$rawAmount') ?? 0;
  }

  String _buildLocalFallbackReply({
    required String message,
    required List<Map<String, dynamic>> transactions,
    required int? statusCode,
  }) {
    final String serverNote = statusCode == null
        ? 'AI online sedang tidak bisa dihubungi'
        : 'AI online sedang bermasalah (status $statusCode)';

    if (transactions.isEmpty) {
      return '''
$serverNote, jadi saya pakai analisis lokal FinTrack.

Belum ada transaksi tersimpan. Mulai catat minimal pemasukan dan pengeluaran harian, lalu saya bisa membaca saldo, kategori paling boros, dan memberi saran yang lebih tepat.

Saran cepat:
- Catat pengeluaran kecil seperti makan, transportasi, dan belanja.
- Pakai kategori yang konsisten.
- Cek ulang kategori terbesar setelah beberapa transaksi masuk.
''';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = <String, double>{};

    for (final Map<String, dynamic> item in transactions) {
      final double amount = _readAmount(item['amount']);
      final String type = '${item['type']}'.toLowerCase();
      final String category = '${item['category'] ?? 'Lainnya'}';

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }
    }

    final double balance = totalIncome - totalExpense;
    final List<MapEntry<String, double>> categories =
        expenseByCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });
    final MapEntry<String, double>? topCategory = categories.isEmpty
        ? null
        : categories.first;
    final String normalizedMessage = message.toLowerCase();

    if (normalizedMessage.contains('boros') ||
        normalizedMessage.contains('kategori')) {
      if (topCategory == null) {
        return '''
$serverNote, jadi saya pakai analisis lokal FinTrack.

Belum ada transaksi pengeluaran. Setelah ada pengeluaran, saya bisa menentukan kategori paling boros.
''';
      }

      return '''
$serverNote, jadi saya pakai analisis lokal FinTrack.

Kategori paling boros saat ini adalah ${topCategory.key} dengan total ${AppFormatter.currency(topCategory.value)}.

Ringkasan:
- Pemasukan: ${AppFormatter.currency(totalIncome)}
- Pengeluaran: ${AppFormatter.currency(totalExpense)}
- Saldo: ${AppFormatter.currency(balance)}
''';
    }

    return '''
$serverNote, jadi saya pakai analisis lokal FinTrack.

Ringkasan kondisi keuangan:
- Pemasukan: ${AppFormatter.currency(totalIncome)}
- Pengeluaran: ${AppFormatter.currency(totalExpense)}
- Saldo: ${AppFormatter.currency(balance)}

${topCategory == null ? 'Belum ada kategori pengeluaran yang bisa dianalisis.' : 'Kategori pengeluaran terbesar: ${topCategory.key} (${AppFormatter.currency(topCategory.value)}).'}

Saran hemat minggu ini:
- Batasi kategori terbesar dulu karena dampaknya paling terasa.
- Catat transaksi kecil di hari yang sama.
- Sisihkan saldo positif ke tabungan sebelum dipakai belanja.
''';
  }
}
