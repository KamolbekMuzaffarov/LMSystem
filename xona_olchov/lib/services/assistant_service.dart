import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/brand.dart';
import '../models/chat_message.dart';

/// AI yordamchidan javob olish natijasi.
enum AskOutcome {
  /// Javob keldi.
  ok,

  /// Internet yo'q yoki server javob bermadi — qayta urinsa bo'ladi.
  offline,

  /// Server band (juda ko'p so'rov) — birozdan so'ng urinish kerak.
  busy,

  /// So'rov qabul qilinmadi — qayta yuborish foyda bermaydi.
  failed;

  bool get canRetry => this == AskOutcome.offline || this == AskOutcome.busy;
}

class AskResult {
  const AskResult(this.outcome, {this.reply, this.message});

  final AskOutcome outcome;
  final String? reply;
  final String? message;

  bool get isOk => outcome == AskOutcome.ok && (reply?.isNotEmpty ?? false);

  String get errorText {
    if (message != null && message!.isNotEmpty) return message!;
    return switch (outcome) {
      AskOutcome.ok => '',
      AskOutcome.offline =>
        'Internet yo‘q yoki server javob bermadi — qayta urinib ko‘ring',
      AskOutcome.busy => 'Yordamchi hozir band — birozdan so‘ng urining',
      AskOutcome.failed => 'Javob olib bo‘lmadi',
    };
  }
}

/// AI yordamchi bilan gaplashadigan xizmat.
///
/// Ilova Claude API'ga to'g'ridan-to'g'ri murojaat qilmaydi — barcha
/// suhbat saytning serveri (`/api/chat`) orqali o'tadi. Shu sababli
/// maxfiy API kaliti faqat serverda turadi, ilovada yoki repozitoriyda
/// hech qachon bo'lmaydi.
class AssistantService {
  AssistantService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration timeout = Duration(seconds: 30);

  /// Serverga yuboriladigan eng ko'p xabar — kontekst juda uzayib ketmasin.
  static const int maxHistory = 20;

  static Uri get endpoint => Uri.https(Brand.apiHost, Brand.chatPath);

  /// Suhbat tarixini yuborib, yordamchidan keyingi javobni oladi.
  Future<AskResult> ask(List<ChatMessage> history) async {
    final usable = history
        .where((m) => !m.failed && m.text.trim().isNotEmpty)
        .toList();
    if (usable.isEmpty || usable.last.role != ChatRole.user) {
      return const AskResult(AskOutcome.failed, message: 'Savolingizni yozing');
    }

    final trimmed = usable.length > maxHistory
        ? usable.sublist(usable.length - maxHistory)
        : usable;
    final payload = jsonEncode(<String, dynamic>{
      'messages': trimmed.map((m) => m.toWire()).toList(),
      'source': Brand.source,
    });

    try {
      final response = await _client
          .post(
            endpoint,
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: payload,
          )
          .timeout(timeout);

      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        final reply = _extractReply(response.body);
        if (reply == null || reply.isEmpty) {
          return const AskResult(
            AskOutcome.failed,
            message: 'Yordamchi javob bermadi — qayta urinib ko‘ring',
          );
        }
        return AskResult(AskOutcome.ok, reply: reply);
      }
      if (code == 429) {
        return AskResult(
          AskOutcome.busy,
          message: _serverMessage(response.body),
        );
      }
      if (code >= 500) {
        return AskResult(
          AskOutcome.offline,
          message: 'Server javob bermadi ($code) — qayta urinib ko‘ring',
        );
      }
      return AskResult(
        AskOutcome.failed,
        message: _serverMessage(response.body),
      );
    } on TimeoutException {
      return const AskResult(
        AskOutcome.offline,
        message: 'Yordamchi uzoq javob bermadi — qayta urinib ko‘ring',
      );
    } on SocketException {
      return const AskResult(AskOutcome.offline);
    } on http.ClientException {
      return const AskResult(AskOutcome.offline);
    } catch (error) {
      debugPrint('AI yordamchi xatosi: $error');
      return const AskResult(AskOutcome.offline);
    }
  }

  /// Server javobidan `reply` matnini oladi.
  static String? _extractReply(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final reply = decoded['reply'] ?? decoded['text'] ?? decoded['answer'];
        if (reply is String) return reply.trim();
      }
    } catch (_) {
      // JSON bo'lmasa — matnning o'zi javob deb qabul qilinadi.
      return body.trim();
    }
    return null;
  }

  static String? _serverMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final key in const <String>['error', 'message', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }
    } catch (_) {
      // e'tiborsiz — umumiy xabar ishlatiladi.
    }
    return null;
  }

  void dispose() => _client.close();
}
