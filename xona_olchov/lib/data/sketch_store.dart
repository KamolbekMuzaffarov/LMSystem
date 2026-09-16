import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/room_sketch.dart';

/// Chizmalar ombori — SharedPreferences ustida ishlaydi.
///
/// **Muhim:** bu klassda chizmani o'chirish metodi ataylab mavjud emas.
/// Saqlangan chizma faqat tahrirlanishi mumkin, o'chirilmaydi.
class SketchStore extends ChangeNotifier {
  SketchStore._(this._prefs, List<RoomSketch> initial)
    : _sketches = List<RoomSketch>.of(initial) {
    _sort();
  }

  static const String storageKey = 'xona_olchov.sketches';
  static const String backupKey = 'xona_olchov.sketches.backup';
  static const int schemaVersion = 1;

  final SharedPreferences _prefs;
  final List<RoomSketch> _sketches;

  /// Oxirgi saqlashda xatolik bo'lsa — sababi.
  String? _lastError;
  String? get lastError => _lastError;

  /// Yangilanish tartibida (eng yangisi birinchi) ro'yxat.
  List<RoomSketch> get sketches => List<RoomSketch>.unmodifiable(_sketches);

  int get count => _sketches.length;

  static Future<SketchStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return SketchStore._(prefs, readAll(prefs));
  }

  /// Asosiy yozuvni, u bo'sh bo'lsa zaxira nusxani o'qiydi.
  ///
  /// Asosiy yozuv o'qilsa-yu, ichi bo'sh chiqsa ham zaxiraga qaraladi:
  /// yozish yarim yo'lda uzilib, `items` bo'sh qolishi mumkin — bunday
  /// holatda chizmalar zaxiradan tiklanadi.
  @visibleForTesting
  static List<RoomSketch> readAll(SharedPreferences prefs) {
    final primary = _read(prefs, storageKey);
    if (primary != null && primary.isNotEmpty) return primary;
    final backup = _read(prefs, backupKey);
    if (backup != null && backup.isNotEmpty) return backup;
    return primary ?? backup ?? const <RoomSketch>[];
  }

  /// Testlar uchun: tayyor ro'yxat bilan ombor yaratish.
  @visibleForTesting
  static Future<SketchStore> openWith(List<RoomSketch> initial) async {
    final prefs = await SharedPreferences.getInstance();
    return SketchStore._(prefs, initial);
  }

  RoomSketch? byId(String id) {
    for (final sketch in _sketches) {
      if (sketch.id == id) return sketch;
    }
    return null;
  }

  /// Yangi chizma qo'shish.
  Future<bool> add(RoomSketch sketch) async {
    _sketches.add(sketch);
    _sort();
    notifyListeners();
    return _persist();
  }

  /// Mavjud chizmani yangilash. Topilmasa — qo'shiladi (ma'lumot yo'qolmaydi).
  Future<bool> update(RoomSketch sketch) async {
    final index = _sketches.indexWhere((item) => item.id == sketch.id);
    if (index == -1) {
      _sketches.add(sketch);
    } else {
      _sketches[index] = sketch;
    }
    _sort();
    notifyListeners();
    return _persist();
  }

  /// Zaxira nusxadan chizmalarni qo'shish.
  ///
  /// Mavjud chizma faqat kelgan nusxa yangiroq bo'lsa yangilanadi; hech narsa
  /// o'chirilmaydi.
  Future<({int added, int updated, int skipped})> importAll(
    List<RoomSketch> incoming,
  ) async {
    var added = 0;
    var updated = 0;
    var skipped = 0;

    for (final sketch in incoming) {
      if (sketch.id.isEmpty) {
        skipped++;
        continue;
      }
      final index = _sketches.indexWhere((item) => item.id == sketch.id);
      if (index == -1) {
        _sketches.add(sketch);
        added++;
      } else if (sketch.updatedAt.isAfter(_sketches[index].updatedAt)) {
        _sketches[index] = sketch;
        updated++;
      } else {
        skipped++;
      }
    }

    if (added == 0 && updated == 0) {
      return (added: 0, updated: 0, skipped: skipped);
    }
    _sort();
    notifyListeners();
    await _persist();
    return (added: added, updated: updated, skipped: skipped);
  }

  void _sort() {
    _sketches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<bool> _persist() async {
    try {
      final payload = jsonEncode(<String, dynamic>{
        'version': schemaVersion,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'items': _sketches.map((item) => item.toJson()).toList(growable: false),
      });

      // Avvalgi holat zaxiraga ko'chiriladi — yozish uzilib qolsa ham
      // chizmalar yo'qolmaydi.
      final previous = _prefs.getString(storageKey);
      if (previous != null && previous.isNotEmpty) {
        await _prefs.setString(backupKey, previous);
      }
      final ok = await _prefs.setString(storageKey, payload);
      _lastError = ok ? null : "Xotiraga yozib bo‘lmadi";
      return ok;
    } catch (error) {
      _lastError = '$error';
      debugPrint('SketchStore saqlashda xato: $error');
      return false;
    }
  }

  static List<RoomSketch>? _read(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final items = decoded['items'];
      if (items is! List) return null;
      final result = <RoomSketch>[];
      for (final item in items) {
        if (item is Map) {
          try {
            result.add(RoomSketch.fromJson(Map<String, dynamic>.from(item)));
          } catch (error) {
            debugPrint("Chizmani o‘qib bo‘lmadi: $error");
          }
        }
      }
      return result;
    } catch (error) {
      debugPrint("Xotirani o‘qishda xato ($key): $error");
      return null;
    }
  }
}

/// Ombordan widget daraxti orqali foydalanish.
class SketchScope extends InheritedNotifier<SketchStore> {
  const SketchScope({
    super.key,
    required SketchStore store,
    required super.child,
  }) : super(notifier: store);

  static SketchStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SketchScope>();
    assert(scope?.notifier != null, 'SketchScope topilmadi');
    return scope!.notifier!;
  }

  /// Qayta qurilishga obuna bo'lmasdan omborga murojaat.
  static SketchStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SketchScope>();
    assert(scope?.notifier != null, 'SketchScope topilmadi');
    return scope!.notifier!;
  }
}
