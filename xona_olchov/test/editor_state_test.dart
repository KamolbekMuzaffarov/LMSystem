import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/app.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/data/sketch_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<SketchStore> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 2400);
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

  bool canPop(WidgetTester tester) => tester
      .widget<PopScope<Object?>>(find.byKey(const Key('editor-pop-scope')))
      .canPop;

  Future<void> fillRectangle(WidgetTester tester) async {
    await tester.tap(find.text('To‘rtburchak').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Uzunligi'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Kengligi'), '4');
    await tester.pump();
  }

  testWidgets('maydonga tegish saqlanmagan o‘zgarish hisoblanmaydi', (
    tester,
  ) async {
    await pumpApp(tester);
    await openNew(tester);

    expect(canPop(tester), isTrue);

    // Faqat fokus: kursor o'zgaradi, matn o'zgarmaydi.
    await tester.tap(find.widgetWithText(TextField, 'Nomi'));
    await tester.pumpAndSettle();
    expect(canPop(tester), isTrue, reason: 'fokus dirty qilmasligi kerak');
  });

  testWidgets('nomni yozish saqlanmagan o‘zgarish sifatida belgilanadi', (
    tester,
  ) async {
    await pumpApp(tester);
    await openNew(tester);
    expect(canPop(tester), isTrue);

    await tester.enterText(find.widgetWithText(TextField, 'Nomi'), 'Zal');
    await tester.pump();
    expect(
      canPop(tester),
      isFalse,
      reason: 'matn yozildi — chiqishda so‘ralsin',
    );
  });

  testWidgets('tavsifni yozish ham belgilanadi', (tester) async {
    await pumpApp(tester);
    await openNew(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Tavsif'), 'Izoh');
    await tester.pump();
    expect(canPop(tester), isFalse);
  });

  testWidgets('burilish saqlanadi va qayta ochilganda yo‘qolmaydi', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openNew(tester);
    await fillRectangle(tester);

    // Bir marta buramiz.
    await tester.tap(find.byTooltip('Chizmani burish'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    expect(store.count, 1);
    final saved = store.sketches.first;
    expect(saved.startHeading, closeTo(90, 0.0001));
    expect(saved.presetInputs['rotation'], closeTo(90, 0.0001));

    // Tahrirlash uchun ochamiz va o'zgartirmasdan saqlaymiz.
    await tester.tap(find.text(saved.displayName));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tahrirlash'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    expect(store.count, 1, reason: 'nusxa yaratilmasin');
    expect(
      store.sketches.first.startHeading,
      closeTo(90, 0.0001),
      reason: 'burilish saqlanib qolishi kerak',
    );
  });

  testWidgets('balandlik kiritilsa devorlar yuzasi ko‘rinadi va saqlanadi', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openNew(tester);
    await fillRectangle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Xona balandligi (ixtiyoriy)'),
      '2.8',
    );
    await tester.pump();

    // Perimetr 18 × 2.8 = 50.40 m², hajm 20 × 2.8 = 56.00 m³
    expect(find.text('50.40 m²'), findsOneWidget);
    expect(find.text('56.00 m³'), findsOneWidget);

    // Zaxira tanlaymiz.
    await tester.tap(find.text('+10%'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    final saved = store.sketches.first;
    expect(saved.height, closeTo(2.8, 0.0001));
    expect(saved.reservePercent, 10);
    expect(saved.estimate.wallArea, closeTo(50.4, 0.0001));
  });
}
