import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/sketch_image.dart';
import '../models/room_sketch.dart';

/// Zaxira nusxa: chizmalarni faylga chiqarish va qaytarib olish.
abstract final class BackupService {
  static const int version = 1;
  static const String marker = 'hisob-backup';

  /// Barcha chizmalarni matn (JSON) ko'rinishiga o'tkazadi.
  static String encode(List<RoomSketch> sketches) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': marker,
      'version': version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'count': sketches.length,
      'items': sketches.map((item) => item.toJson()).toList(growable: false),
    });
  }

  /// Matndan chizmalarni o'qiydi.
  ///
  /// Xato bo'lsa [error] to'ldiriladi, [sketches] bo'sh qaytadi.
  static ({List<RoomSketch> sketches, String? error}) decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return (sketches: const <RoomSketch>[], error: 'Matn bo‘sh');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return (
        sketches: const <RoomSketch>[],
        error: 'Bu JSON fayl emas — matnni to‘liq joylashtiring',
      );
    }

    // Bir chizmaning o'zi ham qabul qilinadi.
    final List<dynamic> items;
    if (decoded is Map && decoded['items'] is List) {
      items = decoded['items'] as List<dynamic>;
    } else if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['walls'] is List) {
      items = <dynamic>[decoded];
    } else {
      return (
        sketches: const <RoomSketch>[],
        error: 'Zaxira nusxa tuzilishi tanilmadi',
      );
    }

    final sketches = <RoomSketch>[];
    var broken = 0;
    for (final item in items) {
      if (item is! Map) {
        broken++;
        continue;
      }
      try {
        final sketch = RoomSketch.fromJson(Map<String, dynamic>.from(item));
        if (sketch.id.isEmpty || sketch.walls.isEmpty) {
          broken++;
          continue;
        }
        sketches.add(sketch);
      } catch (_) {
        broken++;
      }
    }

    if (sketches.isEmpty) {
      return (
        sketches: const <RoomSketch>[],
        error: 'Faylda birorta chizma topilmadi',
      );
    }
    return (
      sketches: sketches,
      error: broken == 0 ? null : '$broken yozuvni o‘qib bo‘lmadi',
    );
  }

  static String backupFileName([DateTime? now]) {
    final date = now ?? DateTime.now();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'hisob-zaxira-${date.year}-$month-$day.json';
  }

  /// Zaxira nusxani fayl qilib ulashadi.
  static Future<String?> shareBackup(List<RoomSketch> sketches) async {
    try {
      final file = await _writeTemp(
        backupFileName(),
        utf8.encode(encode(sketches)),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'application/json')],
          subject: 'Hisob — zaxira nusxa',
          text: '${sketches.length} ta chizma zaxirasi',
        ),
      );
      return null;
    } catch (error) {
      debugPrint('Zaxira nusxani ulashishda xato: $error');
      return "Zaxira nusxani ulashib bo'lmadi";
    }
  }

  /// Chizmani rasm qilib ulashadi.
  static Future<String?> shareSketchImage(RoomSketch sketch) async {
    try {
      final bytes = await SketchImage.render(sketch);
      final file = await _writeTemp(SketchImage.fileName(sketch), bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'image/png')],
          subject: sketch.displayName,
          text: '${sketch.displayName} — ${sketch.area.toStringAsFixed(2)} m²',
        ),
      );
      return null;
    } catch (error) {
      debugPrint('Rasmni ulashishda xato: $error');
      return "Rasmni ulashib bo'lmadi";
    }
  }

  static Future<File> _writeTemp(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return file;
  }
}
