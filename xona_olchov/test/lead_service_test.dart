import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/core/brand.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/models/ceiling.dart';
import 'package:xona_olchov/models/lead.dart';
import 'package:xona_olchov/services/lead_sender.dart';
import 'package:xona_olchov/services/lead_service.dart';

Lead sample({String id = 'l1', String name = 'Kamol'}) => Lead(
  id: id,
  name: name,
  phone: '+998939856102',
  area: 20,
  design: CeilingDesign.glossy,
  createdAt: DateTime(2026, 9, 14, 10, 30),
);

/// Har bir so'rovni yozib boradigan soxta mijoz.
class Recorder {
  final List<http.Request> requests = <http.Request>[];

  MockClient client(
    FutureOr<http.Response> Function(http.Request request) handler,
  ) {
    return MockClient((request) async {
      requests.add(request);
      return handler(request);
    });
  }

  Map<String, dynamic> get lastBody =>
      jsonDecode(requests.last.body) as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('LeadService', () {
    test('manzil sayt bilan bir xil', () {
      expect(LeadService.endpoint.scheme, 'https');
      expect(LeadService.endpoint.host, Brand.apiHost);
      expect(LeadService.endpoint.path, Brand.leadPath);
    });

    test('200 — yuborildi va tana to‘g‘ri', () async {
      final recorder = Recorder();
      final service = LeadService(
        client: recorder.client((_) => http.Response('{"ok":true}', 200)),
      );
      final result = await service.send(sample());
      expect(result.isSent, isTrue);
      expect(recorder.requests.single.url, LeadService.endpoint);

      final body = recorder.lastBody;
      expect(body['name'], 'Kamol');
      expect(body['phone'], '+998939856102');
      expect(body['area'], 20);
      expect(body['source'], Brand.source);
      expect(body['website'], '');
      expect(
        recorder.requests.single.headers['Content-Type'],
        contains('application/json'),
      );
    });

    test('201 ham qabul qilinadi', () async {
      final service = LeadService(
        client: MockClient((_) async => http.Response('', 201)),
      );
      expect((await service.send(sample())).isSent, isTrue);
    });

    test('400 — rad etildi, server matni ko‘rsatiladi', () async {
      final service = LeadService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, String>{'message': 'Telefon xato'}),
            400,
          ),
        ),
      );
      final result = await service.send(sample());
      expect(result.outcome, SendOutcome.rejected);
      expect(result.userMessage, 'Telefon xato');
      expect(result.outcome.canRetry, isFalse);
    });

    test('429 va 500 — keyin qayta urinamiz', () async {
      for (final code in <int>[408, 429, 500, 503]) {
        final service = LeadService(
          client: MockClient((_) async => http.Response('', code)),
        );
        final result = await service.send(sample());
        expect(result.outcome, SendOutcome.offline, reason: '$code');
        expect(result.outcome.canRetry, isTrue, reason: '$code');
      }
    });

    test('internet yo‘q — ariza yo‘qolmaydi', () async {
      for (final error in <Object>[
        const SocketException('yo‘q'),
        TimeoutException('kech'),
        http.ClientException('uzildi'),
        StateError('kutilmagan'),
      ]) {
        final service = LeadService(
          client: MockClient((_) async => throw error),
        );
        final result = await service.send(sample());
        expect(result.outcome, SendOutcome.offline, reason: '$error');
      }
    });

    test('bo‘sh ariza serverga umuman bormaydi', () async {
      final recorder = Recorder();
      final service = LeadService(
        client: recorder.client((_) => http.Response('', 200)),
      );
      final result = await service.send(sample(name: 'A'));
      expect(result.outcome, SendOutcome.rejected);
      expect(recorder.requests, isEmpty);
    });
  });

  group('LeadSender', () {
    Future<(PotolokStore, LeadSender)> build({
      required MockClient client,
      bool online = true,
    }) async {
      final store = await PotolokStore.open();
      return (
        store,
        LeadSender(
          store: store,
          service: LeadService(client: client),
          isOnline: () async => online,
        ),
      );
    }

    test('ariza avval saqlanadi, keyin yuboriladi', () async {
      final (store, sender) = await build(
        client: MockClient((_) async => http.Response('', 200)),
      );
      final result = await sender.submit(
        name: '  Kamol  ',
        phone: '93 985 61 02',
        area: 20,
        design: CeilingDesign.matte,
        address: '  ',
        comment: ' shosh ',
      );

      expect(result.isSent, isTrue);
      expect(store.count, 1);
      final lead = store.leads.single;
      expect(lead.name, 'Kamol', reason: 'ortiqcha bo‘shliq olib tashlanadi');
      expect(lead.phone, '+998939856102');
      expect(lead.address, isNull, reason: 'bo‘sh manzil saqlanmaydi');
      expect(lead.comment, 'shosh');
      expect(lead.status, LeadStatus.sent);
      expect(lead.sentAt, isNotNull);
      expect(store.pendingCount, 0);
    });

    test('internet yo‘q bo‘lsa ariza navbatda qoladi', () async {
      final (store, sender) = await build(
        client: MockClient((_) async => throw const SocketException('yo‘q')),
      );
      final result = await sender.submit(name: 'Kamol', phone: '+998939856102');

      expect(result.outcome, SendOutcome.offline);
      expect(store.count, 1, reason: 'ariza yo‘qolmaydi');
      expect(store.pendingCount, 1);
      expect(store.leads.single.attempts, 1);
      expect(store.leads.single.error, isNotNull);
    });

    test('ulanish tiklansa navbat yuboriladi', () async {
      var online = false;
      final store = await PotolokStore.open();
      var fail = true;
      final sender = LeadSender(
        store: store,
        service: LeadService(
          client: MockClient((_) async {
            if (fail) throw const SocketException('yo‘q');
            return http.Response('', 200);
          }),
        ),
        isOnline: () async => online,
      );

      await sender.submit(name: 'Kamol', phone: '+998939856102');
      await sender.submit(name: 'Vali', phone: '+998901234567');
      expect(store.pendingCount, 2);

      // Hali internet yo'q — navbat tegilmaydi.
      expect(await sender.flushPending(), 0);
      expect(store.pendingCount, 2);

      online = true;
      fail = false;
      expect(await sender.flushPending(), 2);
      expect(store.pendingCount, 0);
      expect(
        store.leads.every((lead) => lead.status == LeadStatus.sent),
        isTrue,
      );
    });

    test('yuborish yarim yo‘lda uzilsa qolgani navbatda qoladi', () async {
      var sent = 0;
      final store = await PotolokStore.open();
      final sender = LeadSender(
        store: store,
        service: LeadService(
          client: MockClient((_) async {
            sent++;
            if (sent > 1) throw const SocketException('yo‘q');
            return http.Response('', 200);
          }),
        ),
        isOnline: () async => true,
      );

      await store.add(sample(id: 'a'));
      await store.add(sample(id: 'b'));
      await store.add(sample(id: 'c'));

      expect(await sender.flushPending(), 1);
      expect(store.pendingCount, 2);
      expect(sent, 2, reason: 'uzilgandan keyin urinish to‘xtaydi');
    });

    test('server rad etgan ariza qayta yuborilmaydi', () async {
      final (store, sender) = await build(
        client: MockClient((_) async => http.Response('', 422)),
      );
      await sender.submit(name: 'Kamol', phone: '+998939856102');
      expect(store.leads.single.status, LeadStatus.rejected);
      expect(store.pendingCount, 0);
      expect(await sender.flushPending(), 0);
    });

    test('noto‘g‘ri ma‘lumot saqlanmaydi', () async {
      final recorder = Recorder();
      final store = await PotolokStore.open();
      final sender = LeadSender(
        store: store,
        service: LeadService(
          client: recorder.client((_) => http.Response('', 200)),
        ),
        isOnline: () async => true,
      );

      final result = await sender.submit(name: 'K', phone: '123');
      expect(result.outcome, SendOutcome.rejected);
      expect(store.count, 0, reason: 'yaroqsiz ariza xotiraga yozilmaydi');
      expect(recorder.requests, isEmpty);
    });

    test('cheksiz urinish yo‘q', () async {
      final store = await PotolokStore.open();
      final sender = LeadSender(
        store: store,
        service: LeadService(
          client: MockClient((_) async => throw const SocketException('yo‘q')),
        ),
        isOnline: () async => true,
      );
      await store.add(sample().copyWith(attempts: LeadSender.maxAttempts));
      expect(await sender.flushPending(), 0);
      expect(store.leads.single.attempts, LeadSender.maxAttempts);
    });
  });
}
