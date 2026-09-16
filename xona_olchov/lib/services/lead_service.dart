import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/brand.dart';
import '../models/lead.dart';

/// Arizani yuborish natijasi.
enum SendOutcome {
  /// Server qabul qildi.
  sent,

  /// Internet yo'q yoki server javob bermadi — keyin qayta urinamiz.
  offline,

  /// Server ma'lumotni rad etdi — qayta yuborish foyda bermaydi.
  rejected;

  bool get canRetry => this == SendOutcome.offline;
}

class SendResult {
  const SendResult(this.outcome, {this.message});

  final SendOutcome outcome;
  final String? message;

  bool get isSent => outcome == SendOutcome.sent;

  String get userMessage {
    if (message != null && message!.isNotEmpty) return message!;
    return switch (outcome) {
      SendOutcome.sent => 'Ariza yuborildi — tez orada qo‘ng‘iroq qilamiz',
      SendOutcome.offline =>
        'Internet yo‘q — ariza saqlandi va ulanish tiklanganda yuboriladi',
      SendOutcome.rejected => 'Ariza qabul qilinmadi — ma‘lumotni tekshiring',
    };
  }
}

/// Arizani saytning serveriga (Vercel) yuboradigan xizmat.
///
/// Server javob bermasa ariza yo'qolmaydi: chaqiruvchi uni navbatda qoldiradi
/// va keyin qayta urinadi.
class LeadService {
  LeadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration timeout = Duration(seconds: 12);

  /// Yuborish manzili.
  static Uri get endpoint => Uri.https(Brand.apiHost, Brand.leadPath);

  Future<SendResult> send(Lead lead) async {
    // Yuborishdan oldin oddiy tekshiruv — bo'sh ariza serverga bormasin.
    if (!NameRules.isValid(lead.name) || !PhoneRules.isValid(lead.phone)) {
      return const SendResult(
        SendOutcome.rejected,
        message: 'Ism va telefon raqamini to‘g‘ri kiriting',
      );
    }

    try {
      final response = await _client
          .post(
            endpoint,
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(lead.toPayload()),
          )
          .timeout(timeout);

      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        return const SendResult(SendOutcome.sent);
      }
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return SendResult(
          SendOutcome.rejected,
          message: _serverMessage(response.body),
        );
      }
      // 5xx, 429, 408 — server vaqtincha band. Keyin qayta urinamiz.
      return SendResult(
        SendOutcome.offline,
        message: 'Server javob bermadi ($code) — ariza navbatda saqlandi',
      );
    } on TimeoutException {
      return const SendResult(
        SendOutcome.offline,
        message: 'Server uzoq javob bermadi — ariza navbatda saqlandi',
      );
    } on SocketException {
      return const SendResult(SendOutcome.offline);
    } on http.ClientException {
      return const SendResult(SendOutcome.offline);
    } catch (error) {
      debugPrint('Ariza yuborishda xato: $error');
      return const SendResult(SendOutcome.offline);
    }
  }

  /// Server qaytargan xatolik matni (bo'lsa).
  static String? _serverMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final key in const <String>['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      // JSON bo'lmasa — umumiy xabar ishlatiladi.
    }
    return null;
  }

  void dispose() => _client.close();
}
