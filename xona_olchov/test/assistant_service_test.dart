import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xona_olchov/core/brand.dart';
import 'package:xona_olchov/models/chat_message.dart';
import 'package:xona_olchov/services/assistant_service.dart';

List<ChatMessage> ask(String text) => <ChatMessage>[ChatMessage.user(text)];

void main() {
  test('manzil sayt bilan bir xil', () {
    expect(AssistantService.endpoint.scheme, 'https');
    expect(AssistantService.endpoint.host, Brand.apiHost);
    expect(AssistantService.endpoint.path, Brand.chatPath);
  });

  test('200 — javob keladi va so‘rov tanasi to‘g‘ri', () async {
    late http.Request seen;
    final service = AssistantService(
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode(<String, String>{'reply': 'Narx 6\$/m² dan'}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.ask(<ChatMessage>[
      const ChatMessage.assistant('Salom!'),
      const ChatMessage.user('Narxi qancha?'),
    ]);

    expect(result.isOk, isTrue);
    expect(result.reply, 'Narx 6\$/m² dan');

    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    final messages = body['messages'] as List<dynamic>;
    expect(messages.length, 2);
    expect(messages.first, <String, String>{
      'role': 'assistant',
      'content': 'Salom!',
    });
    expect(messages.last, <String, String>{
      'role': 'user',
      'content': 'Narxi qancha?',
    });
    expect(body['source'], Brand.source);
  });

  test('bo‘sh javob xatolik sifatida qaytadi', () async {
    final service = AssistantService(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode(<String, String>{'reply': ''}), 200),
      ),
    );
    final result = await service.ask(ask('Salom'));
    expect(result.outcome, AskOutcome.failed);
    expect(result.isOk, isFalse);
  });

  test('oxirgi xabar user bo‘lmasa so‘rov yuborilmaydi', () async {
    var called = false;
    final service = AssistantService(
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );
    final result = await service.ask(<ChatMessage>[
      const ChatMessage.assistant('Salom'),
    ]);
    expect(result.outcome, AskOutcome.failed);
    expect(called, isFalse);
  });

  test('xatolik pufagi va bo‘sh matn yuborilmaydi', () async {
    late http.Request seen;
    final service = AssistantService(
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode(<String, String>{'reply': 'ha'}), 200);
      }),
    );
    await service.ask(<ChatMessage>[
      const ChatMessage.user('birinchi'),
      const ChatMessage.error('Internet yo‘q'),
      const ChatMessage.user('   '),
      const ChatMessage.user('ikkinchi'),
    ]);
    final messages =
        (jsonDecode(seen.body) as Map<String, dynamic>)['messages']
            as List<dynamic>;
    expect(messages.length, 2, reason: 'xatolik va bo‘sh xabar tashlanadi');
    expect((messages.last as Map)['content'], 'ikkinchi');
  });

  test('tarix oxirgi 20 xabargacha qisqaradi', () async {
    late http.Request seen;
    final service = AssistantService(
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode(<String, String>{'reply': 'ok'}), 200);
      }),
    );
    final history = <ChatMessage>[
      for (var i = 0; i < 25; i++) ChatMessage.user('savol $i'),
    ];
    await service.ask(history);
    final messages =
        (jsonDecode(seen.body) as Map<String, dynamic>)['messages']
            as List<dynamic>;
    expect(messages.length, AssistantService.maxHistory);
    expect((messages.last as Map)['content'], 'savol 24');
  });

  test('429 — band, qayta urinsa bo‘ladi', () async {
    final service = AssistantService(
      client: MockClient((_) async => http.Response('', 429)),
    );
    final result = await service.ask(ask('Salom'));
    expect(result.outcome, AskOutcome.busy);
    expect(result.outcome.canRetry, isTrue);
  });

  test('5xx — offline, qayta urinsa bo‘ladi', () async {
    for (final code in <int>[500, 502, 503]) {
      final service = AssistantService(
        client: MockClient((_) async => http.Response('', code)),
      );
      final result = await service.ask(ask('Salom'));
      expect(result.outcome, AskOutcome.offline, reason: '$code');
      expect(result.outcome.canRetry, isTrue);
    }
  });

  test('400 — server matni bilan, qayta urinilmaydi', () async {
    final service = AssistantService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, String>{'error': 'messages kerak'}),
          400,
        ),
      ),
    );
    final result = await service.ask(ask('Salom'));
    expect(result.outcome, AskOutcome.failed);
    expect(result.errorText, 'messages kerak');
    expect(result.outcome.canRetry, isFalse);
  });

  test('internet yo‘q — offline', () async {
    for (final error in <Object>[
      const SocketException('yo‘q'),
      TimeoutException('kech'),
      http.ClientException('uzildi'),
      StateError('kutilmagan'),
    ]) {
      final service = AssistantService(
        client: MockClient((_) async => throw error),
      );
      final result = await service.ask(ask('Salom'));
      expect(result.outcome, AskOutcome.offline, reason: '$error');
    }
  });

  test('JSON bo‘lmagan javob ham matn sifatida qabul qilinadi', () async {
    final service = AssistantService(
      client: MockClient((_) async => http.Response('Oddiy matn javob', 200)),
    );
    final result = await service.ask(ask('Salom'));
    expect(result.isOk, isTrue);
    expect(result.reply, 'Oddiy matn javob');
  });
}
