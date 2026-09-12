import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/models/wall.dart';

void main() {
  group('Trapetsiya', () {
    test('namunadagi xona: 17.38 × (2.96 / 3.17) = 53.27 m²', () {
      final built = ShapePresets.trapezoid(
        span: 17.38,
        sideA: 2.96,
        sideB: 3.17,
      );
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );

      expect(geometry.vertices.length, 4);
      expect(geometry.isClosed, isTrue);
      expect(geometry.selfIntersecting, isFalse);
      expect(geometry.area, closeTo((2.96 + 3.17) / 2 * 17.38, 0.0001));
      expect(geometry.area, closeTo(53.2697, 0.001));
      // Chizmadagi umumiy o'lcham strelkasi aynan uzunlikni ko'rsatadi.
      expect(geometry.bounds.width, closeTo(17.38, 0.0001));
    });

    test('yon tomonlar aynan kiritilgan uzunlikda', () {
      final built = ShapePresets.trapezoid(span: 10, sideA: 3, sideB: 5);
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );
      final lengths = geometry.edges.map((e) => e.length).toList()..sort();
      expect(lengths.first, closeTo(3, 0.0001));
      expect(lengths[1], closeTo(5, 0.0001));
      expect(geometry.area, closeTo(40, 0.0001));
    });
  });

  group("To‘rtburchak", () {
    test('5 × 4 xona', () {
      final built = ShapePresets.rectangle(length: 5, width: 4);
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );
      expect(geometry.vertices.length, 4);
      expect(geometry.area, closeTo(20, 0.0001));
      expect(geometry.perimeter, closeTo(18, 0.0001));
      expect(geometry.isClosed, isTrue);
      expect(geometry.impliedEdge, isNull);
      for (var i = 0; i < 4; i++) {
        expect(geometry.interiorAngleAt(i), closeTo(90, 0.0001));
      }
    });

    test('burish yuzani o‘zgartirmaydi', () {
      final built = ShapePresets.rectangle(length: 5, width: 4);
      for (final heading in <double>[0, 37, 90, 180, 270]) {
        final geometry = RoomGeometry.fromWalls(
          built.walls,
          startHeading: heading,
        );
        expect(geometry.area, closeTo(20, 0.0001));
      }
    });
  });

  group("Ko‘p burchakli xona", () {
    test('L-shakl: 6×6 kvadratdan 3×3 kesilgan = 27 m²', () {
      const walls = <Wall>[
        Wall(length: 6, turn: 90),
        Wall(length: 3, turn: 90),
        Wall(length: 3, turn: -90),
        Wall(length: 3, turn: 90),
        Wall(length: 3, turn: 90),
        Wall(length: 6, turn: 90),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 6);
      expect(geometry.isClosed, isTrue);
      expect(geometry.selfIntersecting, isFalse);
      expect(geometry.area, closeTo(27, 0.0001));
      expect(geometry.perimeter, closeTo(24, 0.0001));
      // Ichkariga qaragan burchak 270°.
      final angles = List<double>.generate(
        geometry.vertices.length,
        geometry.interiorAngleAt,
      );
      expect(angles.where((a) => (a - 270).abs() < 0.001).length, 1);
      expect(angles.where((a) => (a - 90).abs() < 0.001).length, 5);
    });

    test('U-shakl: 8×6 dan 3×3.5 kesilgan = 37.5 m²', () {
      const walls = <Wall>[
        Wall(length: 8, turn: 90),
        Wall(length: 6, turn: 90),
        Wall(length: 2.5, turn: 90),
        Wall(length: 3.5, turn: -90),
        Wall(length: 3, turn: -90),
        Wall(length: 3.5, turn: 90),
        Wall(length: 2.5, turn: 90),
        Wall(length: 6, turn: 90),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 8);
      expect(geometry.isClosed, isTrue);
      expect(geometry.area, closeTo(37.5, 0.0001));
    });

    test('oxirgi devor avtomatik yopiladi', () {
      const walls = <Wall>[
        Wall(length: 5, turn: 90),
        Wall(length: 4, turn: 90),
        Wall(length: 5, turn: 90),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 4);
      final implied = geometry.impliedEdge;
      expect(implied, isNotNull);
      expect(implied!.length, closeTo(4, 0.0001));
      expect(geometry.area, closeTo(20, 0.0001));
    });

    test('to‘g‘ri burchakli bo‘lmagan xona ham hisoblanadi', () {
      const walls = <Wall>[
        Wall(length: 4, turn: 120),
        Wall(length: 4, turn: 120),
        Wall(length: 4, turn: 120),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 3);
      // Teng tomonli uchburchak: a²√3/4
      expect(geometry.area, closeTo(6.9282, 0.001));
    });

    test('devorlar kesishsa aniqlanadi', () {
      // "Sakkizlik" shakli — devorlar markazda kesishadi.
      const ring = <Offset>[
        Offset(0, 0),
        Offset(4, 0),
        Offset(0, 4),
        Offset(4, 4),
      ];
      final built = RoomGeometry.wallsFromRing(ring);
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );
      expect(geometry.selfIntersecting, isTrue);
      expect(geometry.hasArea, isFalse);
    });

    test('devorlar ustma-ust tushsa ham aniqlanadi', () {
      const walls = <Wall>[
        Wall(length: 5, turn: 90),
        Wall(length: 5, turn: 90),
        Wall(length: 5, turn: -90),
        Wall(length: 5, turn: 90),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.selfIntersecting, isTrue);
    });

    test('bo‘sh yoki nol o‘lchamli kiritish xavfsiz', () {
      expect(RoomGeometry.fromWalls(const <Wall>[]).isEmpty, isTrue);
      expect(
        RoomGeometry.fromWalls(const <Wall>[Wall(length: 0, turn: 90)]).isEmpty,
        isTrue,
      );
      expect(
        RoomGeometry.fromWalls(
          const <Wall>[Wall(length: double.nan, turn: 90)],
        ).isEmpty,
        isTrue,
      );
    });
  });

  group('Halqadan devorlarga', () {
    test('to‘rtburchak halqa asl shaklga qaytadi', () {
      const ring = <Offset>[
        Offset(0, 0),
        Offset(6, 0),
        Offset(6, 4),
        Offset(0, 4),
      ];
      final built = RoomGeometry.wallsFromRing(ring);
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );
      expect(geometry.area, closeTo(24, 0.0001));
      expect(geometry.perimeter, closeTo(20, 0.0001));
      expect(geometry.isClosed, isTrue);
    });
  });

  group('Yopilish tolerantligi', () {
    test('butun gradus bilan kiritilgan uchburchak yopiladi', () {
      // 3-4-5 uchburchak: aniq burilish 143.13°, foydalanuvchi 143° kiritadi.
      const walls = <Wall>[
        Wall(length: 3, turn: 90),
        Wall(length: 4, turn: 143),
        Wall(length: 5, turn: 127),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 3, reason: 'soxta devor qo\u2018shilmasin');
      expect(geometry.isClosed, isTrue);
      expect(geometry.impliedEdge, isNull);
      expect(geometry.area, closeTo(6, 0.02));
      final angles = List<double>.generate(3, geometry.interiorAngleAt);
      expect(angles.reduce((a, b) => a + b), closeTo(180, 0.5));
    });

    test('teng tomonli uchburchak 119.9° bilan ham yopiladi', () {
      const walls = <Wall>[
        Wall(length: 10, turn: 119.9),
        Wall(length: 10, turn: 119.9),
        Wall(length: 10, turn: 120.2),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.vertices.length, 3);
      expect(geometry.isClosed, isTrue);
      expect(geometry.area, closeTo(43.30, 0.1));
    });

    test('tolerantlik eng qisqa devorga nisbatan olinadi', () {
      expect(
        RoomGeometry.closureToleranceFor(const <Wall>[Wall(length: 10)]),
        closeTo(0.1, 1e-9),
      );
      expect(
        RoomGeometry.closureToleranceFor(const <Wall>[Wall(length: 0.2)]),
        closeTo(0.005, 1e-9),
      );
      expect(
        RoomGeometry.closureToleranceFor(const <Wall>[]),
        RoomGeometry.closureEpsilon,
      );
    });

    test('haqiqiy ochiq shakl hamon yopilmagan deb qoladi', () {
      const walls = <Wall>[
        Wall(length: 5, turn: 90),
        Wall(length: 4, turn: 90),
        Wall(length: 5, turn: 90),
      ];
      final geometry = RoomGeometry.fromWalls(walls);
      expect(geometry.isClosed, isFalse);
      expect(geometry.impliedEdge!.length, closeTo(4, 0.0001));
    });
  });

  group('Tashqi normal', () {
    test('yozuvlar shakldan tashqarida joylashadi', () {
      final built = ShapePresets.rectangle(length: 6, width: 4);
      final geometry = RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      );
      final center = geometry.bounds.center;
      for (final edge in geometry.edges) {
        final probe = edge.mid + edge.outwardNormal * 0.5;
        // Tashqi nuqta markazdan qirra o'rtasiga qaraganda uzoqroq bo'ladi.
        expect(
          (probe - center).distance,
          greaterThan((edge.mid - center).distance),
        );
      }
    });
  });
}
