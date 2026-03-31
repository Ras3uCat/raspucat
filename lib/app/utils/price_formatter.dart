class PriceFormatter {
  PriceFormatter._();

  /// Formats an integer dollar amount with comma separators.
  /// e.g. 1200 → '1,200', 999 → '999'
  static String dollars(int dollars) {
    final s = dollars.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Converts cents to a formatted dollar string with $ prefix.
  /// e.g. 120000 → '$1,200'
  static String cents(int cents) => '\$${dollars((cents / 100).round())}';
}
