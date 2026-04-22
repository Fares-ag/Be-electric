import 'package:intl/intl.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  // Qatar Riyal currency symbol
  static const String currencySymbol = 'QAR';
  static const String currencyCode = 'QAR';

  /// Format a number as currency with QAR symbol
  /// Example: formatCurrency(1000) returns "QAR 1,000.00"
  static String formatCurrency(double? value, {bool showSymbol = true}) {
    if (value == null) return showSymbol ? 'QAR 0.00' : '0.00';

    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedValue = formatter.format(value);

    return showSymbol ? 'QAR $formattedValue' : formattedValue;
  }

  /// Format a number as currency without decimal places
  /// Example: formatCurrencyWhole(1000) returns "QAR 1,000"
  static String formatCurrencyWhole(double? value, {bool showSymbol = true}) {
    if (value == null) return showSymbol ? 'QAR 0' : '0';

    final formatter = NumberFormat('#,##0', 'en_US');
    final formattedValue = formatter.format(value);

    return showSymbol ? 'QAR $formattedValue' : formattedValue;
  }

  /// Format a number as compact currency (e.g., 1.5K, 2.3M)
  /// Example: formatCompactCurrency(1500) returns "QAR 1.5K"
  static String formatCompactCurrency(double? value, {bool showSymbol = true}) {
    if (value == null) return showSymbol ? 'QAR 0' : '0';

    final formatter = NumberFormat.compact();
    final formattedValue = formatter.format(value);

    return showSymbol ? 'QAR $formattedValue' : formattedValue;
  }
}
