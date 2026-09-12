import 'dart:math' as math;

/// Xona bo'yicha material hisob-kitobi.
///
/// Barcha qiymatlar chizmadan olinadi: pol/potolok yuzasi — shaklning yuzasi,
/// devorlar yuzasi — perimetr × balandlik.
class RoomEstimate {
  const RoomEstimate({
    required this.floorArea,
    required this.perimeter,
    this.height,
    this.reservePercent = 0,
  });

  /// Pol (va potolok) yuzasi, m².
  final double floorArea;

  /// Perimetr, m.
  final double perimeter;

  /// Xona balandligi, m. Kiritilmagan bo'lsa `null`.
  final double? height;

  /// Zaxira foizi (kesim va nuqson uchun).
  final double reservePercent;

  bool get hasHeight => height != null && height! > 0;

  /// Zaxira koeffitsiyenti: 10% → 1.1.
  double get factor => 1 + reservePercent / 100;

  double get ceilingArea => floorArea;

  /// Devorlarning umumiy yuzasi, m².
  double? get wallArea => hasHeight ? perimeter * height! : null;

  /// Xona hajmi, m³.
  double? get volume => hasHeight ? floorArea * height! : null;

  /// Pol + devorlar (masalan shpatlyovka uchun).
  double? get totalSurface =>
      hasHeight ? floorArea + perimeter * height! : null;

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

  /// Ruxsat etilgan zaxira variantlari, %.
  static const List<double> reserveOptions = <double>[0, 5, 10, 15];

  static double clampReserve(double value) {
    if (!value.isFinite) return 0;
    return math.min(math.max(value, 0), 100);
  }
}
