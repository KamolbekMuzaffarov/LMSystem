import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/data/sketch_store.dart';
import 'package:xona_olchov/models/geo_point.dart';
import 'package:xona_olchov/models/room_sketch.dart';
import 'package:xona_olchov/models/wall.dart';

RoomSketch buildSketch(String id, {String name = 'Xona'}) {
  final now = DateTime.now();
  final built = ShapePresets.trapezoid(span: 17.38, sideA: 2.96, sideB: 3.17);
  return RoomSketch(
    id: id,
    name: name,
    description: 'Sinov uchun',
    kind: RoomKind.trapezoid,
    walls: built.walls,
    startHeading: built.startHeading,
    presetInputs: const <String, double>{
      'span': 17.38,
      'sideA': 2.96,
      'sideB': 3.17,
    },
    location: const GeoPoint(
      latitude: 41.311081,
      longitude: 69.240562,
      address: 'Toshkent',
      source: LocationSource.gps,
    ),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('chizma saqlanadi va qayta o‘qiladi', () async {
    final store = await SketchStore.open();
    expect(store.count, 0);

    expect(await store.add(buildSketch('a1', name: 'Zal')), isTrue);
    expect(store.count, 1);

    final reopened = await SketchStore.open();
    expect(reopened.count, 1);
    final restored = reopened.byId('a1');
    expect(restored, isNotNull);
    expect(restored!.name, 'Zal');
    expect(restored.kind, RoomKind.trapezoid);
    expect(restored.area, closeTo(53.2697, 0.001));
    expect(restored.location?.address, 'Toshkent');
    expect(restored.presetInputs['span'], 17.38);
  });

  test('tahrirlash mavjud chizmani yangilaydi, nusxa yaratmaydi', () async {
    final store = await SketchStore.open();
    final sketch = buildSketch('b1', name: 'Eski nom');
    await store.add(sketch);
    await store.update(sketch.copyWith(name: 'Yangi nom'));

    expect(store.count, 1);
    expect(store.byId('b1')!.name, 'Yangi nom');

    final reopened = await SketchStore.open();
    expect(reopened.count, 1);
    expect(reopened.byId('b1')!.name, 'Yangi nom');
  });

  test('omborda o‘chirish imkoniyati yo‘q', () {
    // Bu ro'yxat SketchStore ochiq API'sining to'liq ro'yxati.
    // Yangi metod qo'shilsa, bu test uni ko'rib chiqishga majbur qiladi.
    const publicApi = <String>{
      'sketches',
      'count',
      'byId',
      'add',
      'update',
      'lastError',
      'open',
      'openWith',
      'storageKey',
      'backupKey',
      'schemaVersion',
    };
    const forbidden = <String>['delete', 'remove', 'clear', 'erase', 'wipe'];
    for (final name in publicApi) {
      for (final word in forbidden) {
        expect(
          name.toLowerCase().contains(word),
          isFalse,
          reason: '$name o‘chirishga o‘xshaydi',
        );
      }
    }
  });

  test('bir nechta chizma tartib bilan saqlanadi', () async {
    final store = await SketchStore.open();
    for (var i = 0; i < 12; i++) {
      await store.add(buildSketch('id$i', name: 'Xona $i'));
      // Yangilanish vaqtlari farq qilsin.
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(store.count, 12);

    final reopened = await SketchStore.open();
    expect(reopened.count, 12);
    // Eng yangisi birinchi.
    expect(reopened.sketches.first.id, 'id11');
    for (var i = 0; i < 12; i++) {
      expect(reopened.byId('id$i'), isNotNull);
    }
  });

  test('buzilgan yozuv zaxiradan tiklanadi', () async {
    final store = await SketchStore.open();
    await store.add(buildSketch('c1'));
    await store.add(buildSketch('c2'));

    final prefs = await SharedPreferences.getInstance();
    // Asosiy yozuvni buzamiz — zaxira saqlanib qolgan.
    await prefs.setString(SketchStore.storageKey, '{bu json emas');

    final recovered = await SketchStore.open();
    expect(recovered.count, greaterThanOrEqualTo(1));
    expect(recovered.byId('c1'), isNotNull);
  });

  test('chizmalar ro‘yxati o‘zgartirib bo‘lmaydigan', () async {
    final store = await SketchStore.open();
    await store.add(buildSketch('d1'));
    expect(() => store.sketches.add(buildSketch('d2')), throwsUnsupportedError);
  });

  test('JSON aylanishi barcha maydonlarni saqlaydi', () {
    final sketch = buildSketch('e1', name: 'Test');
    final restored = RoomSketch.fromJson(sketch.toJson());

    expect(restored.id, sketch.id);
    expect(restored.name, sketch.name);
    expect(restored.description, sketch.description);
    expect(restored.kind, sketch.kind);
    expect(restored.walls.length, sketch.walls.length);
    expect(restored.startHeading, closeTo(sketch.startHeading, 1e-9));
    expect(restored.area, closeTo(sketch.area, 1e-9));
    expect(restored.location!.latitude, closeTo(41.311081, 1e-9));
    expect(restored.location!.source, LocationSource.gps);
    expect(
      restored.createdAt.millisecondsSinceEpoch,
      sketch.createdAt.millisecondsSinceEpoch,
    );
  });

  test('nuqsonli JSON ilovani buzmaydi', () {
    final restored = RoomSketch.fromJson(<String, dynamic>{
      'id': 'x',
      'walls': <dynamic>[
        <String, dynamic>{'length': 'salom', 'turn': null},
        'devor emas',
      ],
      'location': <String, dynamic>{'lat': 'yo‘q', 'lng': null},
    });
    expect(restored.id, 'x');
    expect(restored.walls.length, 1);
    expect(restored.walls.first.length, 0);
    expect(restored.geometry.isEmpty, isTrue);
  });

  test('eski schema (presetInputs yo‘q) o‘qiladi', () {
    final restored = RoomSketch.fromJson(<String, dynamic>{
      'id': 'old',
      'name': 'Eski chizma',
      'walls': <dynamic>[
        <String, dynamic>{'length': 5, 'turn': 90},
        <String, dynamic>{'length': 4, 'turn': 90},
        <String, dynamic>{'length': 5, 'turn': 90},
        <String, dynamic>{'length': 4, 'turn': 90},
      ],
    });
    expect(restored.walls.length, 4);
    expect(restored.area, closeTo(20, 0.0001));
    expect(restored.presetInputs, isEmpty);
  });

  test('Wall JSON ixcham saqlanadi', () {
    const wall = Wall(length: 3.5, turn: -90);
    final json = wall.toJson();
    expect(json.containsKey('label'), isFalse);
    expect(json.containsKey('showLength'), isFalse);
    expect(Wall.fromJson(json), wall);
  });
}
