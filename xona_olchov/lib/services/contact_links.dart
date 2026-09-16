import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../models/lead.dart';

/// Tashqi aloqa yo'llari: qo'ng'iroq, Telegram va sayt.
abstract final class ContactLinks {
  /// Raqamga qo'ng'iroq qiladi. Raqam noto'g'ri bo'lsa `false`.
  static Future<bool> call(String? phone) async {
    final normalized = phone == null ? null : PhoneRules.normalize(phone);
    if (normalized == null) return false;
    return _open(Uri(scheme: 'tel', path: normalized));
  }

  /// SMS yozish oynasini ochadi.
  static Future<bool> sms(String? phone, {String? body}) async {
    final normalized = phone == null ? null : PhoneRules.normalize(phone);
    if (normalized == null) return false;
    return _open(
      Uri(
        scheme: 'sms',
        path: normalized,
        queryParameters: body == null ? null : <String, String>{'body': body},
      ),
    );
  }

  /// Telegram kanalini yoki botni ochadi.
  static Future<bool> telegram([String handle = Brand.telegramChannel]) =>
      _open(Uri.parse(Brand.telegramUrl(handle)));

  /// Arizani Telegram bot orqali yuborish — server ishlamay qolganda.
  ///
  /// Matn vaqtinchalik xotiraga ko'chiriladi, bot oynasi ochiladi va
  /// foydalanuvchi uni bitta bosishda joylashtiradi.
  static Future<bool> sendViaTelegram(Lead lead) async {
    await Clipboard.setData(ClipboardData(text: lead.toMessage()));
    return telegram(Brand.telegramBot);
  }

  /// Saytni brauzerda ochadi.
  static Future<bool> site() => _open(Uri.parse(Brand.siteUrl));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Havolani ochib bo‘lmadi ($uri): $error');
      return false;
    }
  }
}
