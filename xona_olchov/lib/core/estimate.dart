import 'dart:math' as math;

import '../models/opening.dart';

/// Xona bo'yicha material hisob-kitobi.
///
/// Barcha qiymatlar chizmadan olinadi: pol/potolok yuzasi — shaklning yuzasi,
/// devorlar yuzasi — perimetr × balandlik. Eshik va derazalar devor yuzasidan
/// ayriladi, eshiklar esa plintus uzunligini qisqartiradi.
class RoomEstimate {
  const RoomEstimate({
    required this.floorArea,
    required this.perimeter,
    this.height,
    this.reservePercent = 0,
    this.openings = const <Opening>[],
  });

  /// Pol (va potolok) yuzasi, m².
  final double floorArea;

  /// Perimetr, m.
  final double perimeter;

  /// Xona balandligi, m. Kiritilmagan bo'lsa `null`.
  final double? height;

  /// Zaxira foizi (kesim va nuqson uchun).
  final double reservePercent;

  /// Eshik va derazalar.
  final List<Opening> openings;

  bool get hasHeight => height != null && height! > 0;

  /// Zaxira koeffitsiyenti: 10% → 1.1.
  double get factor => 1 + reservePercent / 100;

  double get ceilingArea => floorArea;

  /// Eshik va derazalarning umumiy yuzasi, m².
  double get openingArea => openings.totalArea;

  bool get hasOpenings => openingArea > 0;

  /// Devorlarning yalpi yuzasi (ochiq joylar ayrilmagan), m².
  double? get grossWallArea => hasHeight ? perimeter * height! : null;

  /// Devorlarning sof yuzasi — eshik va derazalar ayrilgan, m².
  ///
  /// Ochiq joylar devordan kattaroq bo'lib qolsa ham natija manfiy bo'lmaydi.
  double? get wallArea {
    final gross = grossWallArea;
    if (gross == null) return null;
    return math.max(gross - openingArea, 0);
  }

  /// Xona hajmi, m³.
  double? get volume => hasHeight ? floorArea * height! : null;

  /// Pol + devorlar (masalan shpatlyovka uchun).
  double? get totalSurface {
    final walls = wallArea;
    return walls == null ? null : floorArea + walls;
  }

  /// Plintus uzunligi — perimetrdan eshiklar eni ayrilgan, m.
  double get skirtingLength => math.max(perimeter - openings.doorWidth, 0);

  /// Zaxira qo'shilgan qiymat.
  double withReserve(double value) => value * factor;

  /// Bitta quti/rulon `perUnit` m² ni qoplasa, nechta kerak bo'ladi.
  ///
  /// Zaxira allaqachon qo'shilgan yuzadan hisoblanadi va yuqoriga
  /// yaxlitlanadi — yarim quti sotilmaydi.
  static int unitsNeeded(double area, double perUnit) {
    if (!area.isFinite || !perUnit.isFinite || perUnit <= 0 || area <= 0) {
      return 0;
    }
    return (area / perUnit).ceil();
  }

  /// `area` m² uchun umumiy narx. Narx yaroqsiz bo'lsa `null`.
  static double? totalCost(double area, double? pricePerUnit) {
    if (pricePerUnit == null ||
        !pricePerUnit.isFinite ||
        pricePerUnit <= 0 ||
        !area.isFinite ||
        area <= 0) {
      return null;
    }
    return area * pricePerUnit;
  }

  /// Ruxsat etilgan zaxira variantlari, %.
  static const List<double> reserveOptions = <double>[0, 5, 10, 15];

  static double clampReserve(double value) {
    if (!value.isFinite) return 0;
    return math.min(math.max(value, 0), 100);
  }

  /// Kiritilishi mumkin bo'lgan xona balandligi oralig'i, m.
  static const double minHeight = 0.5;
  static const double maxHeight = 30;

  /// Balandlik yaroqli bo'lsa o'zini, aks holda `null` qaytaradi.
  static double? validHeight(double? value) {
    if (value == null || !value.isFinite) return null;
    if (value < minHeight || value > maxHeight) return null;
    return value;
  }
}
