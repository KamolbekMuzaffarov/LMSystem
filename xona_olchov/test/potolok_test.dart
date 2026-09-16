import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/core/brand.dart';
import 'package:xona_olchov/core/formatters.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/models/ceiling.dart';
import 'package:xona_olchov/models/lead.dart';

Lead lead(String id, {LeadStatus status = LeadStatus.pending}) => Lead(
      id: id,
      name: 'Kamol',
      phone: '+998939856102',
      createdAt: DateTime(2026, 9, 14, 10, int.parse(id)),
      status: status,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Narx hisobi', () {
    test('20 m² → 120\$ ≈ 1 512 000 so‘m', () {
      const quote = CeilingQuote(area: 20);
      expect(quote.usdPerSquare, 6);
      expect(quote.usd, closeTo(120, 1e-9));
      expect(quote.roundedUsd, 120);
      expect(quote.som, closeTo(1512000, 1e-6));
      expect(Fmt.money(quote.roundedSom), '1 512 000');
    });

    test('so‘m ming so‘mgacha yuqoriga yaxlitlanadi', () {
      const quote = CeilingQuote(area: 17.38);
      expect(quote.roundedUsd, 105, reason: '104.28 → 105');
      expect(quote.roundedSom % 1000, 0);
      expect(quote.roundedSom, greaterThanOrEqualTo(quote.som));
    });

    test('yaroqsiz yuza narx bermaydi', () {
      for (final area in <double>[0, -5, double.nan, double.infinity, 20000]) {
        final quote = CeilingQuote(area: area);
        expect(quote.isValid, isFalse, reason: '$area');
        expect(quote.usd, 0);
        expect(quote.roundedSom, 0);
      }
    });

    test('kurs oralig‘i tekshiriladi', () {
      expect(CeilingPrice.normalizeRate(13500), 13500);
      expect(CeilingPrice.normalizeRate(null), CeilingPrice.defaultSomPerUsd);
      expect(CeilingPrice.normalizeRate(5), CeilingPrice.defaultSomPerUsd);
      expect(
        CeilingPrice.normalizeRate(double.nan),
        CeilingPrice.defaultSomPerUsd,
      );
      expect(const CeilingQuote(area: 10, somPerUsd: 0).som, closeTo(756000, 1e-6));
    });

    test('e‘lon qilinadigan narx faqat eng past daraja', () {
      // Premium narxlar (10\$ va undan yuqori) ilovada umuman ko'rsatilmaydi.
      expect(CeilingPrice.publicUsdPerSquare, 6);
      expect(const CeilingQuote(area: 50).usdPerSquare, 6);
      expect(CeilingQuote.fromWord, 'dan');
    });

    test('yuza xavfsiz oraliqqa keltiriladi', () {
      expect(CeilingQuote.clampArea(50), 50);
      expect(CeilingQuote.clampArea(99999), CeilingPrice.maxArea);
      expect(CeilingQuote.clampArea(-4), 0);
      expect(CeilingQuote.clampArea(double.nan), 0);
    });

    test('shift turlari nomi bo‘yicha topiladi', () {
      expect(CeilingDesign.byName('glossy'), CeilingDesign.glossy);
      expect(CeilingDesign.byName('yo‘q'), isNull);
      expect(CeilingDesign.byName(null), isNull);
      expect(CeilingDesign.values.length, 6);
    });
  });

  group('Telefon raqami', () {
    test('turli ko‘rinishlar bir xil raqamga keladi', () {
      const expected = '+998939856102';
      for (final raw in <String>[
        '+998939856102',
        '998 93 985 61 02',
        '93 985-61-02',
        '(93) 985 61 02',
        '8 93 985 61 02',
      ]) {
        expect(PhoneRules.normalize(raw), expected, reason: raw);
      }
    });

    test('noto‘g‘ri raqam rad etiladi', () {
      for (final raw in <String>[
        '',
        '123',
        '93 985 61 0',
        '+7 926 123 45 67',
        '11 985 61 02',
        'salom',
      ]) {
        expect(PhoneRules.normalize(raw), isNull, reason: raw);
        expect(PhoneRules.isValid(raw), isFalse, reason: raw);
      }
    });

    test('o‘qishga qulay ko‘rinish', () {
      expect(PhoneRules.pretty('+998939856102'), '+998 93 985 61 02');
      expect(PhoneRules.pretty('salom'), 'salom');
    });

    test('ism tekshiruvi', () {
      expect(NameRules.isValid('Ali'), isTrue);
      expect(NameRules.clean('  Ali   Vali '), 'Ali Vali');
      expect(NameRules.isValid('A'), isFalse);
      expect(NameRules.isValid('   '), isFalse);
      expect(NameRules.isValid('a' * 61), isFalse);
    });
  });

  group('Ariza', () {
    final sample = Lead(
      id: 'l1',
      name: 'Kamol',
      phone: '+998939856102',
      area: 24.456,
      design: CeilingDesign.glossy,
      address: 'Buxoro',
      comment: 'Ertaga qo‘ng‘iroq qiling',
      createdAt: DateTime(2026, 9, 14, 10, 30),
    );

    test('JSON orqali yo‘qolmaydi', () {
      final restored = Lead.fromJson(sample.toJson());
      expect(restored.id, sample.id);
      expect(restored.name, sample.name);
      expect(restored.phone, sample.phone);
      expect(restored.area, closeTo(24.456, 1e-9));
      expect(restored.design, CeilingDesign.glossy);
      expect(restored.address, 'Buxoro');
      expect(restored.comment, sample.comment);
      expect(restored.status, LeadStatus.pending);
    });

    test('buzilgan yozuv ham o‘qiladi', () {
      final restored = Lead.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'Ali',
        'phone': '+998901234567',
        'area': 'yo‘q',
        'design': 'boshqacha',
        'attempts': '3',
      });
      expect(restored.area, isNull);
      expect(restored.design, isNull);
      expect(restored.attempts, 3);
      expect(restored.status, LeadStatus.pending);
    });

    test('serverga yuboriladigan maydonlar', () {
      final payload = sample.toPayload();
      expect(payload['name'], 'Kamol');
      expect(payload['phone'], '+998939856102');
      expect(payload['area'], 24.46, reason: 'ikki xonagacha');
      expect(payload['design'], 'Glyanets');
      expect(payload['source'], Brand.source);
      expect(
        payload['website'],
        '',
        reason: 'honeypot maydoni har doim bo‘sh',
      );
      expect(payload.containsKey('status'), isFalse);
    });

    test('Telegram uchun matn', () {
      final text = sample.toMessage();
      expect(text, contains('Kamol'));
      expect(text, contains('+998 93 985 61 02'));
      expect(text, contains('24.46 m²'));
      expect(text, contains('Glyanets'));
      expect(text, contains('Buxoro'));
    });

    test('nusxa holatni yangilaydi, qolganini saqlaydi', () {
      final sent = sample.copyWith(
        status: LeadStatus.sent,
        sentAt: DateTime(2026, 9, 14, 11),
        attempts: 1,
        clearError: true,
      );
      expect(sent.status, LeadStatus.sent);
      expect(sent.attempts, 1);
      expect(sent.error, isNull);
      expect(sent.name, sample.name);
      expect(sent.area, sample.area);
    });
  });

  group('Potolok ombori', () {
    test('ariza qo‘shiladi va qayta o‘qiladi', () async {
      final store = await PotolokStore.open();
      await store.add(lead('1'));
      expect(store.count, 1);
      expect(store.pendingCount, 1);

      final reopened = await PotolokStore.open();
      expect(reopened.count, 1);
      expect(reopened.byId('1')?.name, 'Kamol');
    });

    test('holat yangilanadi, ariza tarixda qoladi', () async {
      final store = await PotolokStore.open();
      await store.add(lead('1'));
      await store.update(
        store.byId('1')!.copyWith(status: LeadStatus.sent),
      );
      expect(store.count, 1, reason: 'yangilash nusxa yaratmasin');
      expect(store.pendingCount, 0);
      expect(store.byId('1')?.status, LeadStatus.sent);
    });

    test('navbat eng eskisidan boshlanadi', () async {
      final store = await PotolokStore.openWith(<Lead>[
        lead('1'),
        lead('2'),
        lead('3', status: LeadStatus.sent),
      ]);
      expect(store.pending.map((item) => item.id), <String>['1', '2']);
    });

    test('sozlamalar saqlanadi', () async {
      final store = await PotolokStore.open();
      expect(store.contactPhone, isNull);
      expect(store.somPerUsd, CeilingPrice.defaultSomPerUsd);

      await store.setContactPhone('93 985 61 02');
      await store.setSomPerUsd(13200);
      expect(store.contactPhone, '+998939856102');
      expect(store.somPerUsd, 13200);

      final reopened = await PotolokStore.open();
      expect(reopened.contactPhone, '+998939856102');
      expect(reopened.somPerUsd, 13200);
    });

    test('noto‘g‘ri raqam saqlanmaydi', () async {
      final store = await PotolokStore.open();
      await store.setContactPhone('123');
      expect(store.contactPhone, isNull);
    });

    test('buzilgan yozuv ilovani to‘xtatmaydi', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PotolokStore.leadsKey: '{"items": [',
        PotolokStore.settingsKey: 'x',
      });
      final store = await PotolokStore.open();
      expect(store.count, 0);
      expect(store.somPerUsd, CeilingPrice.defaultSomPerUsd);
    });
  });
}
