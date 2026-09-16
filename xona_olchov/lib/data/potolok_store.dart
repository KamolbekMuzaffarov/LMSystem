import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ceiling.dart';
import '../models/lead.dart';

/// Potolok bo'limining xotirasi: arizalar va sozlamalar.
///
/// Chizmalar ombori kabi bu yerda ham o'chirish yo'q — yuborilgan ariza
/// tarixda qoladi.
class PotolokStore extends ChangeNotifier {
  PotolokStore._(this._prefs, List<Lead> initial, this._settings)
    : _leads = List<Lead>.of(initial) {
    _sort();
  }

  static const String leadsKey = 'potolok.leads';
  static const String settingsKey = 'potolok.settings';
  static const int schemaVersion = 1;

  /// Tarixda saqlanadigan eng ko'p ariza soni.
  static const int maxLeads = 300;

  final SharedPreferences _prefs;
  final List<Lead> _leads;
  Map<String, dynamic> _settings;

  static Future<PotolokStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PotolokStore._(prefs, _readLeads(prefs), _readSettings(prefs));
  }

  /// Testlar uchun: tayyor ro'yxat bilan ombor.
  @visibleForTesting
  static Future<PotolokStore> openWith(List<Lead> initial) async {
    final prefs = await SharedPreferences.getInstance();
    return PotolokStore._(prefs, initial, _readSettings(prefs));
  }

  List<Lead> get leads => List<Lead>.unmodifiable(_leads);

  int get count => _leads.length;

  /// Hali yuborilmagan arizalar — eng eskisi birinchi.
  List<Lead> get pending =>
      _leads.where((lead) => lead.isPending).toList().reversed.toList();

  int get pendingCount => _leads.where((lead) => lead.isPending).length;

  Lead? byId(String id) {
    for (final lead in _leads) {
      if (lead.id == id) return lead;
    }
    return null;
  }

  /// Aloqa uchun telefon raqami (`+998…`). Kiritilmagan bo'lsa `null`.
  String? get contactPhone {
    final raw = _settings['phone'];
    if (raw is! String || raw.isEmpty) return null;
    return PhoneRules.normalize(raw);
  }

  /// Dollar kursi.
  double get somPerUsd {
    final raw = _settings['rate'];
    final value = raw is num ? raw.toDouble() : null;
    return CeilingPrice.normalizeRate(value);
  }

  Future<void> setContactPhone(String? raw) async {
    final normalized = raw == null ? null : PhoneRules.normalize(raw);
    await _saveSettings(<String, dynamic>{
      ..._settings,
      'phone': normalized ?? '',
    });
  }

  Future<void> setSomPerUsd(double value) async {
    await _saveSettings(<String, dynamic>{
      ..._settings,
      'rate': CeilingPrice.normalizeRate(value),
    });
  }

  Future<void> _saveSettings(Map<String, dynamic> next) async {
    _settings = next;
    notifyListeners();
    try {
      await _prefs.setString(settingsKey, jsonEncode(next));
    } catch (error) {
      debugPrint('Potolok sozlamalarini saqlashda xato: $error');
    }
  }

  /// Yangi ariza qo'shadi.
  Future<void> add(Lead lead) async {
    _leads.add(lead);
    _sort();
    _trim();
    notifyListeners();
    await _persist();
  }

  /// Arizaning holatini yangilaydi. Topilmasa — qo'shiladi.
  Future<void> update(Lead lead) async {
    final index = _leads.indexWhere((item) => item.id == lead.id);
    if (index == -1) {
      _leads.add(lead);
    } else {
      _leads[index] = lead;
    }
    _sort();
    notifyListeners();
    await _persist();
  }

  void _sort() => _leads.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Tarix cheksiz o'smasin — eng eskilari (yuborilganlari) tushiriladi.
  void _trim() {
    if (_leads.length <= maxLeads) return;
    for (var i = _leads.length - 1; i >= 0 && _leads.length > maxLeads; i--) {
      if (!_leads[i].isPending) _leads.removeAt(i);
    }
  }

  Future<void> _persist() async {
    try {
      await _prefs.setString(
        leadsKey,
        jsonEncode(<String, dynamic>{
          'version': schemaVersion,
          'items': _leads.map((lead) => lead.toJson()).toList(growable: false),
        }),
      );
    } catch (error) {
      debugPrint('Arizalarni saqlashda xato: $error');
    }
  }

  static List<Lead> _readLeads(SharedPreferences prefs) {
    final raw = prefs.getString(leadsKey);
    if (raw == null || raw.isEmpty) return const <Lead>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <Lead>[];
      final items = decoded['items'];
      if (items is! List) return const <Lead>[];
      final result = <Lead>[];
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final lead = Lead.fromJson(Map<String, dynamic>.from(item));
          if (lead.id.isNotEmpty) result.add(lead);
        } catch (error) {
          debugPrint("Arizani o‘qib bo‘lmadi: $error");
        }
      }
      return result;
    } catch (error) {
      debugPrint("Arizalarni o‘qishda xato: $error");
      return const <Lead>[];
    }
  }

  static Map<String, dynamic> _readSettings(SharedPreferences prefs) {
    final raw = prefs.getString(settingsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

/// Omborni widget daraxti orqali uzatish.
class PotolokScope extends InheritedNotifier<PotolokStore> {
  const PotolokScope({
    super.key,
    required PotolokStore store,
    required super.child,
  }) : super(notifier: store);

  static PotolokStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PotolokScope>();
    assert(scope?.notifier != null, 'PotolokScope topilmadi');
    return scope!.notifier!;
  }

  static PotolokStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<PotolokScope>();
    assert(scope?.notifier != null, 'PotolokScope topilmadi');
    return scope!.notifier!;
  }
}
