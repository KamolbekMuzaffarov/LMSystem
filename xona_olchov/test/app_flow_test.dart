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
    // Baland ekran — ListView ichidagi barcha bo'limlar qurilsin.
    tester.view.physicalSize = const Size(720, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final store = await SketchStore.open();
    final potolok = await PotolokStore.open();
    await tester.pumpWidget(XonaOlchovApp(store: store, potolok: potolok));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('bo‘sh holat ko‘rsatiladi', (tester) async {
    await pumpApp(tester);
    expect(find.text('Hali chizma yo‘q'), findsOneWidget);
    expect(find.text('Yangi chizma'), findsOneWidget);
  });

  testWidgets('trapetsiya chizmasi yaratiladi va saqlanadi', (tester) async {
    final store = await pumpApp(tester);

    await tester.tap(find.text('Birinchi chizmani yaratish'));
    await tester.pumpAndSettle();

    // Trapetsiya boshlang'ich rejim.
    expect(find.text('Trapetsiya'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, 'Uzunligi (ikki tomon orasidagi masofa)'),
      '17.38',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Chap tomoni'),
      '2.96',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'O‘ng tomoni'),
      '3.17',
    );
    await tester.pump();

    // Namunadagi natija: 53.27 m².
    expect(find.text('53.27 m²'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'Nomi'), 'Katta zal');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    expect(store.count, 1);
    expect(store.sketches.first.name, 'Katta zal');
    expect(store.sketches.first.area, closeTo(53.2697, 0.001));

    // Ro'yxatda ko'rinadi.
    expect(find.text('Katta zal'), findsOneWidget);
    expect(find.text('53.27 m²'), findsWidgets);
  });

  testWidgets('to‘rtburchak rejimida yuza hisoblanadi', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Birinchi chizmani yaratish'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('To‘rtburchak').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Uzunligi'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Kengligi'), '4');
    await tester.pump();

    expect(find.text('20.00 m²'), findsWidgets);
    expect(find.text('Perimetr: 18.00 m'), findsOneWidget);
  });

  testWidgets('chizmani o‘chirish imkoniyati yo‘q', (tester) async {
    final store = await pumpApp(tester);
    await tester.tap(find.text('Birinchi chizmani yaratish'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Uzunligi (ikki tomon orasidagi masofa)'),
      '10',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Chap tomoni'), '3');
    await tester.enterText(find.widgetWithText(TextField, 'O‘ng tomoni'), '3');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    expect(store.count, 1);
    // Snackbar (o‘zi Dismissible) yo‘qolguncha kutamiz.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Ro'yxatda: o'chirish jestlari ham, tugmalari ham yo'q.
    expect(find.byType(Dismissible), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.textContaining('chir'), findsNothing);

    // Batafsil ekranda ham.
    await tester.tap(find.text('Xona 1'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.textContaining('o‘chirilmaydi'), findsOneWidget);
  });

  testWidgets('ko‘p burchakli xona: L-shakl shabloni', (tester) async {
    final store = await pumpApp(tester);

    await tester.tap(find.text('Birinchi chizmani yaratish'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘p burchakli').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('L-shakl'));
    await tester.pumpAndSettle();

    // 6 devorli L-shakl: 27 m².
    expect(find.text('27.00 m²'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();

    expect(store.count, 1);
    expect(store.sketches.first.geometry.vertices.length, 6);
    expect(store.sketches.first.area, closeTo(27, 0.001));
  });
}
