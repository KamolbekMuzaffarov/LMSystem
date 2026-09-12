/// Lokatsiya qanday olingani.
enum LocationSource {
  gps('GPS'),
  manual("Qo‘lda kiritilgan"),
  mapsLink('Google Maps havolasi');

  const LocationSource(this.title);

  final String title;

  static LocationSource fromName(String? name) {
    for (final source in values) {
      if (source.name == name) return source;
    }
    return LocationSource.manual;
  }
}

/// Chizma olingan joy koordinatalari.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    this.source = LocationSource.manual,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;

  /// Teskari geokodlash orqali topilgan manzil (internet bo'lsa).
  final String? address;

  /// GPS aniqligi, metrda.
  final double? accuracy;

  final LocationSource source;
  final DateTime? capturedAt;

  static bool isValidLatitude(double value) =>
      value.isFinite && value >= -90 && value <= 90;

  static bool isValidLongitude(double value) =>
      value.isFinite && value >= -180 && value <= 180;

  bool get isValid =>
      isValidLatitude(latitude) && isValidLongitude(longitude);

  String get coordinatesText =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// Google Maps'da ochish uchun havola.
  Uri get mapsUri => Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

  /// Qurilmadagi xarita ilovasi uchun geo havola.
  Uri get geoUri => Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

  GeoPoint copyWith({
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    LocationSource? source,
    DateTime? capturedAt,
    bool clearAddress = false,
  }) {
    return GeoPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: clearAddress ? null : (address ?? this.address),
      accuracy: accuracy ?? this.accuracy,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        if (address != null) 'address': address,
        if (accuracy != null) 'accuracy': accuracy,
        'source': source.name,
        if (capturedAt != null)
          'capturedAt': capturedAt!.toUtc().toIso8601String(),
      };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final capturedAt = json['capturedAt'];
    return GeoPoint(
      latitude: _toDouble(json['lat']),
      longitude: _toDouble(json['lng']),
      address: json['address'] as String?,
      accuracy: json['accuracy'] is num
          ? (json['accuracy'] as num).toDouble()
          : null,
      source: LocationSource.fromName(json['source'] as String?),
      capturedAt:
          capturedAt is String ? DateTime.tryParse(capturedAt)?.toLocal() : null,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.address == address &&
      other.source == source;

  @override
  int get hashCode => Object.hash(latitude, longitude, address, source);
}
