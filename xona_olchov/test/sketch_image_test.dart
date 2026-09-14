import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/core/sketch_image.dart';
import 'package:xona_olchov/models/room_sketch.dart';

RoomSketch sample({double? height}) {
  final built = ShapePresets.trapezoid(span: 17.38, sideA: 2.96, sideB: 3.17);
  final now = DateTime(2026, 9, 12, 14, 41);
  return RoomSketch(
    id: 'a1',
    name: "Katta zal",
    kind: RoomKind.trapezoid,
    walls: built.walls,
    startHeading: built.startHeading,
    height: height,
    reservePercent: 10,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('chizma PNG rasmga aylanadi', (tester) async {
    await tester.runAsync(() async {
      final bytes = await SketchImage.render(
        sample(height: 2.8),
        width: 900,
        height: 1100,
      );
      expect(bytes.length, greaterThan(2000));
      // PNG sarlavhasi
      expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    });
  });

  testWidgets('balandliksiz chizma ham rasmga aylanadi', (tester) async {
    await tester.runAsync(() async {
      final bytes = await SketchImage.render(sample(), width: 600, height: 700);
      expect(bytes.length, greaterThan(1000));
    });
  });

  test('fayl nomi xavfsiz bo‘ladi', () {
    final built = ShapePresets.rectangle(length: 5, width: 4);
    final now = DateTime(2026, 3, 5);
    final sketch = RoomSketch(
      id: 'b',
      name: 'Yotoq/xona #2: katta',
      walls: built.walls,
      createdAt: now,
      updatedAt: now,
    );
    final name = SketchImage.fileName(sketch);
    expect(name, 'Yotoqxona-2-katta-2026-03-05.png');
    expect(name.contains('/'), isFalse);
  });
}
