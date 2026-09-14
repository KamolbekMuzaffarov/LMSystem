import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/core/formatters.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/models/geo_point.dart';
import 'package:xona_olchov/models/opening.dart';
import 'package:xona_olchov/models/room_sketch.dart';
import 'package:xona_olchov/services/backup_service.dart';

RoomSketch sample() {
  final built = ShapePresets.rectangle(length: 5, width: 4);
  return RoomSketch(
    id: 'c1',
    name: 'Zal "katta"',
    description: 'Ikki qator;\nizoh',
    kind: RoomKind.rectangle,
    walls: built.walls,
    startHeading: built.startHeading,
    height: 2.8,
    reservePercent: 10,
    openings: const <Opening>[
      Opening(kind: OpeningKind.door, width: 0.8, height: 2.05),
    ],
    location: const GeoPoint(
      latitude: 41.311081,
      longitude: 69.240562,
      address: 'Toshkent',
    ),
    createdAt: DateTime(2026, 9, 14, 10, 30),
    updatedAt: DateTime(2026, 9, 14, 11, 45),
  );
}

/// `;` bilan ajratilgan, qo'shtirnoqli CSV qatorini kataklarga bo'ladi.
List<String> cells(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ';' && !inQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString());
  return result;
}

void main() {
  group('CSV eksport', () {
    test('sarlavha va qator ustunlari mos keladi', () {
      final csv = BackupService.encodeCsv(<RoomSketch>[sample()]);
      expect(csv.startsWith('﻿'), isTrue, reason: 'Excel uchun BOM');

      // Tavsif ichidagi yangi qator katak ichida qoladi — qatorlarni
      // qo'shtirnoq holatini hisobga olib ajratamiz.
      final lines = <String>[];
      final buffer = StringBuffer();
      var inQuotes = false;
      for (final char in csv.substring(1).split('')) {
        if (char == '"') inQuotes = !inQuotes;
        if (char == '\n' && !inQuotes) {
          lines.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      }
      expect(lines.length, 2);

      final header = cells(lines[0]);
      final row = cells(lines[1]);
      expect(header, BackupService.csvColumns);
      expect(row.length, header.length);

      final byName = Map<String, String>.fromIterables(header, row);
      expect(byName['Nomi'], 'Zal "katta"');
      expect(byName['Yuza (m²)'], '20.00');
      expect(byName['Perimetr (m)'], '18.00');
      expect(byName['Balandlik (m)'], '2.80');
      expect(byName['Devorlar yuzasi (m²)'], '48.76');
      expect(byName['Hajmi (m³)'], '56.00');
      expect(byName['Eshik/deraza (dona)'], '1');
      expect(byName['Plintus (m)'], '17.20');
      expect(byName['Zaxira (%)'], '10');
      expect(byName['Kenglik (lat)'], '41.311081');
      expect(byName['Manzil'], 'Toshkent');
      expect(byName['Tavsif'], 'Ikki qator;\nizoh');
    });

    test('bo‘sh ro‘yxat faqat sarlavha beradi', () {
      final csv = BackupService.encodeCsv(const <RoomSketch>[]);
      expect(csv.trim().split('\n').length, 1);
    });

    test('fayl nomlari sanaga bog‘langan', () {
      final date = DateTime(2026, 9, 14);
      expect(BackupService.csvFileName(date), 'hisob-jadval-2026-09-14.csv');
      expect(BackupService.backupFileName(date), 'hisob-zaxira-2026-09-14.json');
    });
  });

  group('Pul formati', () {
    test('uch xonadan ajratiladi', () {
      expect(Fmt.money(0), '0');
      expect(Fmt.money(999), '999');
      expect(Fmt.money(1000), '1 000');
      expect(Fmt.money(4981000), '4 981 000');
      expect(Fmt.money(1234567.8), '1 234 568');
      expect(Fmt.money(-2500), '-2 500');
      expect(Fmt.money(double.nan), '—');
    });

    test('hajm formati', () {
      expect(Fmt.volume(56), '56.00 m³');
    });
  });
}
