import 'dart:math' as math;

/// Shift turlari — mijozga ko'rsatiladigan tanlov.
enum CeilingDesign {
  glossy(
    'Glyanets',
    'Oyna kabi yaltiroq. Xonani kengroq va yorug‘roq ko‘rsatadi.',
  ),
  matte(
    'Mat',
    'Suvoq kabi tekis, aks ettirmaydi. Klassik xonalarga mos.',
  ),
  satin(
    'Satin',
    'Yumshoq marvarid yaltirashi — mat bilan glyanets oralig‘i.',
  ),
  photoPrint(
    'Foto-chop',
    'Istalgan rasm to‘g‘ridan-to‘g‘ri shiftga bosiladi.',
  ),
  multiLevel(
    'Ko‘p darajali',
    'Ikki va undan ortiq daraja, yashirin yoritgich bilan.',
  ),
  starrySky(
    'Yulduzli osmon',
    'Optik tolali nur nuqtalari — yotoqxona va bolalar xonasi uchun.',
  );

  const CeilingDesign(this.title, this.description);

  final String title;
  final String description;

  static CeilingDesign? byName(String? name) {
    if (name == null) return null;
    for (final design in values) {
      if (design.name == name) return design;
    }
    return null;
  }
}

/// Narx qoidasi.
///
/// **Muhim:** ilovada faqat eng past, «hammasi ichida» narx ko'rsatiladi.
/// Yuqori darajalar (murakkab shakl, ko'p daraja, foto-chop) raqam bilan
/// e'lon qilinmaydi — ular uchun mijoz qo'ng'iroq qiladi.
abstract final class CeilingPrice {
  /// Omma oldida ko'rsatiladigan yagona narx, 1 m² uchun AQSh dollarida.
  static const double publicUsdPerSquare = 6;

  /// So'mga aylantirish kursi — sozlamalardan o'zgartiriladi.
  static const double defaultSomPerUsd = 12600;

  /// Kurs qabul qilinadigan oraliq.
  static const double minRate = 1000;
  static const double maxRate = 100000;

  static double normalizeRate(double? value) {
    if (value == null || !value.isFinite) return defaultSomPerUsd;
    if (value < minRate || value > maxRate) return defaultSomPerUsd;
    return value;
  }

  /// O'lchov mumkin bo'lgan eng katta xona yuzasi, m².
  static const double maxArea = 10000;

  static double? validArea(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;
    if (value > maxArea) return null;
    return value;
  }
}

/// Yuza bo'yicha taxminiy hisob.
class CeilingQuote {
  const CeilingQuote({
    required this.area,
    this.usdPerSquare = CeilingPrice.publicUsdPerSquare,
    this.somPerUsd = CeilingPrice.defaultSomPerUsd,
  });

  /// Shift yuzasi, m².
  final double area;

  /// 1 m² narxi, $.
  final double usdPerSquare;

  /// Dollar kursi.
  final double somPerUsd;

  bool get isValid => CeilingPrice.validArea(area) != null;

  /// Umumiy narx, $.
  double get usd => isValid ? area * usdPerSquare : 0;

  /// Umumiy narx, so'm.
  double get som => usd * CeilingPrice.normalizeRate(somPerUsd);

  /// Yuqoriga yaxlitlangan dollar — «120$ dan» ko'rinishi uchun.
  int get roundedUsd => usd <= 0 ? 0 : usd.ceil();

  /// So'm ming so'mgacha yaxlitlanadi — aniq raqam qo'ng'iroqda aytiladi.
  double get roundedSom {
    if (som <= 0) return 0;
    return (som / 1000).ceil() * 1000;
  }

  /// Narx har doim «dan» bilan aytiladi: aniq summa o'lchovdan keyin chiqadi.
  static const String fromWord = 'dan';

  /// Yuzani xavfsiz oraliqqa keltiradi.
  static double clampArea(double value) {
    if (!value.isFinite || value <= 0) return 0;
    return math.min(value, CeilingPrice.maxArea);
  }
}
