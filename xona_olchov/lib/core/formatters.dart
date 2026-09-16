/// O'lcham va sana formatlari.
abstract final class Fmt {
  static const List<String> months = <String>[
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  /// 12.345 -> "12.35"
  static String number(double value, {int digits = 2}) {
    if (!value.isFinite) return '—';
    return value.toStringAsFixed(digits);
  }

  /// 12.345 -> "12.35 m"
  static String meters(double value, {int digits = 2}) =>
      '${number(value, digits: digits)} m';

  /// 53.2694 -> "53.27 m²"
  static String area(double value, {int digits = 2}) =>
      '${number(value, digits: digits)} m²';

  /// 42.5 -> "42.50 m³"
  static String volume(double value, {int digits = 2}) =>
      '${number(value, digits: digits)} m³';

  /// 1234567.8 -> "1 234 568" — uch xonadan ajratilgan pul miqdori.
  static String money(double value) {
    if (!value.isFinite) return '—';
    final rounded = value.abs().round();
    final digits = rounded.toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Kichik joylar uchun qisqartma: 1234.5 -> "1234.5"
  static String compact(double value) {
    if (!value.isFinite) return '—';
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  static String date(DateTime value) {
    final local = value.toLocal();
    final month = months[(local.month - 1).clamp(0, 11)];
    return '${local.day}-$month, ${local.year}';
  }

  static String dateTime(DateTime value) {
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${date(local)} · $hh:$mm';
  }

  /// "2 kun oldin" ko'rinishidagi nisbiy sana.
  static String relative(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value.toLocal());
    if (diff.inSeconds < 60) return 'hozirgina';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return date(value);
  }

  /// Kiritilgan matnni songa aylantiradi ("3,17" ham qabul qilinadi).
  static double? parseNumber(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || !value.isFinite) return null;
    return value;
  }
}
