import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/data/sketch_store.dart';
import 'package:xona_olchov/models/room_sketch.dart';
import 'package:xona_olchov/services/backup_service.dart';

RoomSketch build(String id, {String name = 'Xona', DateTime? updatedAt}) {
  final built = ShapePresets.rectangle(length: 5, width: 4);
  final now = DateTime(2026, 9, 12, 10);
  return RoomSketch(
    id: id,
    name: name,
    kind: RoomKind.rectangle,
    walls: built.walls,
    startHeading: built.startHeading,
    height: 2.8,
    reservePercent: 10,
    presetInputs: const <String, double>{'length': 5, 'width': 4},
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Zaxira nusxa matni', () {
    test('yozib-o‘qilganda barcha maydonlar saqlanadi', () {
      final sketches = <RoomSketch>[build('a', name: 'Zal'), build('b')];
      final parsed = BackupService.decode(BackupService.encode(sketches));
      expect(parsed.error, isNull);
      expect(parsed.sketches.length, 2);
      expect(parsed.sketches.first.name, 'Zal');
      expect(parsed.sketches.first.height, 2.8);
      expect(parsed.sketches.first.reservePercent, 10);
      expect(parsed.sketches.first.area, closeTo(20, 0.0001));
    });

    test('bitta chizmaning JSON’i ham qabul qilinadi', () {
      final parsed = BackupService.decode(jsonEncode(build('solo').toJson()));
      expect(parsed.sketches.length, 1);
      expect(parsed.sketches.first.id, 'solo');
    });

    test('ro‘yxat ko‘rinishi ham qabul qilinadi', () {
      final raw = jsonEncode(<dynamic>[build('x').toJson()]);
      expect(BackupService.decode(raw).sketches.length, 1);
    });

    test('buzilgan yozuvlar tashlab ketiladi', () {
      final raw = jsonEncode(<String, dynamic>{
        'items': <dynamic>[
          build('ok').toJson(),
          'chizma emas',
          <String, dynamic>{'id': '', 'walls': <dynamic>[]},
        ],
      });
      final parsed = BackupService.decode(raw);
      expect(parsed.sketches.length, 1);
      expect(parsed.error, contains('2'));
    });

    test('xato matnlar tushunarli xabar beradi', () {
      expect(BackupService.decode('').error, isNotNull);
      expect(BackupService.decode('salom').error, contains('JSON'));
      expect(BackupService.decode('{"a":1}').error, isNotNull);
      expect(BackupService.decode('{"items":[]}').error, isNotNull);
    });

    test('fayl nomi sanaga bog‘langan', () {
      expect(
        BackupService.backupFileName(DateTime(2026, 3, 7)),
        'hisob-zaxira-2026-03-07.json',
      );
    });
  });

  group('Zaxiradan tiklash', () {
    test('yangi chizmalar qo‘shiladi, eskilari o‘zgarmaydi', () async {
      final store = await SketchStore.open();
      await store.add(build('a', name: 'Asl'));

      final result = await store.importAll(<RoomSketch>[
        build('a', name: 'Eski nusxa', updatedAt: DateTime(2026, 1, 1)),
        build('b', name: 'Yangi'),
      ]);

      expect(result.added, 1);
      expect(result.updated, 0);
      expect(result.skipped, 1);
      expect(store.count, 2);
      expect(store.byId('a')!.name, 'Asl'); // eski nusxa ustidan yozmadi
      expect(store.byId('b')!.name, 'Yangi');
    });

    test('yangiroq nusxa mavjudini yangilaydi', () async {
      final store = await SketchStore.open();
      await store.add(build('a', name: 'Eski'));

      final result = await store.importAll(<RoomSketch>[
        build('a', name: 'Yangilangan', updatedAt: DateTime(2027, 1, 1)),
      ]);

      expect(result.updated, 1);
      expect(store.count, 1);
      expect(store.byId('a')!.name, 'Yangilangan');
    });

    test('tiklash hech qachon chizmani o‘chirmaydi', () async {
      final store = await SketchStore.open();
      await store.add(build('a'));
      await store.add(build('b'));

      // Bo'sh ro'yxat bilan tiklash — hech narsa yo'qolmaydi.
      final result = await store.importAll(const <RoomSketch>[]);
      expect(result.added, 0);
      expect(store.count, 2);

      final reopened = await SketchStore.open();
      expect(reopened.count, 2);
    });

    test('tiklangan chizmalar xotirada qoladi', () async {
      final store = await SketchStore.open();
      await store.importAll(<RoomSketch>[build('a'), build('b')]);
      final reopened = await SketchStore.open();
      expect(reopened.count, 2);
      expect(reopened.byId('a'), isNotNull);
    });
  });
}
