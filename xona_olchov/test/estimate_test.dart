import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/estimate.dart';

void main() {
  group('Material hisobi', () {
    test('balandliksiz faqat pol yuzasi bo‘ladi', () {
      const estimate = RoomEstimate(floorArea: 53.27, perimeter: 41.1);
      expect(estimate.hasHeight, isFalse);
      expect(estimate.ceilingArea, 53.27);
      expect(estimate.wallArea, isNull);
      expect(estimate.volume, isNull);
      expect(estimate.totalSurface, isNull);
      expect(estimate.factor, 1);
    });

    test('devorlar yuzasi = perimetr × balandlik', () {
      const estimate = RoomEstimate(floorArea: 20, perimeter: 18, height: 2.8);
      expect(estimate.wallArea, closeTo(50.4, 0.0001));
      expect(estimate.volume, closeTo(56, 0.0001));
      expect(estimate.totalSurface, closeTo(70.4, 0.0001));
    });

    test('zaxira foizi qo‘shiladi', () {
      const estimate = RoomEstimate(
        floorArea: 53.2697,
        perimeter: 41.1,
        reservePercent: 10,
      );
      expect(estimate.factor, closeTo(1.1, 1e-9));
      // Namunadagi maslahat: 53.27 m² ga 10% zaxira ≈ 58.6 m².
      expect(estimate.withReserve(estimate.floorArea), closeTo(58.5967, 0.001));
    });

    test('quti soni yuqoriga yaxlitlanadi', () {
      expect(RoomEstimate.unitsNeeded(20, 2.5), 8);
      expect(RoomEstimate.unitsNeeded(20.1, 2.5), 9);
      expect(RoomEstimate.unitsNeeded(58.6, 2.5), 24);
    });

    test('xato kiritish 0 qaytaradi', () {
      expect(RoomEstimate.unitsNeeded(20, 0), 0);
      expect(RoomEstimate.unitsNeeded(20, -1), 0);
      expect(RoomEstimate.unitsNeeded(0, 2.5), 0);
      expect(RoomEstimate.unitsNeeded(double.nan, 2.5), 0);
      expect(RoomEstimate.unitsNeeded(20, double.infinity), 0);
    });

    test('zaxira foizi chegaralanadi', () {
      expect(RoomEstimate.clampReserve(-5), 0);
      expect(RoomEstimate.clampReserve(250), 100);
      expect(RoomEstimate.clampReserve(double.nan), 0);
      expect(RoomEstimate.clampReserve(10), 10);
    });

    test('nol balandlik kiritilmagan deb hisoblanadi', () {
      const estimate = RoomEstimate(floorArea: 10, perimeter: 12, height: 0);
      expect(estimate.hasHeight, isFalse);
      expect(estimate.wallArea, isNull);
    });
  });
}
