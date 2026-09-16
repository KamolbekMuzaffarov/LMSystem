import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/app.dart';
import 'package:xona_olchov/core/estimate.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/data/sketch_store.dart';
import 'package:xona_olchov/models/opening.dart';
import 'package:xona_olchov/screens/editor_parts.dart';
import 'package:xona_olchov/theme/app_theme.dart';
import 'package:xona_olchov/widgets/material_card.dart';
import 'package:xona_olchov/widgets/ui_bits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<SketchStore> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final store = await SketchStore.open();
    final potolok = await PotolokStore.open();
    await tester.pumpWidget(XonaOlchovApp(store: store, potolok: potolok));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openNew(WidgetTester tester) async {
    await tester.tap(find.text('Birinchi chizmani yaratish'));
    await tester.pumpAndSettle();
  }

  Future<void> fillRectangle(WidgetTester tester) async {
    await tester.tap(find.text('To‘rtburchak').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Uzunligi'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Kengligi'), '4');
    await tester.enterText(
      find.widgetWithText(TextField, 'Xona balandligi (ixtiyoriy)'),
      '2.8',
    );
    await tester.pump();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('eshik qo‘shilsa devor yuzasi kamayadi va saqlanadi', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openNew(tester);
    await fillRectangle(tester);

    // 18 × 2.8 = 50.40 m² — hali eshiksiz.
    expect(find.text('50.40 m²'), findsOneWidget);

    await scrollTo(tester, find.text('Eshik qo‘shish'));
    await tester.tap(find.text('Eshik qo‘shish'));
    await tester.pumpAndSettle();

    // Standart eshik 0.80 × 2.05 = 1.64 m² → 48.76 m².
    expect(find.text('48.76 m²'), findsOneWidget);
    expect(find.text('Devorlar (sof)'), findsOneWidget);
    expect(find.text('1.64 m²'), findsOneWidget);

    // Sonini 2 ga oshiramiz.
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    expect(find.text('47.12 m²'), findsOneWidget);

    await scrollTo(tester, find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    final saved = store.sketches.single;
    expect(saved.openings.length, 1);
    expect(saved.openings.first.kind, OpeningKind.door);
    expect(saved.openings.first.count, 2);
    expect(saved.estimate.wallArea, closeTo(47.12, 1e-9));
    expect(saved.estimate.skirtingLength, closeTo(16.4, 1e-9));

    // Batafsil ekranda ro'yxat ko'rinadi.
    await tester.tap(find.text(saved.displayName));
    await tester.pumpAndSettle();
    expect(find.text('Eshik × 2'), findsOneWidget);
    expect(find.text('Plintus (eshiksiz)'), findsOneWidget);
    expect(find.text('16.40 m'), findsOneWidget);
  });

  testWidgets('oraliqdan tashqari balandlik ogohlantiradi va saqlanmaydi', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openNew(tester);
    await fillRectangle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Xona balandligi (ixtiyoriy)'),
      '45',
    );
    await tester.pump();

    expect(find.textContaining('bu qiymat saqlanmaydi'), findsOneWidget);
    expect(find.text('Hajmi'), findsNothing);

    await scrollTo(tester, find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();
    expect(store.sketches.single.height, isNull);
  });

  testWidgets('o‘lcham maydoni manfiy son va ikki nuqtani o‘tkazmaydi', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: MeasureField(controller: controller, label: 'Uzunligi'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '-5');
    expect(controller.text, '5');

    await tester.enterText(find.byType(TextField), '3,17');
    expect(controller.text, '3,17');

    await tester.enterText(find.byType(TextField), '1.2.3');
    expect(controller.text, '3,17', reason: 'ikkinchi nuqta rad etiladi');
  });

  test('burilish burchagi ±180° ichida ushlanadi', () {
    expect(TurnSelector.clamp(5000), 179.9);
    expect(TurnSelector.clamp(-400), -179.9);
    expect(TurnSelector.clamp(90), 90);
    expect(TurnSelector.clamp(double.nan), 0);
  });

  testWidgets('balandlik olib tashlansa material kartasi polga qaytadi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Widget build(RoomEstimate estimate) => MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(
        body: ListView(children: <Widget>[MaterialCard(estimate: estimate)]),
      ),
    );

    await tester.pumpWidget(
      build(const RoomEstimate(floorArea: 20, perimeter: 18, height: 2.8)),
    );
    await tester.tap(find.text('Devorlar').last);
    await tester.pumpAndSettle();
    // "Kerakli miqdor" endi devor yuzasi.
    expect(find.text('50.40 m²'), findsNWidgets(2));

    // Xuddi shu karta, balandliksiz hisob bilan qayta quriladi.
    await tester.pumpWidget(
      build(const RoomEstimate(floorArea: 20, perimeter: 18)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('0.00 m²'),
      findsNothing,
      reason: 'eskirgan "Devorlar" tanlovi 0 ko‘rsatmasin',
    );
    expect(find.text('20.00 m²'), findsNWidgets(2));
  });

  testWidgets('narx kiritilsa umumiy summa chiqadi', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: MaterialCard(
              estimate: RoomEstimate(floorArea: 20, perimeter: 18),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, '1 m² narxi'),
      '85000',
    );
    await tester.pump();
    expect(find.text('1 700 000'), findsOneWidget);
  });
}
