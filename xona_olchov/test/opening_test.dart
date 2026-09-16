import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/estimate.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/models/opening.dart';
import 'package:xona_olchov/models/room_sketch.dart';

void main() {
  group('Eshik va derazalar', () {
    test('yuza = eni × bo‘yi × soni', () {
      const door = Opening(kind: OpeningKind.door, width: 0.8, height: 2.05);
      const windows = Opening(
        kind: OpeningKind.window,
        width: 1.4,
        height: 1.5,
        count: 2,
      );
      expect(door.area, closeTo(1.64, 1e-9));
      expect(windows.area, closeTo(4.2, 1e-9));
      expect(windows.totalWidth, closeTo(2.8, 1e-9));
      expect(door.sizeText, '0.80 × 2.05 m');
    });

    test('yaroqsiz o‘lcham hisobga kirmaydi', () {
      const zero = Opening(kind: OpeningKind.door, width: 0, height: 2);
      const huge = Opening(kind: OpeningKind.door, width: 50, height: 2);
      const nan = Opening(kind: OpeningKind.door, width: double.nan, height: 2);
      const none = Opening(
        kind: OpeningKind.door,
        width: 0.8,
        height: 2,
        count: 0,
      );
      for (final opening in <Opening>[zero, huge, nan, none]) {
        expect(opening.isValid, isFalse);
        expect(opening.area, 0);
        expect(opening.totalWidth, 0);
      }
    });

    test('ro‘yxat jamlanmasi', () {
      const list = <Opening>[
        Opening(kind: OpeningKind.door, width: 0.8, height: 2.05),
        Opening(kind: OpeningKind.door, width: 0.9, height: 2.05, count: 2),
        Opening(kind: OpeningKind.window, width: 1.4, height: 1.5),
        Opening(kind: OpeningKind.other, width: 0, height: 1),
      ];
      expect(list.pieces, 4);
      expect(list.doorWidth, closeTo(0.8 + 1.8, 1e-9));
      expect(list.totalArea, closeTo(1.64 + 3.69 + 2.1, 1e-9));
    });

    test('JSON orqali yo‘qolmaydi, buzilgan yozuv tashlanadi', () {
      final fromJson = Opening.fromJson(<String, dynamic>{
        'kind': 'window',
        'width': '1.4',
        'height': 1.5,
        'count': 3,
      });
      expect(fromJson.kind, OpeningKind.window);
      expect(fromJson.width, 1.4);
      expect(fromJson.count, 3);

      final broken = Opening.fromJson(<String, dynamic>{
        'kind': 'nimadir',
        'width': 'x',
        'count': -4,
      });
      expect(broken.kind, OpeningKind.other);
      expect(broken.isValid, isFalse);
      expect(broken.count, 1);
    });
  });

  group('Material hisobi ochiq joylar bilan', () {
    const openings = <Opening>[
      Opening(kind: OpeningKind.door, width: 0.8, height: 2.05),
      Opening(kind: OpeningKind.window, width: 1.4, height: 1.5),
    ];

    test('devor yuzasidan ayriladi, plintus eshiksiz', () {
      const estimate = RoomEstimate(
        floorArea: 20,
        perimeter: 18,
        height: 2.8,
        openings: openings,
      );
      expect(estimate.grossWallArea, closeTo(50.4, 1e-9));
      expect(estimate.openingArea, closeTo(1.64 + 2.1, 1e-9));
      expect(estimate.wallArea, closeTo(50.4 - 3.74, 1e-9));
      expect(estimate.totalSurface, closeTo(20 + 50.4 - 3.74, 1e-9));
      expect(estimate.skirtingLength, closeTo(17.2, 1e-9));
      expect(estimate.hasOpenings, isTrue);
    });

    test('ochiq joylar devordan katta bo‘lsa ham manfiy chiqmaydi', () {
      const estimate = RoomEstimate(
        floorArea: 4,
        perimeter: 8,
        height: 0.5,
        openings: <Opening>[
          Opening(kind: OpeningKind.window, width: 4, height: 4),
        ],
      );
      expect(estimate.wallArea, 0);
      expect(estimate.skirtingLength, 8);
    });

    test('balandliksiz devor yuzasi yo‘q, plintus esa bor', () {
      const estimate = RoomEstimate(
        floorArea: 20,
        perimeter: 18,
        openings: openings,
      );
      expect(estimate.wallArea, isNull);
      expect(estimate.skirtingLength, closeTo(17.2, 1e-9));
    });

    test('umumiy narx', () {
      expect(RoomEstimate.totalCost(58.6, 85000), closeTo(4981000, 1e-6));
      expect(RoomEstimate.totalCost(58.6, null), isNull);
      expect(RoomEstimate.totalCost(58.6, 0), isNull);
      expect(RoomEstimate.totalCost(0, 85000), isNull);
      expect(RoomEstimate.totalCost(double.nan, 85000), isNull);
    });

    test('balandlik oralig‘i', () {
      expect(RoomEstimate.validHeight(2.8), 2.8);
      expect(RoomEstimate.validHeight(0.5), 0.5);
      expect(RoomEstimate.validHeight(30), 30);
      expect(RoomEstimate.validHeight(0.2), isNull);
      expect(RoomEstimate.validHeight(45), isNull);
      expect(RoomEstimate.validHeight(null), isNull);
      expect(RoomEstimate.validHeight(double.infinity), isNull);
    });
  });

  group('Chizma JSON', () {
    RoomSketch build() {
      final now = DateTime.now();
      final built = ShapePresets.rectangle(length: 5, width: 4);
      return RoomSketch(
        id: 'o1',
        name: 'Yotoqxona',
        kind: RoomKind.rectangle,
        walls: built.walls,
        startHeading: built.startHeading,
        height: 2.8,
        openings: const <Opening>[
          Opening(kind: OpeningKind.door, width: 0.8, height: 2.05),
          Opening(kind: OpeningKind.window, width: 1.4, height: 1.5, count: 2),
        ],
        createdAt: now,
        updatedAt: now,
      );
    }

    test('eshik va derazalar saqlanadi va qayta o‘qiladi', () {
      final sketch = build();
      final restored = RoomSketch.fromJson(sketch.toJson());
      expect(restored.openings, sketch.openings);
      expect(
        restored.estimate.wallArea,
        closeTo(sketch.estimate.wallArea!, 1e-9),
      );
      expect(restored.estimate.skirtingLength, closeTo(17.2, 1e-9));
    });

    test('yaroqsiz balandlik va ochiq joy o‘qishda tashlanadi', () {
      final json = build().toJson()
        ..['height'] = 120
        ..['openings'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'door', 'width': 0.8, 'height': 2.05},
          <String, dynamic>{'kind': 'door', 'width': 0, 'height': 2.05},
          <String, dynamic>{'kind': 'window', 'width': 'x', 'height': 1},
        ];
      final restored = RoomSketch.fromJson(json);
      expect(restored.height, isNull);
      expect(restored.openings.length, 1);
    });

    test('nusxa ochiq joylarni ham oladi', () {
      final copy = build().duplicate(id: 'o2', name: 'Nusxa');
      expect(copy.openings.length, 2);
      expect(copy.height, 2.8);
    });
  });
}
