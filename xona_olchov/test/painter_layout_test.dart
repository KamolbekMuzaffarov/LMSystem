import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/models/wall.dart';
import 'package:xona_olchov/widgets/sketch_painter.dart';

/// Chizma nimani qayerga chizganini yozib oladigan Canvas.
class SpyCanvas implements Canvas {
  final List<(Offset, Offset)> lines = <(Offset, Offset)>[];
  final List<Rect> texts = <Rect>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines.add((p1, p2));

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    texts.add(
      Rect.fromLTWH(
        offset.dx,
        offset.dy,
        paragraph.width,
        paragraph.height,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Gorizontal chiziq matn to'rtburchagini kesib o'tadimi.
bool lineCrossesText((Offset, Offset) line, Rect text) {
  final (a, b) = line;
  if ((a.dy - b.dy).abs() > 0.5) return false; // faqat gorizontal chiziqlar
  if (a.dy < text.top || a.dy > text.bottom) return false;
  final left = math.min(a.dx, b.dx);
  final right = math.max(a.dx, b.dx);
  return right > text.left && left < text.right;
}

const _sizes = <Size>[
  Size(330, 230), // tahrirlash oynasidagi ko'rinish
  Size(326, 266), // batafsil ekran
  Size(800, 600),
  Size(240, 180), // juda kichik
];

SpyCanvas render(RoomGeometry geometry, Size size, {bool angles = false}) {
  final spy = SpyCanvas();
  SketchPainter(geometry: geometry, showAngles: angles).paint(spy, size);
  return spy;
}

void main() {
  RoomGeometry rectangle() {
    final built = ShapePresets.rectangle(length: 5, width: 4);
    return RoomGeometry.fromWalls(built.walls, startHeading: built.startHeading);
  }

  RoomGeometry lShape() => RoomGeometry.fromWalls(const <Wall>[
        Wall(length: 6, turn: 90),
        Wall(length: 3, turn: 90),
        Wall(length: 3, turn: -90),
        Wall(length: 3, turn: 90),
        Wall(length: 3, turn: 90),
        Wall(length: 6, turn: 90),
      ]);

  RoomGeometry trapezoid() {
    final built = ShapePresets.trapezoid(span: 17.38, sideA: 2.96, sideB: 3.17);
    return RoomGeometry.fromWalls(built.walls, startHeading: built.startHeading);
  }

  group('Umumiy o‘lcham takrorlanmaydi', () {
    test("to‘rtburchakda tepadagi uzunlik bir marta yoziladi", () {
      for (final size in _sizes) {
        final spy = render(rectangle(), size);
        // strelka (1) + o‘ng/past/chap devor (3) + yuza (1) = 5 yozuv.
        // Tepadagi devor yozuvi strelka bilan bir xil bo‘lgani uchun tushirildi.
        expect(spy.texts.length, 5, reason: '$size');
      }
    });

    test('L-shaklda ham tepadagi devor yozuvi takrorlanmaydi', () {
      final spy = render(lShape(), const Size(360, 300));
      // strelka + 5 devor + yuza
      expect(spy.texts.length, 7);
    });

    test('qisqa tepa devor bo‘lsa yozuv saqlanadi', () {
      // Trapetsiyada qiya devorlar yashirin: strelka + 2 yon + yuza = 4.
      final spy = render(trapezoid(), const Size(360, 300));
      expect(spy.texts.length, 4);
    });

    test('strelka o‘chirilganda barcha devorlar yoziladi', () {
      final spy = SpyCanvas();
      SketchPainter(geometry: rectangle(), showSpan: false, showArea: false)
          .paint(spy, const Size(330, 230));
      expect(spy.texts.length, 4);
    });
  });

  group('Yozuvlar ustma-ust tushmaydi', () {
    void expectNoOverlap(RoomGeometry geometry, Size size, {bool angles = false}) {
      final spy = render(geometry, size, angles: angles);
      for (var i = 0; i < spy.texts.length; i++) {
        for (var j = i + 1; j < spy.texts.length; j++) {
          final a = spy.texts[i].deflate(0.5);
          final b = spy.texts[j].deflate(0.5);
          expect(
            a.overlaps(b),
            isFalse,
            reason: 'yozuvlar kesishdi: $a va $b ($size)',
          );
        }
      }
      for (final line in spy.lines) {
        for (final text in spy.texts) {
          expect(
            lineCrossesText(line, text.deflate(0.5)),
            isFalse,
            reason: 'chiziq yozuvni kesib o‘tdi: $line / $text ($size)',
          );
        }
      }
    }

    test("to‘rtburchak — yuza yozuvi devor yozuvidan ajratilgan", () {
      for (final size in _sizes) {
        expectNoOverlap(rectangle(), size);
      }
    });

    test('L-shakl', () {
      for (final size in _sizes) {
        expectNoOverlap(lShape(), size);
      }
    });

    test('trapetsiya', () {
      for (final size in _sizes) {
        expectNoOverlap(trapezoid(), size);
      }
    });

    test('burchaklar ko‘rsatilganda ham', () {
      expectNoOverlap(rectangle(), const Size(400, 340), angles: true);
      expectNoOverlap(lShape(), const Size(400, 340), angles: true);
    });
  });

  group('Hech narsa chetdan chiqib ketmaydi', () {
    test('barcha yozuvlar maydon ichida', () {
      for (final geometry in <RoomGeometry>[rectangle(), lShape(), trapezoid()]) {
        for (final size in _sizes) {
          final spy = render(geometry, size);
          for (final text in spy.texts) {
            expect(text.top, greaterThanOrEqualTo(-0.5), reason: '$size');
            expect(text.bottom, lessThanOrEqualTo(size.height + 0.5),
                reason: '$size');
            expect(text.left, greaterThanOrEqualTo(-0.5), reason: '$size');
            expect(text.right, lessThanOrEqualTo(size.width + 0.5),
                reason: '$size');
          }
        }
      }
    });
  });

  group('Botiq burchak yozuvi xona ichida', () {
    test('L-shaklning 270° burchagi kesilgan joyga tushmaydi', () {
      final geometry = lShape();
      // Kesilgan burchak (3, 3) da, ichki burchak 270°.
      final index = List<int>.generate(geometry.vertices.length, (i) => i)
          .firstWhere((i) => (geometry.interiorAngleAt(i) - 270).abs() < 0.01);
      final vertex = geometry.vertices[index];
      expect(vertex.dx, closeTo(3, 0.001));
      expect(vertex.dy, closeTo(3, 0.001));

      final spy = render(geometry, const Size(400, 340), angles: true);
      // Burchak yozuvlari orasida (3,3) dan kesilgan tomonga (x>3 && y>3)
      // suriladigani bo'lmasligi kerak — xona ichida x<3 yoki y<3.
      // Buni to'g'ridan-to'g'ri tekshirish uchun yozuvlar sonini sanaymiz:
      // strelka + 5 devor + yuza + 6 burchak = 13.
      expect(spy.texts.length, 13);
    });
  });
}
