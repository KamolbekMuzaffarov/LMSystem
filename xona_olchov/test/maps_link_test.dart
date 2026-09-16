import 'package:flutter_test/flutter_test.dart';
import 'package:xona_olchov/models/geo_point.dart';
import 'package:xona_olchov/services/maps_link.dart';

void main() {
  const lat = 41.311081;
  const lng = 69.240562;

  void expectPoint(GeoPoint? point) {
    expect(point, isNotNull);
    expect(point!.latitude, closeTo(lat, 0.0001));
    expect(point.longitude, closeTo(lng, 0.0001));
  }

  group('Google Maps havolalari', () {
    test('/maps/@lat,lng,zoom', () {
      expectPoint(
        MapsLink.parse('https://www.google.com/maps/@41.311081,69.240562,17z'),
      );
    });

    test('joy nomi bilan havola', () {
      expectPoint(
        MapsLink.parse(
          'https://www.google.com/maps/place/Toshkent/@41.311081,69.240562,15z/data=!3m1',
        ),
      );
    });

    test('?q= parametri', () {
      expectPoint(
        MapsLink.parse('https://maps.google.com/?q=41.311081,69.240562'),
      );
    });

    test('search API havolasi', () {
      expectPoint(
        MapsLink.parse(
          'https://www.google.com/maps/search/?api=1&query=41.311081,69.240562',
        ),
      );
    });

    test('data ichidagi !3d!4d', () {
      expectPoint(
        MapsLink.parse(
          'https://www.google.com/maps/place/X/data=!4m2!3m1!3d41.311081!4d69.240562',
        ),
      );
    });

    test('geo: havolasi', () {
      expectPoint(MapsLink.parse('geo:41.311081,69.240562'));
    });

    test('qisqartirilgan havola aniqlanadi', () {
      expect(MapsLink.isShortLink('https://maps.app.goo.gl/abc123'), isTrue);
      expect(MapsLink.isShortLink('https://www.google.com/maps/@1,2'), isFalse);
    });
  });

  group('Koordinata matni', () {
    test('nuqtali o‘nlik', () {
      expectPoint(MapsLink.parse('41.311081, 69.240562'));
    });

    test('vergulli o‘nlik (bo‘shliq bilan ajratilgan)', () {
      expectPoint(MapsLink.parse('41,311081 69,240562'));
    });

    test('manfiy koordinatalar', () {
      final point = MapsLink.parse('-33.865143, 151.209900');
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-33.865143, 0.0001));
      expect(point.longitude, closeTo(151.2099, 0.0001));
    });

    test('daraja belgisi bilan', () {
      expectPoint(MapsLink.parse('41.311081°, 69.240562°'));
    });
  });

  group('Xato kiritish', () {
    test('bo‘sh matn', () {
      expect(MapsLink.parse(''), isNull);
      expect(MapsLink.parse('   '), isNull);
    });

    test('son yo‘q', () {
      expect(MapsLink.parse('Toshkent shahri'), isNull);
    });

    test('diapazondan chiqqan qiymatlar rad etiladi', () {
      expect(MapsLink.parse('120.5, 69.2'), isNull);
      expect(MapsLink.parse('41.3, 200.1'), isNull);
    });
  });
}
