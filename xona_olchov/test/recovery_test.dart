import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/data/sketch_store.dart';
import 'package:xona_olchov/models/geo_point.dart';
import 'package:xona_olchov/models/room_sketch.dart';

String payload(List<RoomSketch> items) => jsonEncode(<String, dynamic>{
      'version': SketchStore.schemaVersion,
      'items': items.map((item) => item.toJson()).toList(),
    });

RoomSketch sketch(String id) {
  final now = DateTime.now();
  final built = ShapePresets.rectangle(length: 5, width: 4);
  return RoomSketch(
    id: id,
    name: 'Xona $id',
    walls: built.walls,
    startHeading: built.startHeading,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Xotirani tiklash', () {
    test('asosiy yozuv bo‘sh bo‘lsa zaxiradan o‘qiladi', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SketchStore.storageKey: payload(const <RoomSketch>[]),
        SketchStore.backupKey: payload(<RoomSketch>[sketch('a'), sketch('b')]),
      });
      final store = await SketchStore.open();
      expect(store.count, 2, reason: 'bo‘sh asosiy yozuv zaxirani yashirmasin');
    });

    test('asosiy yozuv buzilgan bo‘lsa zaxiradan o‘qiladi', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SketchStore.storageKey: '{"version":1,"items":[{"id":',
        SketchStore.backupKey: payload(<RoomSketch>[sketch('a')]),
      });
      final store = await SketchStore.open();
      expect(store.count, 1);
    });

    test('asosiy yozuvda chizma bo‘lsa u ustun', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SketchStore.storageKey: payload(<RoomSketch>[sketch('yangi')]),
        SketchStore.backupKey: payload(<RoomSketch>[sketch('eski')]),
      });
      final store = await SketchStore.open();
      expect(store.count, 1);
      expect(store.byId('yangi'), isNotNull);
    });

    test('ikkalasi ham bo‘sh bo‘lsa xatosiz ochiladi', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await SketchStore.open();
      expect(store.count, 0);
    });
  });

  group('Lokatsiya JSON', () {
    test('koordinatasiz yozuv nuqta bermaydi', () {
      expect(GeoPoint.tryFromJson(<String, dynamic>{}), isNull);
      expect(
        GeoPoint.tryFromJson(<String, dynamic>{'lat': 'x', 'lng': 69.2}),
        isNull,
      );
      expect(
        GeoPoint.tryFromJson(<String, dynamic>{'lat': 95, 'lng': 69.2}),
        isNull,
        reason: '95° kenglik mavjud emas',
      );
    });

    test('to‘g‘ri yozuv nuqta beradi', () {
      final point = GeoPoint.tryFromJson(<String, dynamic>{
        'lat': '41.311081',
        'lng': 69.240562,
        'source': 'gps',
      });
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(41.311081, 1e-9));
      expect(point.source, LocationSource.gps);
    });

    test('chizma buzilgan lokatsiya bilan ham o‘qiladi, nuqtasiz', () {
      final json = sketch('l').toJson()
        ..['location'] = <String, dynamic>{'address': 'Noma‘lum'};
      final restored = RoomSketch.fromJson(json);
      expect(restored.location, isNull);
      expect(restored.hasLocation, isFalse);
    });
  });
}
