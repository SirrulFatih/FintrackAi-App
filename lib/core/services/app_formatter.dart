import 'package:intl/intl.dart';

class AppFormatter {
  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _compactDateFormatter = DateFormat('d MMM', 'id_ID');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  static String currency(double value) {
    return _idrFormatter.format(value);
  }

  static String signedCurrency(double value) {
    final String sign = value >= 0 ? '+' : '-';
    return '$sign${currency(value.abs())}';
  }

  static String date(DateTime value) {
    return _dateFormatter.format(value);
  }

  static String compactDate(DateTime value) {
    return _compactDateFormatter.format(value);
  }

  static String time(DateTime value) {
    return _timeFormatter.format(value);
  }

  static double? parseCurrencyInput(String input) {
    final String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    final double? value = double.tryParse(digitsOnly);
    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }
}
