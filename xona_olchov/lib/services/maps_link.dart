import '../models/geo_point.dart';

/// Google Maps havolasi yoki koordinata matnidan nuqtani ajratib oladi.
///
/// Qo'llab-quvvatlanadi:
///  * `41.311081, 69.240562` va `41,311081 69,240562`
///  * `https://www.google.com/maps/@41.311081,69.240562,17z`
///  * `https://maps.google.com/?q=41.311081,69.240562`
///  * `https://www.google.com/maps/search/?api=1&query=41.31,69.24`
///  * `geo:41.311081,69.240562`
///  * `.../data=...!3d41.311081!4d69.240562`
abstract final class MapsLink {
  static final List<RegExp> _patterns = <RegExp>[
    RegExp(r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    RegExp(r'[?&]query=(?:loc:)?(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    RegExp(r'[?&]q=(?:loc:)?(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    RegExp(r'[?&]ll=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    RegExp(r'[?&]center=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)'),
    RegExp(r'^geo:(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
  ];

  /// Qisqartirilgan havola — koordinatalar ichida yo'q.
  static bool isShortLink(String raw) {
    final text = raw.trim().toLowerCase();
    return text.contains('maps.app.goo.gl') || text.contains('goo.gl/maps');
  }

  static GeoPoint? parse(String raw, {LocationSource? source}) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    for (final pattern in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final point = _build(
        match.group(1),
        match.group(2),
        source ?? LocationSource.mapsLink,
      );
      if (point != null) return point;
    }

    return _parsePair(text, source ?? LocationSource.manual);
  }

  /// "41.31, 69.24" yoki "41,31 69,24" ko'rinishidagi juftlik.
  static GeoPoint? _parsePair(String text, LocationSource source) {
    final cleaned = text.replaceAll(RegExp(r'[()\[\]°]'), ' ').trim();

    // Avval bo'shliq/nuqtali vergul bo'yicha ajratamiz — bunda vergul
    // o'nlik ajratgich bo'lishi mumkin.
    final bySpace = cleaned
        .split(RegExp(r'[;\s]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (bySpace.length == 2) {
      final point = _build(bySpace[0], bySpace[1], source);
      if (point != null) return point;
    }

    final byComma = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (byComma.length == 2) {
      return _build(byComma[0], byComma[1], source);
    }

    return null;
  }

  static GeoPoint? _build(String? rawLat, String? rawLng, LocationSource source) {
    if (rawLat == null || rawLng == null) return null;
    final lat = double.tryParse(
      rawLat.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    final lng = double.tryParse(
      rawLng.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (lat == null || lng == null) return null;
    if (!GeoPoint.isValidLatitude(lat) || !GeoPoint.isValidLongitude(lng)) {
      return null;
    }
    return GeoPoint(
      latitude: lat,
      longitude: lng,
      source: source,
      capturedAt: DateTime.now(),
    );
  }
}
