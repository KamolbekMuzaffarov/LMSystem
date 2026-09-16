import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/app.dart';
import 'package:xona_olchov/core/geometry.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/data/sketch_store.dart';
import 'package:xona_olchov/models/ceiling.dart';
import 'package:xona_olchov/models/lead.dart';
import 'package:xona_olchov/models/room_sketch.dart';
import 'package:xona_olchov/screens/potolok/potolok_parts.dart';
import 'package:xona_olchov/screens/potolok/potolok_screen.dart';
import 'package:xona_olchov/services/lead_sender.dart';
import 'package:xona_olchov/services/lead_service.dart';
import 'package:xona_olchov/theme/app_theme.dart';
import 'package:xona_olchov/widgets/ceiling_preview.dart';

RoomSketch room(String name, {double length = 5, double width = 4}) {
  final built = ShapePresets.rectangle(length: length, width: width);
  final now = DateTime(2026, 9, 14, 10);
  return RoomSketch(
    id: name,
    name: name,
    kind: RoomKind.rectangle,
    walls: built.walls,
    startHeading: built.startHeading,
    createdAt: now,
    updatedAt: now,
  );
}

MockClient okClient() => MockClient((_) async => http.Response('{}', 200));

MockClient offlineClient() =>
    MockClient((_) async => throw const SocketException('yo‘q'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<PotolokStore> pumpSection(
    WidgetTester tester, {
    MockClient? client,
    List<RoomSketch> sketches = const <RoomSketch>[],
    bool online = true,
    Size size = const Size(760, 3600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final potolok = await PotolokStore.open();
    final sketchStore = await SketchStore.openWith(sketches);
    final sender = LeadSender(
      store: potolok,
      service: LeadService(client: client ?? okClient()),
      isOnline: () async => online,
    );

    await tester.pumpWidget(
      SketchScope(
        store: sketchStore,
        child: PotolokScope(
          store: potolok,
          child: MaterialApp(
            theme: AppTheme.build(),
            home: PotolokScreen(sender: sender),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return potolok;
  }

  Future<void> fillForm(WidgetTester tester, {required String phone}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Ismingiz'), 'Kamol');
    await tester.enterText(
      find.widgetWithText(TextField, 'Telefon raqamingiz'),
      phone,
    );
    await tester.pump();
    await tester.tap(find.text('Arizani yuborish'));
    await tester.pumpAndSettle();
  }

  testWidgets('pastdagi menyudan potolok bo‘limi ochiladi', (tester) async {
    tester.view.physicalSize = const Size(760, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await SketchStore.open();
    final potolok = await PotolokStore.open();
    await tester.pumpWidget(XonaOlchovApp(store: store, potolok: potolok));
    await tester.pumpAndSettle();

    // Avval chizmalar bo'limi.
    expect(find.text('Hali chizma yo‘q'), findsOneWidget);
    expect(find.text('НАТЯЖНОЙ ПОТОЛОК'), findsNothing);

    await tester.tap(find.text('Potolok'));
    await tester.pumpAndSettle();

    expect(find.text('НАТЯЖНОЙ ПОТОЛОК'), findsOneWidget);
    expect(find.text('15 yil kafolat'), findsOneWidget);
    expect(find.byType(CeilingPreview), findsNWidgets(6));

    // Qaytib kelganda chizmalar bo'limi joyida turadi.
    await tester.tap(find.text('Chizmalar'));
    await tester.pumpAndSettle();
    expect(find.text('Hali chizma yo‘q'), findsOneWidget);
  });

  testWidgets('yuza kiritilsa narx chiqadi', (tester) async {
    await pumpSection(tester);

    expect(find.textContaining('Xona yuzasini kiriting'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Xona yuzasi'), '20');
    await tester.pumpAndSettle();

    expect(find.text('120\$ dan'), findsOneWidget);
    expect(find.text('≈ 1 512 000 so‘m'), findsOneWidget);
    expect(find.text('20.00 m² · 6\$/m²'), findsOneWidget);
  });

  testWidgets('narx faqat eng past darajada ko‘rsatiladi', (tester) async {
    await pumpSection(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Xona yuzasi'), '20');
    await tester.pumpAndSettle();

    // Premium narx (10$/m² va undan yuqorisi) hech qayerda chiqmasin.
    for (final hidden in <String>['10\$/m²', '12\$/m²', '200\$ dan']) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    // Har bir yo'l qo'ng'iroqqa olib boradi, aniq summa esa o'lchovdan keyin.
    expect(find.text('Qo‘ng‘iroq qilish'), findsOneWidget);
    expect(find.textContaining('Aniq summa o‘lchovdan keyin'), findsOneWidget);
  });

  testWidgets('saqlangan chizmadan yuza olinadi', (tester) async {
    await pumpSection(tester, sketches: <RoomSketch>[room('Zal')]);

    await tester.tap(find.text('Chizmadan'));
    await tester.pumpAndSettle();

    expect(find.text('Qaysi xona?'), findsOneWidget);
    await tester.tap(find.text('Zal'));
    await tester.pumpAndSettle();

    expect(find.text('120\$ dan'), findsOneWidget);
  });

  testWidgets('chizma yo‘q bo‘lsa tanlash oynasi tushuntiradi', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Chizmadan'));
    await tester.pumpAndSettle();
    expect(find.text('Chizma yo‘q'), findsOneWidget);
  });

  testWidgets('ariza yuboriladi va tarixda qoladi', (tester) async {
    final store = await pumpSection(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Xona yuzasi'), '20');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Glyanets'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bepul o‘lchovga yozilish'));
    await tester.pumpAndSettle();
    expect(find.text('20.00 m²'), findsOneWidget, reason: 'yuza ko‘chadi');
    expect(find.text('Glyanets'), findsWidgets);

    await fillForm(tester, phone: '93 985 61 02');

    expect(find.text('Ariza qabul qilindi'), findsOneWidget);
    final lead = store.leads.single;
    expect(lead.name, 'Kamol');
    expect(lead.phone, '+998939856102');
    expect(lead.area, closeTo(20, 1e-9));
    expect(lead.design, CeilingDesign.glossy);
    expect(lead.status, LeadStatus.sent);
  });

  testWidgets('noto‘g‘ri raqam yuborilmaydi', (tester) async {
    final store = await pumpSection(tester);

    await tester.tap(find.text('Bepul o‘lchovga yozilish'));
    await tester.pumpAndSettle();
    await fillForm(tester, phone: '123');

    expect(find.text('Raqamni to‘liq kiriting'), findsOneWidget);
    expect(store.count, 0);
  });

  testWidgets('internet yo‘q bo‘lsa ariza navbatda ko‘rinadi', (tester) async {
    final store = await pumpSection(
      tester,
      client: offlineClient(),
      online: false,
    );

    await tester.tap(find.text('Bepul o‘lchovga yozilish'));
    await tester.pumpAndSettle();
    await fillForm(tester, phone: '+998939856102');

    // Yetkazilmagan ariza «qabul qilindi» deb aytilmaydi.
    expect(find.text('Ariza saqlandi'), findsOneWidget);
    expect(find.text('Ariza qabul qilindi'), findsNothing);
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();

    expect(store.pendingCount, 1);
    expect(find.textContaining('1 ta ariza hali yuborilmagan'), findsOneWidget);
  });

  testWidgets('arizalar ekranida holat ko‘rinadi', (tester) async {
    await pumpSection(tester, client: offlineClient(), online: false);

    await tester.tap(find.text('Bepul o‘lchovga yozilish'));
    await tester.pumpAndSettle();
    await fillForm(tester, phone: '+998939856102');
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Arizalarim'));
    await tester.pumpAndSettle();

    expect(find.text('Arizalarim'), findsOneWidget);
    expect(find.text('Navbatda'), findsOneWidget);
    expect(find.text('+998 93 985 61 02'), findsOneWidget);
  });

  testWidgets('telefon raqami saqlanadi va tekshiriladi', (tester) async {
    final store = await pumpSection(tester);

    expect(find.text('Telefon raqami kiritilmagan'), findsOneWidget);
    await tester.tap(find.byTooltip('Telefon raqamini o‘zgartirish'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(store.contactPhone, isNull);
    expect(find.textContaining('Raqam noto‘g‘ri'), findsOneWidget);

    await tester.tap(find.byTooltip('Telefon raqamini o‘zgartirish'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '93 985 61 02');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(store.contactPhone, '+998939856102');
    expect(find.text('+998 93 985 61 02'), findsOneWidget);
  });

  testWidgets('juda katta yuza ogohlantiradi, narx bermaydi', (tester) async {
    await pumpSection(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Xona yuzasi'),
      '99999',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('10000 m² dan kichik'), findsOneWidget);
    expect(find.byType(QuoteBox), findsNothing, reason: 'narx berilmasin');
  });

  testWidgets('savol-javob ochiladi', (tester) async {
    await pumpSection(tester);
    expect(find.text('O‘lchov pulli emasmi?'), findsOneWidget);
    await tester.tap(find.text('O‘lchov pulli emasmi?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('O‘lchov va maslahat bepul'), findsOneWidget);
  });
}
