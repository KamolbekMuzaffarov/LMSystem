import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../data/potolok_store.dart';
import '../models/ceiling.dart';
import '../models/lead.dart';
import 'lead_service.dart';

/// Arizani saqlash va yuborishni bir joyda boshqaradi.
///
/// Tartib: ariza avval xotiraga yoziladi, keyin serverga uzatiladi. Shu sabab
/// internet uzilib qolsa ham ariza yo'qolmaydi — u navbatda qoladi va
/// [flushPending] uni qayta yuboradi.
class LeadSender {
  LeadSender({
    required this.store,
    LeadService? service,
    Future<bool> Function()? isOnline,
  })  : _service = service ?? LeadService(),
        _isOnline = isOnline ?? _defaultIsOnline;

  final PotolokStore store;
  final LeadService _service;
  final Future<bool> Function() _isOnline;

  /// Bitta ariza uchun eng ko'p urinish — undan keyin foydalanuvchi o'zi
  /// Telegram yoki qo'ng'iroq orqali yuboradi.
  static const int maxAttempts = 8;

  /// Yangi ariza yaratadi, saqlaydi va yuborishga urinadi.
  Future<SendResult> submit({
    required String name,
    required String phone,
    double? area,
    CeilingDesign? design,
    String? address,
    String comment = '',
  }) async {
    final cleanName = NameRules.clean(name);
    final normalizedPhone = PhoneRules.normalize(phone);
    if (!NameRules.isValid(cleanName) || normalizedPhone == null) {
      return const SendResult(
        SendOutcome.rejected,
        message: 'Ism va telefon raqamini to‘g‘ri kiriting',
      );
    }

    final lead = Lead(
      id: Ids.generate(),
      name: cleanName,
      phone: normalizedPhone,
      area: CeilingPrice.validArea(area),
      design: design,
      address: address?.trim().isEmpty ?? true ? null : address!.trim(),
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    await store.add(lead);
    return _deliver(lead);
  }

  /// Navbatdagi arizalarni qayta yuboradi. Nechtasi yetib borgani qaytadi.
  Future<int> flushPending() async {
    final queue = store.pending;
    if (queue.isEmpty) return 0;
    if (!await _isOnline()) return 0;

    var delivered = 0;
    for (final lead in queue) {
      if (lead.attempts >= maxAttempts) continue;
      final result = await _deliver(lead);
      if (result.isSent) {
        delivered++;
      } else if (result.outcome == SendOutcome.offline) {
        // Ulanish yana uzildi — qolganlari keyingi safar yuboriladi.
        break;
      }
    }
    return delivered;
  }

  /// Bitta arizani yuboradi va holatini yangilaydi.
  Future<SendResult> _deliver(Lead lead) async {
    final result = await _service.send(lead);
    final updated = switch (result.outcome) {
      SendOutcome.sent => lead.copyWith(
          status: LeadStatus.sent,
          sentAt: DateTime.now(),
          attempts: lead.attempts + 1,
          clearError: true,
        ),
      SendOutcome.rejected => lead.copyWith(
          status: LeadStatus.rejected,
          attempts: lead.attempts + 1,
          error: result.message ?? 'Server rad etdi',
        ),
      SendOutcome.offline => lead.copyWith(
          attempts: lead.attempts + 1,
          error: result.message ?? 'Internet yo‘q',
        ),
    };
    await store.update(updated);
    return result;
  }

  static Future<bool> _defaultIsOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
    } catch (error) {
      debugPrint('Ulanishni tekshirib bo‘lmadi: $error');
      // Tekshirib bo'lmasa — yuborib ko'ramiz.
      return true;
    }
  }

  void dispose() => _service.dispose();
}
