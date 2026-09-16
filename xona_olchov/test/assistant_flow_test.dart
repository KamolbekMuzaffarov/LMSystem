import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xona_olchov/data/potolok_store.dart';
import 'package:xona_olchov/screens/potolok/assistant_screen.dart';
import 'package:xona_olchov/services/assistant_service.dart';
import 'package:xona_olchov/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> pump(WidgetTester tester, {required MockClient client}) async {
    tester.view.physicalSize = const Size(760, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await PotolokStore.open();
    await tester.pumpWidget(
      PotolokScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: AssistantScreen(service: AssistantService(client: client)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MockClient reply(String text) =>
      MockClient((_) async => http.Response('{"reply": "$text"}', 200));

  testWidgets('savol yuboriladi va javob ko‘rinadi', (tester) async {
    await pump(tester, client: reply('Narx 6\$/m² dan boshlanadi'));

    // Bo'sh holatda tayyor savollar turadi.
    expect(find.text('Savolingiz bormi?'), findsOneWidget);
    expect(find.text('Narxi qancha?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Salom');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Salom'), findsOneWidget);
    expect(find.text('Narx 6\$/m² dan boshlanadi'), findsOneWidget);
  });

  testWidgets('tayyor savol bosilsa yuboriladi', (tester) async {
    await pump(tester, client: reply('15 yil kafolat'));

    await tester.tap(find.text('Kafolat necha yil?'));
    await tester.pumpAndSettle();

    expect(find.text('Kafolat necha yil?'), findsOneWidget);
    expect(find.text('15 yil kafolat'), findsOneWidget);
  });

  testWidgets('internet yo‘q — xatolik va qayta urinish', (tester) async {
    var fail = true;
    await pump(
      tester,
      client: MockClient((_) async {
        if (fail) throw const SocketException('yo‘q');
        return http.Response('{"reply": "Mana javob"}', 200);
      }),
    );

    await tester.enterText(find.byType(TextField), 'Narxi?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.textContaining('Internet yo‘q'), findsOneWidget);
    expect(find.text('Qayta urinish'), findsOneWidget);

    // Ulanish tiklandi — qayta urinamiz.
    fail = false;
    await tester.tap(find.text('Qayta urinish'));
    await tester.pumpAndSettle();

    expect(find.text('Mana javob'), findsOneWidget);
    expect(find.text('Qayta urinish'), findsNothing);
    expect(find.text('Narxi?'), findsOneWidget, reason: 'savol tarixda qoladi');
  });

  testWidgets('javob kutilayotganda kiritish o‘chadi', (tester) async {
    // Javobni qo'lda ushlab turamiz — shunda «kutish» holatini tekshiramiz.
    final gate = Completer<http.Response>();
    await pump(tester, client: MockClient((_) => gate.future));

    await tester.enterText(find.byType(TextField), 'Salom');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // javob hali kelmagan

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(http.Response('{"reply": "Mana javob"}', 200));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(find.text('Mana javob'), findsOneWidget);
  });
}
