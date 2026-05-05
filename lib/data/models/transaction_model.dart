import 'package:hive/hive.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense,
}

extension TransactionTypeX on TransactionType {
  String get label {
    return switch (this) {
      TransactionType.income => 'Pemasukan',
      TransactionType.expense => 'Pengeluaran',
    };
  }

  String get apiValue {
    return switch (this) {
      TransactionType.income => 'income',
      TransactionType.expense => 'expense',
    };
  }
}

@HiveType(typeId: 0)
class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final TransactionType type;

  @HiveField(5)
  final String category;

  @HiveField(4)
  final DateTime date;

  double get signedAmount {
    return type == TransactionType.income ? amount : -amount;
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.apiValue,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  static const int typeIdValue = 0;

  @override
  final int typeId = typeIdValue;

  @override
  TransactionModel read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    final dynamic rawType = fields[3];
    final TransactionType parsedType = _parseTransactionType(rawType);

    final dynamic rawAmount = fields[2];
    final double parsedAmount = rawAmount is num ? rawAmount.toDouble() : 0.0;

    return TransactionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: parsedAmount,
      type: parsedType,
      category: (fields[5] as String?) ?? 'Lainnya',
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type.index)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.category);
  }

  TransactionType _parseTransactionType(dynamic rawType) {
    if (rawType is TransactionType) {
      return rawType;
    }

    if (rawType is int &&
        rawType >= 0 &&
        rawType < TransactionType.values.length) {
      return TransactionType.values[rawType];
    }

    if (rawType is String) {
      final String normalized = rawType.toLowerCase().trim();
      if (normalized == 'income') {
        return TransactionType.income;
      }
      if (normalized == 'expense') {
        return TransactionType.expense;
      }
    }

    return TransactionType.expense;
  }
}
